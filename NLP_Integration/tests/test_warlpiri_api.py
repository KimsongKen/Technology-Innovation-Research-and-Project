#!/usr/bin/env python3
"""
Full API integration test — sends all 10 WAV files to a running SACA instance
and validates the JSON responses.  Generates a human-readable HTML report.

Prerequisites:
  1. API is running:    .\\run_api.ps1 -WarlpiriDevFallback
     (use -WarlpiriDevFallback so English Whisper handles the audio;
      the Warlpiri dictionary bridge still runs on the transcript)
  2. Audio files exist: python tests/generate_test_audio.py

Run:
    python tests/test_warlpiri_api.py [--base-url http://localhost:8000] [--token dev-token]

Report saved to: tests/report_warlpiri_api.html
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from datetime import datetime
from pathlib import Path

_ROOT = Path(__file__).resolve().parent.parent
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

try:
    import httpx
except ImportError:
    print("ERROR: httpx not installed.  Run: pip install httpx")
    sys.exit(1)

CASES_PATH = Path(__file__).parent / "warlpiri_test_cases.json"
AUDIO_DIR  = Path(__file__).parent / "audio"
REPORT_PATH = Path(__file__).parent / "report_warlpiri_api.html"

_SEVERITY_RANK = {"Mild": 1, "Moderate": 2, "Severe": 3}


def _safe_filename(case: dict) -> str:
    slug = case["scenario"].lower().replace(" ", "_").replace("/", "_").replace("—", "")
    slug = "".join(c for c in slug if c.isalnum() or c == "_")
    return f"{case['id']}_{slug}.wav"


def _run_case(client: httpx.Client, case: dict, base_url: str, token: str) -> dict:
    wav_path = AUDIO_DIR / _safe_filename(case)

    # ── Path 1: audio upload (tests full audio → STT → translate → triage) ──
    audio_result: dict | None = None
    if wav_path.exists():
        t0 = time.perf_counter()
        try:
            with wav_path.open("rb") as f:
                resp = client.post(
                    f"{base_url}/triage/analyze-voice",
                    headers={"Authorization": f"Bearer {token}"},
                    files={"audio_file": (wav_path.name, f, "audio/wav")},
                    data={"language": "wbp"},
                    timeout=60.0,
                )
            elapsed_ms = int((time.perf_counter() - t0) * 1000)
            audio_result = {
                "status_code": resp.status_code,
                "elapsed_ms": elapsed_ms,
                "body": resp.json() if resp.headers.get("content-type", "").startswith("application/json") else resp.text,
                "error": None,
            }
        except Exception as exc:
            audio_result = {"status_code": None, "elapsed_ms": 0, "body": None, "error": str(exc)}
    else:
        audio_result = {"status_code": None, "elapsed_ms": 0, "body": None, "error": f"WAV not found: {wav_path.name}"}

    # ── Path 2: JSON text triage (bypasses audio, tests translate → triage only) ──
    t0 = time.perf_counter()
    try:
        resp2 = client.post(
            f"{base_url}/triage/predict",
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
            content=json.dumps({
                "raw_transcript": case["warlpiri_phrase"],
                "verified_transcript": case["warlpiri_phrase"],
                "language": "wbp",
            }),
            timeout=30.0,
        )
        elapsed_ms2 = int((time.perf_counter() - t0) * 1000)
        text_result = {
            "status_code": resp2.status_code,
            "elapsed_ms": elapsed_ms2,
            "body": resp2.json() if resp2.headers.get("content-type", "").startswith("application/json") else resp2.text,
            "error": None,
        }
    except Exception as exc:
        text_result = {"status_code": None, "elapsed_ms": 0, "body": None, "error": str(exc)}

    return {"case": case, "audio": audio_result, "text": text_result}


def _check(result: dict, path: str) -> tuple[bool, list[str]]:
    data = result[path]
    case = result["case"]
    failures: list[str] = []

    if data["error"]:
        failures.append(f"Request error: {data['error']}")
        return False, failures

    if data["status_code"] != 200:
        failures.append(f"HTTP {data['status_code']}: {str(data['body'])[:200]}")
        return False, failures

    body = data["body"]
    if not isinstance(body, dict):
        failures.append(f"Non-JSON response: {str(body)[:100]}")
        return False, failures

    triage_level = body.get("triage_level", "")
    expected = case["expected_triage"]
    actual_base = triage_level.split(" (")[0]
    if actual_base != expected:
        failures.append(f"Triage '{actual_base}' ≠ expected '{expected}'")

    transcript = (body.get("transcript") or body.get("verified_transcript") or "").lower()
    for kw in case["expected_english_contains"]:
        if kw.lower() not in transcript:
            failures.append(f"Transcript missing '{kw}'")

    return len(failures) == 0, failures


# ── HTML report ───────────────────────────────────────────────────────────────

_TRIAGE_BADGE = {
    "Severe":   "background:#dc2626;color:#fff",
    "Moderate": "background:#d97706;color:#fff",
    "Mild":     "background:#16a34a;color:#fff",
}

def _triage_style(level: str) -> str:
    for k, v in _TRIAGE_BADGE.items():
        if k in level:
            return v
    return "background:#6b7280;color:#fff"


def _build_report(results: list[dict], base_url: str) -> str:
    total = len(results)
    text_pass  = sum(1 for r in results if _check(r, "text")[0])
    audio_pass = sum(1 for r in results if r["audio"]["error"] is None and _check(r, "audio")[0])
    audio_attempted = sum(1 for r in results if r["audio"]["error"] is None or "not found" not in (r["audio"]["error"] or ""))
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    rows = ""
    for r in results:
        case = r["case"]
        text_ok,  text_fails  = _check(r, "text")
        audio_ok, audio_fails = _check(r, "audio")
        text_level  = (r["text"]["body"] or {}).get("triage_level", "—") if r["text"]["body"] else "—"
        audio_level = (r["audio"]["body"] or {}).get("triage_level", "—") if r["audio"]["body"] else r["audio"].get("error") or "no WAV"

        def badge(ok: bool, label: str) -> str:
            c = "#16a34a" if ok else "#dc2626"
            t = "PASS" if ok else "FAIL"
            return f'<span style="background:{c};color:#fff;padding:2px 8px;border-radius:4px;font-size:12px">{t}</span> {label}'

        def triage_pill(level: str) -> str:
            return f'<span style="{_triage_style(level)};padding:2px 10px;border-radius:12px;font-size:12px;font-weight:600">{level}</span>'

        text_transcript  = (r["text"]["body"]  or {}).get("transcript", "")
        audio_transcript = (r["audio"]["body"] or {}).get("transcript", "")
        text_condition   = (r["text"]["body"]  or {}).get("top_condition", "")
        audio_condition  = (r["audio"]["body"] or {}).get("top_condition", "")

        fail_html = ""
        all_fails = [("Text", f) for f in text_fails] + [("Audio", f) for f in audio_fails]
        if all_fails:
            items = "".join(f"<li><b>{src}:</b> {msg}</li>" for src, msg in all_fails)
            fail_html = f'<ul style="color:#dc2626;margin:4px 0 0 0;font-size:12px">{items}</ul>'

        rows += f"""
        <tr style="border-bottom:1px solid #e5e7eb">
          <td style="padding:10px;font-weight:600;white-space:nowrap">{case['id']}</td>
          <td style="padding:10px">
            <b>{case['scenario']}</b><br>
            <span style="color:#6b7280;font-size:12px">{case['expected_disease_hint']}</span>
          </td>
          <td style="padding:10px;font-family:monospace;font-size:13px;color:#1e40af">{case['warlpiri_phrase']}</td>
          <td style="padding:10px;text-align:center">{triage_pill(case['expected_triage'])}</td>
          <td style="padding:10px">
            {badge(text_ok, '')}
            {triage_pill(text_level)}<br>
            <span style="font-size:11px;color:#374151">{text_transcript[:80] or '—'}</span>
            {'<br><small style="color:#374151">' + text_condition + '</small>' if text_condition else ''}
          </td>
          <td style="padding:10px">
            {badge(audio_ok, '')}
            {triage_pill(audio_level)}<br>
            <span style="font-size:11px;color:#374151">{audio_transcript[:80] or '—'}</span>
            {'<br><small style="color:#374151">' + audio_condition + '</small>' if audio_condition else ''}
          </td>
        </tr>
        {('<tr><td colspan="6" style="padding:4px 10px 10px">' + fail_html + '</td></tr>') if fail_html else ''}
        """

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>SACA — Warlpiri Triage Test Report</title>
<style>
  body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 0; background: #f9fafb; color: #111827; }}
  .header {{ background: #1e3a5f; color: #fff; padding: 24px 32px; }}
  .header h1 {{ margin: 0 0 4px; font-size: 22px; }}
  .header p  {{ margin: 0; opacity: .75; font-size: 13px; }}
  .summary {{ display: flex; gap: 16px; padding: 20px 32px; background: #fff; border-bottom: 1px solid #e5e7eb; }}
  .stat {{ background: #f3f4f6; border-radius: 8px; padding: 12px 20px; text-align: center; }}
  .stat .n {{ font-size: 28px; font-weight: 700; }}
  .stat .l {{ font-size: 12px; color: #6b7280; }}
  table {{ width: 100%; border-collapse: collapse; margin: 24px 32px; width: calc(100% - 64px); background: #fff; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,.1); }}
  th {{ background: #1e3a5f; color: #fff; padding: 10px 10px; text-align: left; font-size: 13px; }}
  .note {{ margin: 0 32px 32px; font-size: 12px; color: #6b7280; }}
</style>
</head>
<body>
<div class="header">
  <h1>SACA — Warlpiri Clinical Triage Test Report</h1>
  <p>Generated: {now} &nbsp;|&nbsp; API: {base_url} &nbsp;|&nbsp; Cases: {total}</p>
</div>
<div class="summary">
  <div class="stat"><div class="n">{total}</div><div class="l">Total Cases</div></div>
  <div class="stat" style="background:#dcfce7"><div class="n" style="color:#16a34a">{text_pass}</div><div class="l">Text Path PASS</div></div>
  <div class="stat" style="background:#dcfce7"><div class="n" style="color:#16a34a">{audio_pass}</div><div class="l">Audio Path PASS</div></div>
  <div class="stat" style="background:#fef9c3"><div class="n" style="color:#b45309">{total - text_pass}</div><div class="l">Text Path FAIL</div></div>
</div>
<table>
  <thead>
    <tr>
      <th>ID</th><th>Scenario</th><th>Warlpiri Phrase</th><th>Expected</th>
      <th>Text Path (JSON)</th><th>Audio Path (WAV)</th>
    </tr>
  </thead>
  <tbody>{rows}</tbody>
</table>
<p class="note">
  <b>Text Path</b> = POST /triage/predict with Warlpiri text (language=wbp) — tests dictionary bridge + triage.<br>
  <b>Audio Path</b> = POST /triage/analyze-voice with WAV file (language=wbp) — tests full audio pipeline.<br>
  Audio files generated by TTS use English pronunciation of Warlpiri words; ASR accuracy depends on the active STT backend.
</p>
</body>
</html>"""


# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default="http://localhost:8000")
    parser.add_argument("--token",    default="dev-token")
    args = parser.parse_args()

    cases = json.loads(CASES_PATH.read_text(encoding="utf-8"))
    print(f"\nSACA — Warlpiri API Integration Test")
    print(f"Target: {args.base_url}\n")

    # Quick health check
    try:
        r = httpx.get(f"{args.base_url}/health", timeout=5)
        print(f"API health: {r.status_code} — {r.json().get('status', '?')}\n")
    except Exception as exc:
        print(f"ERROR: Cannot reach API at {args.base_url} — {exc}")
        print("Start the API first:  .\\run_api.ps1 -WarlpiriDevFallback\n")
        return 1

    results: list[dict] = []
    with httpx.Client() as client:
        for case in cases:
            print(f"  [{case['id']}] {case['scenario']} … ", end="", flush=True)
            r = _run_case(client, case, args.base_url, args.token)
            text_ok, _ = _check(r, "text")
            audio_ok, _ = _check(r, "audio")
            print(f"text={'PASS' if text_ok else 'FAIL'}  audio={'PASS' if audio_ok else 'FAIL'}")
            results.append(r)

    # Write HTML report
    html = _build_report(results, args.base_url)
    REPORT_PATH.write_text(html, encoding="utf-8")
    print(f"\nReport saved: {REPORT_PATH}")
    print(f"Open in browser: file:///{REPORT_PATH.as_posix()}")

    failed = sum(1 for r in results if not _check(r, "text")[0])
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
