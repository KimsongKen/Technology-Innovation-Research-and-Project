"""
Warlpiri (wbp) ↔ English clinical gloss helpers (dictionary bridge for SACA).

Where this sits in the stack
----------------------------

**ASR (speech → Warlpiri text)** is *not* implemented here. For ``language=wbp``, voice
intake calls Meta MMS in :mod:`api.bridge.warlpiri_stt` (``transcribe_mms_waveform``),
possibly via a related-language adapter (``pjt``, etc.). WER and orthography quality are
almost entirely determined by that model + audio — not by the clinical lexicon size.

**This module** runs *after* recognition: :func:`normalize_wbp_text` then longest-key
substring replacement from :data:`WARLPIRI_TO_ENGLISH_CLINICAL`. That improves how much
useful English-aligned text reaches SBERT / symptom extraction **when** the transcript
already contains token shapes that appear in the dictionary.

.. mermaid::

    flowchart LR
      A[Microphone audio] --> B[MMS Wav2Vec2 + adapter\nwarlpiri_stt.py]
      B --> C[Raw Warlpiri transcript]
      C --> D[normalize + dictionary gloss\nwarlpiri_dict.py]
      D --> E[English-oriented string]
      E --> F[SBERT encode + triage\nrouter / TriageService]

Maps Warlpiri clinical keywords into English phrases aligned with ``symptom_lexicon``
and the SBERT manifold (sentence-transformers/all-MiniLM-L6-v2) — no ML retraining.

The bulk lexicon comes from ``generated/warlpiri_clinical_map.py`` (AuSIL / Lexique Pro
HTML scrape). Keys in :data:`_WARLPIRI_CLINICAL_MANUAL` override the scraped map on
collision. Regenerate the file with ``scrape_dictionary.py`` and review with linguists
before production use.

Voice routes apply :func:`translate_clinical_transcript` in ``router`` after
``_transcribe_upload``; see ``analyze_voice`` / ``triage_predict`` paths there.

Fuzzy matching note
-------------------
MMS with an approximate adapter (``pjt`` instead of ``wbp``) will systematically
misrecognize Warlpiri phonemes. :func:`_fuzzy_word_gloss` catches single-word near-misses
(edit distance ≤ 1 for short words, ≤ 2 for longer ones) so that "paaha" still resolves
to "pain" even if MMS dropped the final vowel. It operates on individual tokens only;
multi-word keys are handled by the existing exact substring pass.

All dictionary entries flagged ``# verify`` should be reviewed by a Warlpiri linguist
before clinical deployment. Entries marked ``# documented`` appear in published academic
or AuSIL resources.
"""

from __future__ import annotations

import re

from api.utils.warlpiri_normalizer import normalize_wbp_text


def _scraped_clinical_map() -> dict[str, str]:
    try:
        from generated.warlpiri_clinical_map import WARLPIRI_CLINICAL_MAP
    except ImportError:
        return {}
    return dict(WARLPIRI_CLINICAL_MAP)


# ---------------------------------------------------------------------------
# Curated clinical lexicon
# ---------------------------------------------------------------------------
# Sources:
#   [D] = Laughren et al., Warlpiri-English Encyclopaedic Dictionary (2006)
#   [A] = AuSIL / AustLang documentation
#   [H] = Ken Hale fieldwork materials (MIT archive)
#   [V] = verify with community linguist before production use
#
# Orthography note: Warlpiri uses retroflex consonants written as rd, rl, rn, rt;
# palatal consonants as j; and long vowels sometimes doubled (aa, ii, uu).
# MMS may produce simplified spellings — fuzzy matching compensates for this.
# ---------------------------------------------------------------------------

_WARLPIRI_CLINICAL_MANUAL: dict[str, str] = {

    # ── Body parts ─────────────────────────────────────────────────────────
    "jurru":           "head",            # [D] head
    "jurru-jurru":     "head pain headache",
    "yurruŋu":         "eye",             # [D]
    "yurrунgu":        "eye",             # normalised variant
    "yurrungu":        "eye",             # [D] ASCII variant
    "mimi":            "ear",             # [D]
    "yarrki":          "mouth",           # [D] verify
    "ngarrka":         "throat neck",     # [D]
    "rduku":           "chest",           # [D] chest/breast area
    "rduku-rduku":     "chest pain",      # reduplication = painful chest
    "puku":            "stomach belly",   # [D]
    "puku-puku":       "stomach pain abdominal pain",
    "ngirli":          "back",            # [D]
    "yalumpu":         "arm",             # [D]
    "yankirri":        "leg",             # [D] verify
    "pama":            "hand",            # [D]
    "karli":           "blood",           # [D]
    "karli-karli":     "bleeding blood",

    # ── Pain / discomfort ──────────────────────────────────────────────────
    "pacha":           "pain",            # [D] pain (some sources: paja)
    "paja":            "pain",            # [D] alternate spelling
    "watiya":          "pain hurt",       # [D]
    "watia":           "pain hurt",       # alternate spelling
    "watingi":         "painful hurting", # [V]
    "kuja":            "sick bad",        # [V]

    # ── Respiratory ────────────────────────────────────────────────────────
    "kurrunpa":        "breath breathing", # [D] breath/spirit
    "kurrunpa wantimi": "cannot breathe stopped breathing", # [V]
    "parnka-parnka":   "gasping cannot breathe difficulty breathing", # [V]
    "parnkaparnka":    "gasping cannot breathe",
    "wirlinyi":        "cough",           # [D]
    "wirlinyi-wirlinyi": "persistent cough",

    # ── Fever / temperature ────────────────────────────────────────────────
    "karrija":         "hot fever",       # [D] hot/warm
    "karrija-karrija": "high fever very hot",
    "jirrarda":        "cold chills",     # [D] cold
    "jirrarda-jirrarda": "chills shivering",

    # ── Nausea / vomiting ──────────────────────────────────────────────────
    "yurrnga":         "vomiting nausea", # [D] verify spelling
    "yurrkaji":        "vomit",           # [V]
    "yurrpu":          "nausea feel sick", # [V]

    # ── Consciousness / neurological ───────────────────────────────────────
    "jarndu":          "faint collapse unconscious", # [V]
    "rdilyka":         "shaking seizure convulsion",  # [V]
    "wantimi":         "fall down collapse",          # [D] fall
    "kuyu-kuyu":       "dizzy dizziness spinning",    # [V]
    "ngurlu-ngurlu":   "dizzy dizziness",             # [V]

    # ── Weakness / fatigue ─────────────────────────────────────────────────
    "pirlirrpa":       "weak weakness tired fatigue", # [V]
    "karlarra":        "tired exhausted",              # [V]

    # ── Severity modifiers ─────────────────────────────────────────────────
    "ngurluju":        "severe serious bad",   # [D] bad/serious quality
    "ngurlu":          "bad",                  # [D]
    "yuwarli":         "sick unwell ill",      # [D]
    "yuwarli ngurluju": "very sick seriously ill emergency",
    "yimirri":         "cannot unable",        # [D]

    # ── People / social context ────────────────────────────────────────────
    "yapa":            "person",           # [D] Aboriginal person
    "kurdu":           "child baby",       # [D]
    "kurdu-kurdu":     "children",
    "jaju":            "grandmother",      # [D] — relevant for elder care
    "yarlungku":       "alone by themselves", # [V] — patient alone/unaccompanied

    # ── Time / duration ────────────────────────────────────────────────────
    "ngurra":          "long time",        # [D] camp/place — extended meaning in duration [V]
    "jinta":           "one first",        # [D]
    "manu":            "and also",         # [D] conjunction

    # ── Legacy demo placeholders (kept for backward compat) ────────────────
    "wpp_placeholter_chest_pain":    "chest pain",
    "wpp_placeholter_short_preath":  "shortness of breath",
    "wpp_placeholter_cannot_preathe": "cannot breathe",
    "wpp_placeholter_coukh":         "cough",
    "wpp_placeholter_heatache":      "headache",
    "wpp_placeholter_fever":         "fever",
    "wpp_placeholter_tizzy":         "dizziness",
    "wpp_placeholter_vomit":         "vomiting",
    "wpp_placeholter_pelly_pain":    "abdominal pain",
    "wpp_placeholter_weak":          "weakness",
}


WARLPIRI_TO_ENGLISH_CLINICAL: dict[str, str] = {
    **_scraped_clinical_map(),
    **_WARLPIRI_CLINICAL_MANUAL,
}


# ---------------------------------------------------------------------------
# Fuzzy word-level matching
# ---------------------------------------------------------------------------

def _edit_distance(a: str, b: str) -> int:
    """Standard Levenshtein distance — pure Python, no dependencies."""
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    m, n = len(a), len(b)
    dp = list(range(n + 1))
    for i in range(1, m + 1):
        prev = dp[0]
        dp[0] = i
        for j in range(1, n + 1):
            temp = dp[j]
            dp[j] = prev if a[i - 1] == b[j - 1] else 1 + min(prev, dp[j], dp[j - 1])
            prev = temp
    return dp[n]


def _max_allowed_distance(word_len: int) -> int:
    """Edit distance budget: tighter for short words to avoid false positives."""
    if word_len <= 3:
        return 0   # exact match only — too short to fuzzy-match safely
    if word_len <= 5:
        return 1
    return 2


# Pre-build index of single-word dictionary keys for fast fuzzy lookup.
_SINGLE_WORD_KEYS: dict[str, str] = {
    k: v for k, v in WARLPIRI_TO_ENGLISH_CLINICAL.items() if " " not in k and "-" not in k
}


def _fuzzy_word_gloss(word: str) -> str | None:
    """Return English gloss if *word* is within edit-distance of a single-word key."""
    wl = len(word)
    budget = _max_allowed_distance(wl)
    best_gloss: str | None = None
    best_dist = budget + 1
    for key, gloss in _SINGLE_WORD_KEYS.items():
        if abs(len(key) - wl) > budget:
            continue  # length difference already exceeds budget — skip
        d = _edit_distance(word, key)
        if d < best_dist:
            best_dist = d
            best_gloss = gloss
    return best_gloss if best_dist <= budget else None


def _apply_fuzzy_word_pass(text: str) -> str:
    """
    Token-by-token fuzzy match for words the exact pass missed.
    Only fires on tokens that look like Warlpiri (all-alpha, length ≥ 4).
    """
    tokens = text.split()
    result = []
    for token in tokens:
        clean = token.lower().strip(".,!?;:'\"")
        if len(clean) >= 4 and clean.isalpha():
            gloss = _fuzzy_word_gloss(clean)
            if gloss:
                result.append(gloss)
                continue
        result.append(token)
    return " ".join(result)


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------

def _apply_warlpiri_lexicon(transcript: str) -> str:
    """MMS orthography → modern wbp normalisation → exact substring gloss → fuzzy word gloss."""
    if not (transcript or "").strip():
        return ""
    result = normalize_wbp_text(transcript)

    # Pass 1: longest-key exact substring replacement (handles multi-word keys first)
    for wbp_term, english in sorted(
        WARLPIRI_TO_ENGLISH_CLINICAL.items(),
        key=lambda item: len(item[0]),
        reverse=True,
    ):
        pattern = re.compile(re.escape(wbp_term), re.IGNORECASE)
        result = pattern.sub(english, result)

    # Pass 2: fuzzy word-level match for tokens the exact pass missed
    result = _apply_fuzzy_word_pass(result)

    result = result.replace("cant", "can't")
    result = re.sub(r"\s+", " ", result).strip()
    return result


def translate_warlpiri_to_english(transcript: str) -> str:
    """
    Warlpiri-only glossing (used by QA helpers and lexicon tests).
    Matching is case-insensitive. Longer dictionary keys are applied first.
    """
    return _apply_warlpiri_lexicon(transcript)


def translate_clinical_transcript(transcript: str, language: str) -> str:
    """
    Unified bridge for the FastAPI triage pipeline.

    * ``language`` in ``wbp`` / ``warlpiri`` / ``w``: map dictionary keys to English.
    * ``language`` == ``en`` (or any other code): return *transcript unchanged* so
      English intake is not lowercased or altered here (symptom extraction lowercases internally).
    """
    if transcript is None:
        return ""
    lang = (language or "").strip().lower()
    if lang in {"wbp", "warlpiri", "w"}:
        return _apply_warlpiri_lexicon(transcript)
    return transcript


def normalize_for_triage(transcript: str, language_code: str) -> str:
    """
    QA / validate endpoint helper: Warlpiri path uses the same bridge as live triage;
    other languages return whitespace-collapsed lowercase (legacy validate behaviour).
    """
    code = (language_code or "").strip().lower()
    if code in {"wbp", "warlpiri", "w"}:
        return translate_clinical_transcript(transcript, "wbp")
    cleaned = re.sub(r"\s+", " ", (transcript or "").strip().lower())
    return cleaned
