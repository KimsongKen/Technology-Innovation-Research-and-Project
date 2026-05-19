"""
Normalize MMS ASR output (archaic/diacritic phonetics) toward modern Warlpiri orthography.

Meta MMS ``facebook/mms-1b-all`` and related checkpoints often emit digraphs such as ``tj``,
retroflex letters with under-dots (``ṟ``, ``ṯ``), and voiced stops (``g``, ``d``, ``b``)
that standard lexical resources write as ``j``, ``r``/``t``, ``k``, ``t``, ``p`` respectively.

This module does **not** perform morphological analysis; it is a deterministic string
normalizer before the clinical dictionary in ``warlpiri_dict.py``.
"""

from __future__ import annotations

import re
import unicodedata


def normalize_wbp_text(raw: str) -> str:
    """
    Sequentially normalize a raw MMS (or similar) transcript string for Warlpiri (wbp).

    1. Lowercase + Unicode NFC.
    2. Remove combining dot/macron below (NFD decomposition) so ṟ / ṯ base letters normalize.
    3. Replace known precomposed under-dotted letters.
    4. ``tj`` -> ``j`` (must run before single-letter stop shifts involving ``t``).
    5. ``g`` -> ``k`` except as the second letter of ``ng``.
    6. ``b`` -> ``p`` except after ``m`` (prenasal cluster guard).
    7. ``d`` -> ``t`` except when part of retroflex ``rd`` (``d`` immediately after ``r``).
    8. Collapse whitespace.
    """
    if not (raw or "").strip():
        return ""

    s = unicodedata.normalize("NFC", raw.strip().lower())

    # Strip combining dot below / macron below from NFD (covers composed + decomposed inputs).
    nfd_buf: list[str] = []
    for ch in unicodedata.normalize("NFD", s):
        if ch in "\u0323\u0331":  # COMBINING DOT BELOW, COMBINING MACRON BELOW
            continue
        nfd_buf.append(ch)
    s = unicodedata.normalize("NFC", "".join(nfd_buf))

    # Precomposed letters still sometimes present without decomposition.
    _UNDERDOT_MAP = str.maketrans(
        {
            "\u1e5f": "r",  # ṟ
            "\u1e5e": "r",
            "\u1e6f": "t",  # ṯ
            "\u1e6e": "t",
            "\u1e6d": "t",  # ṭ
            "\u1e6c": "t",
            "\u1e49": "n",  # ṉ
            "\u1e48": "n",
            "\u1e3b": "l",  # ḻ
            "\u1e3a": "l",
            "\u1e0f": "d",  # ḏ — later d->t rule applies (unless rd)
            "\u1e0e": "d",
        }
    )
    s = s.translate(_UNDERDOT_MAP)

    # Archaic postalveolar affricate digraph -> modern j
    s = s.replace("tj", "j")

    # Velar stop: voiced g -> k, but never break ng [ŋ] digraph in standard orthography.
    s = re.sub(r"(?<!n)g", "k", s)

    # Labial: optional b -> p (guard simple prenasal mb)
    s = re.sub(r"(?<!m)b", "p", s)

    # Apical: d -> unless retroflex cluster rd
    s = re.sub(r"(?<!r)d", "t", s)

    s = re.sub(r"\s+", " ", s).strip()
    return s


if __name__ == "__main__":
    _SAMPLE = (
        "maṟkai maṟgai guranggu patitjaratarku tjalangutju nyampula langutju "
        "australyalatu yapa yapamala paṯiyalgku galigunutjaramirkia"
    )
    _OUT = normalize_wbp_text(_SAMPLE)
    print("normalized output:")
    print(_OUT)
