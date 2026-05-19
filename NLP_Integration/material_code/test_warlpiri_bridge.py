#!/usr/bin/env python3
"""Smoke-test Warlpiri placeholder → English clinical gloss mapping (no HTTP server)."""

from __future__ import annotations

import sys
from pathlib import Path

_ROOT = Path(__file__).resolve().parent
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from api.bridge.warlpiri_dict import translate_warlpiri_to_english

_SAMPLES = (
    "yapa kurrunpa watiya",
    # Lowercased + MMS-style normalizer runs first; keys match post-normalization spellings.
    "wbp_placeholder_chest_pain jukurrpa",
    "WBP_PLACEHOLDER_SHORT_BREATH",
)


def main() -> None:
    for s in _SAMPLES:
        print(f"IN : {s}")
        print(f"OUT: {translate_warlpiri_to_english(s)!r}")
        print()


if __name__ == "__main__":
    main()
