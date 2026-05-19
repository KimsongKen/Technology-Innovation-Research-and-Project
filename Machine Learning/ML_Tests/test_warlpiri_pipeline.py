#!/usr/bin/env python3
"""
Warlpiri clinical pipeline validator — no API server, no audio files needed.

Tests the translation + triage logic end-to-end for all 10 clinical scenarios
by directly calling the same modules the API uses.

Run:
    python tests/test_warlpiri_pipeline.py

Exit code 0 = all passed.  Prints a colour-coded report.
"""

from __future__ import annotations

import json
import sys
import time
from pathlib import Path

# Allow running from project root or from tests/
_ROOT = Path(__file__).resolve().parent.parent
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from api.bridge.warlpiri_dict import translate_warlpiri_to_english
from api.bridge.clinical_text import contains_emergency_keyword, contains_warlpiri_emergency
from api.bridge.triage_service import TriageService
from api.bridge.nlp_service import NLPService

# ── Terminal colours ──────────────────────────────────────────────────────────
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
BOLD   = "\033[1m"
RESET  = "\033[0m"

_CASES_PATH = Path(__file__).parent / "warlpiri_test_cases.json"

# Triage ordering for "at least this level" checks
_SEVERITY_RANK = {"Mild": 1, "Moderate": 2, "Severe": 3}


def _load_cases() -> list[dict]:
    return json.loads(_CASES_PATH.read_text(encoding="utf-8"))


def _run_pipeline(warlpiri_text: str, nlp: NLPService, triage: TriageService) -> dict:
    """Mirror what the router does for language=wbp JSON triage."""
    translated = translate_warlpiri_to_english(warlpiri_text)
    pre_escalate = contains_warlpiri_emergency(warlpiri_text)
    emergency_flag = contains_emergency_keyword(translated)
    vector = nlp.encode(translated)
    decision = triage.decide(transcript=translated, semantic_vector=vector.embedding)
    level = decision.triage_level
    # Apply pre-escalation override (same logic as router)
    if pre_escalate and _SEVERITY_RANK.get(level, 0) < _SEVERITY_RANK["Severe"]:
        level = "Severe (pre-escalated from Warlpiri emergency term)"
    elif emergency_flag and _SEVERITY_RANK.get(level, 0) < _SEVERITY_RANK["Severe"]:
        level = "Severe (emergency keyword gate)"
    return {
        "translated": translated,
        "pre_escalate": pre_escalate,
        "emergency_flag": emergency_flag,
        "triage_level": level,
        "top_condition": decision.top_condition,
        "recommendation": decision.recommendation,
    }


def _check_pass(result: dict, case: dict) -> tuple[bool, list[str], list[str]]:
    """Returns (passed, hard_failures, warnings)."""
    failures: list[str] = []
    warnings: list[str] = []
    translated_lower = result["translated"].lower()

    # Check translation contains expected keywords
    for kw in case["expected_english_contains"]:
        if kw.lower() not in translated_lower:
            failures.append(f"Translation missing '{kw}' — got: {result['translated']!r}")

    # Triage check: use minimum-severity logic.
    # Over-triaging (e.g. Severe when Moderate expected) is clinically SAFE —
    # the system errs toward escalation. Under-triaging is the dangerous failure.
    expected = case["expected_triage"]
    actual_base = result["triage_level"].split(" (")[0]
    expected_rank = _SEVERITY_RANK.get(expected, 0)
    actual_rank   = _SEVERITY_RANK.get(actual_base, 0)

    if actual_rank < expected_rank:
        # Under-triage: real failure
        failures.append(
            f"UNDER-TRIAGE: got '{actual_base}' but expected at least '{expected}' "
            f"(model may miss this presentation)"
        )
    elif actual_rank > expected_rank:
        # Over-triage: safe, but flag for review
        warnings.append(
            f"Over-triage: '{actual_base}' > expected '{expected}' "
            f"(conservative — safe but may cause alert fatigue)"
        )

    return len(failures) == 0, failures, warnings


def main() -> int:
    print(f"\n{BOLD}{'-' * 68}{RESET}")
    print(f"{BOLD}  SACA — Warlpiri Clinical Pipeline Validation{RESET}")
    print(f"{BOLD}{'-' * 68}{RESET}\n")

    cases = _load_cases()
    print(f"Loading NLP + triage services …", end=" ", flush=True)
    t0 = time.perf_counter()
    nlp    = NLPService()
    triage = TriageService()
    print(f"ready in {time.perf_counter() - t0:.1f}s\n")

    passed = 0
    failed = 0

    for case in cases:
        t_start = time.perf_counter()
        result = _run_pipeline(case["warlpiri_phrase"], nlp, triage)
        elapsed_ms = int((time.perf_counter() - t_start) * 1000)
        ok, failures, cautions = _check_pass(result, case)

        # ── Status badge ──────────────────────────────────────────────────
        badge = f"{GREEN}PASS{RESET}" if ok else f"{RED}FAIL{RESET}"
        triage_colour = {
            "Severe": RED, "Moderate": YELLOW, "Mild": GREEN,
        }.get(result["triage_level"].split(" (")[0], CYAN)

        print(f"{badge}  [{case['id']}] {BOLD}{case['scenario']}{RESET}")
        print(f"       Warlpiri : {CYAN}{case['warlpiri_phrase']}{RESET}")
        print(f"       English  : {result['translated']}")
        print(
            f"       Triage   : {triage_colour}{result['triage_level']}{RESET}"
            f"  (expected: {case['expected_triage']})"
            f"  |  Condition: {result['top_condition'] or '—'}"
            f"  |  {elapsed_ms} ms"
        )
        if result["pre_escalate"]:
            print(f"       {YELLOW}[!] Warlpiri pre-translation emergency term detected{RESET}")
        if result["emergency_flag"]:
            print(f"       {YELLOW}[!] Emergency keyword gate fired on translated text{RESET}")
        for w in cautions:
            print(f"       {YELLOW}[~] {w}{RESET}")
        for f in failures:
            print(f"       {RED}[x] {f}{RESET}")
        print()

        if ok:
            passed += 1
        else:
            failed += 1

    # ── Summary ───────────────────────────────────────────────────────────
    total = passed + failed
    colour = GREEN if failed == 0 else RED
    print(f"{BOLD}{'-' * 68}{RESET}")
    print(
        f"{BOLD}  Results: {colour}{passed}/{total} passed{RESET}"
        + (f"  {RED}{failed} failed{RESET}" if failed else "")
    )
    print(f"{BOLD}{'-' * 68}{RESET}\n")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
