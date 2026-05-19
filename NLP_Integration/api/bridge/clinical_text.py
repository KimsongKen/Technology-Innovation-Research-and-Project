"""Clinical text normalization and escalation helpers (kept out of HTTP routing)."""

from __future__ import annotations

import re

from api.bridge.symptom_lexicon import PHRASE_TO_CANONICAL, SYMPTOM_PHRASES
from api.bridge.warlpiri_dict import translate_clinical_transcript

# ---------------------------------------------------------------------------
# Emergency keyword gate
# ---------------------------------------------------------------------------
# Checked AFTER the Warlpiri→English dictionary bridge so all terms are English.
# Keep sorted roughly by severity; order does not affect matching.
# Err on the side of inclusion — false positives escalate to Severe (safe);
# false negatives miss a life-threatening presentation (dangerous).

EMERGENCY_KEYWORDS: tuple[str, ...] = (
    # Respiratory
    "chest pain",
    "chest hurt",
    "chest hurts",
    "cannot breathe",
    "can't breathe",
    "cant breathe",
    "not breathing",
    "no breathing",
    "stopped breathing",
    "hard to breathe",
    "difficulty breathing",
    "shortness of breath",
    "no breath",
    "choking",
    "gasping",
    "wheezing bad",
    # Cardiac
    "heart attack",
    "heart stopped",
    "heart stop",
    "heart pain",
    "chest tight",
    "chest tightness",
    "no pulse",
    "heart not beating",
    # Neurological
    "stroke",
    "seizure",
    "fitting",
    "fit",
    "unconscious",
    "unresponsive",
    "not waking",
    "cannot wake",
    "can't wake",
    "passed out",
    "blacked out",
    "collapsed",
    "fall down",
    "fell down",
    "not moving",
    "confused and shaking",
    # Bleeding
    "severe bleeding",
    "heavy bleeding",
    "lot of blood",
    "too much blood",
    "bleeding bad",
    "bleeding a lot",
    "won't stop bleeding",
    "blood everywhere",
    # Altered consciousness / severe weakness
    "cannot move",
    "can't move",
    "paralysed",
    "paralyzed",
    "one side weak",
    "face drooping",
    "slurred speech",
    "cannot speak",
    "can't speak",
    # Anaphylaxis / allergy
    "throat closing",
    "throat swelling",
    "tongue swelling",
    "allergic reaction",
    "anaphylaxis",
    # Obstetric
    "baby not moving",
    "heavy bleeding pregnant",
    # Paediatric
    "child not breathing",
    "baby not breathing",
    "child unconscious",
)

# Warlpiri emergency terms checked BEFORE the dictionary bridge as a safety net.
# These are documented Warlpiri words for life-threatening states.
# Even if MMS partially mangles them, the pre-translation check may still fire.
_WARLPIRI_EMERGENCY_TERMS: tuple[str, ...] = (
    "parnka-parnka",   # gasping / struggling to breathe
    "parnkaparnka",
    "jarndu",          # faint / collapse
    "rdilyka",         # shaking / convulsing
    "wantimi",         # fall / collapse
    "yuwarli ngurluju", # very sick / seriously unwell
    "pacha ngurluju",  # severe pain
    "kurrunpa wantimi", # breath gone / stopped breathing
)


def contains_emergency_keyword(text: str) -> bool:
    """
    Check the (already English-translated) transcript for emergency terms.
    Padding spaces ensure we match whole words only (avoids 'fit' inside 'profit').
    """
    norm = f" {text.lower()} "
    return any(f" {kw} " in norm for kw in EMERGENCY_KEYWORDS)


def contains_warlpiri_emergency(raw_warlpiri_text: str) -> bool:
    """
    Pre-translation safety check on the raw MMS transcript.
    Call this before applying the dictionary bridge so emergency escalation
    is not blocked by a dictionary miss.
    """
    norm = f" {raw_warlpiri_text.lower()} "
    return any(term in norm for term in _WARLPIRI_EMERGENCY_TERMS)


def extract_top_3_symptoms(text: str, symptom_columns: list[str] | None = None) -> list[str]:
    """Up to three canonical symptoms using the same rules as `TriageService._extract_symptoms`.

    For comma-/semicolon-separated lists, tokens are processed **in user order** first so the UI matches the intake list.
    """
    merged = re.sub(r"\s+", " ", (text or "").strip().lower()).strip()
    if not merged:
        return []
    cols = set(symptom_columns) if symptom_columns else None
    ordered: list[str] = []
    seen: set[str] = set()

    def push(canonical: str) -> None:
        if canonical in seen:
            return
        if cols is not None and canonical not in cols:
            return
        seen.add(canonical)
        ordered.append(canonical)

    def token_pass() -> None:
        for raw in re.split(r"[,;\n]+", merged):
            chunk = raw.strip().strip('"').strip("'").strip("`").lower()
            if len(chunk) < 2:
                continue
            mapped = PHRASE_TO_CANONICAL.get(chunk, chunk)
            if cols is not None:
                if mapped in cols:
                    push(mapped)
                elif chunk in cols:
                    push(chunk)
            elif chunk in PHRASE_TO_CANONICAL:
                push(PHRASE_TO_CANONICAL[chunk])
            if len(ordered) >= 3:
                return

    def phrase_pass() -> None:
        for phrase, target in SYMPTOM_PHRASES.items():
            if phrase in merged:
                push(target)
                if len(ordered) >= 3:
                    return

    segments = [s for s in re.split(r"[,;\n]+", merged) if s.strip()]
    if len(segments) > 1:
        token_pass()
        if len(ordered) < 3:
            phrase_pass()
    else:
        phrase_pass()
        if len(ordered) < 3:
            token_pass()

    return ordered[:3]
