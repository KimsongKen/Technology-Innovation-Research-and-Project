#!/usr/bin/env python3
"""
Parse local AuSIL-style English–Warlpiri dictionary HTML and emit WARLPIRI_CLINICAL_MAP.

Depends on: beautifulsoup4
  pip install beautifulsoup4

There is no fixed folder name like ``ausil_html_files``. Point ``--html-dir`` at the directory
that actually contains dictionary ``.htm`` / ``.html`` files. Word “Save as Web Page” exports
often look like::

  WarlpiriTablet/
    aboutwarlpiri.htm          # dictionary content may be here
    aboutwarlpiri_files/       # usually images/CSS only — often NOT where entries live

If you are unsure where the HTML is, run with ``--discover`` to list matching files.

Example:
  python scrape_dictionary.py --discover --html-dir "C:/Users/kimso/Downloads/WarlpiriTablet"
  python scrape_dictionary.py --html-dir "C:/Users/kimso/Downloads/WarlpiriTablet" --out generated/clinical_map.py
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from collections.abc import Iterator
from pathlib import Path


def _ensure_bs4() -> None:
    try:
        from bs4 import BeautifulSoup  # noqa: F401
    except ImportError:
        print(
            "Missing dependency: beautifulsoup4\n"
            "Install with:  pip install beautifulsoup4",
            file=sys.stderr,
        )
        sys.exit(1)


def normalize_warlpiri_token(s: str) -> str:
    t = (s or "").strip().lower()
    t = re.sub(r"\s+", " ", t)
    return t


def medical_match_keywords(gloss: str, keywords: tuple[str, ...]) -> list[str]:
    if not gloss:
        return []
    low = gloss.lower()
    found: list[str] = []
    for kw in keywords:
        if kw.lower() in low:
            found.append(kw)
    return found


def english_value_for_matches(gloss: str, hits: list[str]) -> str:
    gloss = re.sub(r"\s+", " ", (gloss or "").strip())
    if not hits:
        return gloss
    if len(gloss) <= 120 and len(hits) == 1:
        return gloss
    return ", ".join(hits)


def iter_html_files(root: Path) -> Iterator[Path]:
    for dirpath, _, filenames in os.walk(root):
        for name in filenames:
            low = name.lower()
            if low.endswith((".htm", ".html")):
                yield Path(dirpath) / name


def soup_from_path(path: Path):
    from bs4 import BeautifulSoup

    raw = path.read_text(encoding="utf-8", errors="replace")
    return BeautifulSoup(raw, "html.parser")


def _class_blob(attrs: dict) -> str:
    c = attrs.get("class")
    if not c:
        return ""
    if isinstance(c, list):
        return " ".join(c)
    return str(c)


def looks_warlpiri_span(tag) -> bool:
    b = _class_blob(tag.attrs).lower()
    if not b:
        return False
    markers = (
        "wbp",
        "warlpiri",
        "wrg",
        "vernacular",
        "lx",
        "headword",
        "csl-bibu",
        "csl-vernacular",
        "lexeme",
        # Lexique Pro (e.g. WarlpiriTablet lexicon/*.htm): span.lpLexEntryName
        "lexentry",
    )
    return any(m in b for m in markers)


def looks_english_span(tag) -> bool:
    b = _class_blob(tag.attrs).lower()
    if not b:
        return False
    markers = (
        "eng",
        "gloss",
        "definition",
        "meaning",
        "ge",
        "csl-gloss",
        "csl-english",
    )
    return any(m in b for m in markers)


def iter_pairs_from_soup(soup) -> Iterator[tuple[str, str]]:
    seen: set[tuple[str, str]] = set()

    def emit(w: str, g: str) -> Iterator[tuple[str, str]]:
        wn, gn = normalize_warlpiri_token(w), re.sub(r"\s+", " ", (g or "").strip())
        if len(wn) < 2 or len(gn) < 2:
            return
        key = (wn, gn.lower())
        if key in seen:
            return
        seen.add(key)
        yield wn, gn

    for parent in soup.find_all(["div", "p", "td", "li", "article", "section"]):
        w_el = None
        g_el = None
        for sp in parent.find_all("span"):
            if looks_warlpiri_span(sp):
                w_el = sp
            if looks_english_span(sp):
                g_el = sp
        if w_el and g_el:
            yield from emit(w_el.get_text(" ", strip=True), g_el.get_text(" ", strip=True))

    for tr in soup.find_all("tr"):
        cells = tr.find_all(["td", "th"])
        if len(cells) >= 2:
            w_t = cells[0].get_text(" ", strip=True)
            g_t = cells[1].get_text(" ", strip=True)
            if w_t and g_t and len(w_t) < 80:
                yield from emit(w_t, g_t)

    for dt in soup.find_all("dt"):
        dd = dt.find_next_sibling("dd")
        if dd:
            yield from emit(dt.get_text(" ", strip=True), dd.get_text(" ", strip=True))

    for b in soup.find_all(["b", "strong"]):
        w_t = b.get_text(" ", strip=True)
        if len(w_t) > 80 or len(w_t) < 2:
            continue
        parent = b.parent
        if not parent:
            continue
        full = parent.get_text(" ", strip=True)
        if full.startswith(w_t):
            g_t = full[len(w_t) :].strip(" :–—.-")
            if len(g_t) >= 3:
                yield from emit(w_t, g_t)

    sep_re = re.compile(r"[\u2013\u2014:]\s*")
    for p in soup.find_all("p"):
        t = p.get_text(" ", strip=True)
        parts = sep_re.split(t, maxsplit=1)
        if len(parts) == 2:
            w_t, g_t = parts[0].strip(), parts[1].strip()
            if 2 <= len(w_t) <= 60 and len(g_t) >= 3:
                yield from emit(w_t, g_t)


def count_html_files(root: Path) -> int:
    return sum(1 for _ in iter_html_files(root))


def discover_html_files(root: Path, limit: int = 200) -> None:
    print(f"Scanning for .htm/.html under: {root.resolve()}\n")
    n = 0
    for fpath in sorted(iter_html_files(root)):
        print(fpath)
        n += 1
        if n >= limit:
            print(f"... stopped after {limit} files (there may be more).")
            break
    print(f"\nTotal listed: {n}")


def build_clinical_map(html_root: Path, keywords: tuple[str, ...]) -> dict[str, str]:
    clinical: dict[str, str] = {}
    for fpath in iter_html_files(html_root):
        try:
            soup = soup_from_path(fpath)
        except OSError:
            continue
        for wbp, gloss in iter_pairs_from_soup(soup):
            hits = medical_match_keywords(gloss, keywords)
            if not hits:
                continue
            val = english_value_for_matches(gloss, hits)
            if not val:
                continue
            if wbp not in clinical or len(val) > len(clinical[wbp]):
                clinical[wbp] = val
    return dict(sorted(clinical.items(), key=lambda x: x[0].lower()))


def write_output_py(path: Path, mapping: dict[str, str], source_dir: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        '"""AUTO-GENERATED by scrape_dictionary.py — review with linguists before production use."""\n',
        "\n",
        "# Source HTML directory (at generation time):\n",
        f"# {source_dir}\n",
        "\n",
        "WARLPIRI_CLINICAL_MAP = {\n",
    ]
    for k, v in mapping.items():
        lines.append(f"    {k!r}: {v!r},\n")
    lines.append("}\n")
    path.write_text("".join(lines), encoding="utf-8")


def main() -> None:
    _ensure_bs4()

    default_keywords = (
        "pain",
        "ache",
        "sore",
        "hurt",
        "fever",
        "head",
        "chest",
        "stomach",
        "blood",
        "sick",
        "ill",
        "cough",
        "breathe",
        "vomit",
        "dizzy",
        "wound",
        "cut",
        "swell",
        "bone",
    )

    parser = argparse.ArgumentParser(description="Scrape AuSIL Warlpiri HTML for clinical glosses.")
    parser.add_argument(
        "--html-dir",
        type=Path,
        default=None,
        help=(
            "Folder that contains dictionary .htm/.html (searched recursively). "
            "Use your real path (e.g. WarlpiriTablet root); there is no required name like ausil_html_files. "
            "Default: current working directory."
        ),
    )
    parser.add_argument(
        "--discover",
        action="store_true",
        help="Only list .htm/.html files under --html-dir and exit (use this to find where HTML lives).",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=Path("generated") / "warlpiri_clinical_map.py",
        help="Output Python file with WARLPIRI_CLINICAL_MAP.",
    )
    parser.add_argument(
        "--keywords",
        nargs="*",
        default=list(default_keywords),
        help="English medical substrings to match (default: built-in clinical list).",
    )
    args = parser.parse_args()
    html_dir = (args.html_dir if args.html_dir is not None else Path(".")).resolve()
    if not html_dir.is_dir():
        print(f"ERROR: not a directory: {html_dir}", file=sys.stderr)
        sys.exit(2)

    if args.discover:
        discover_html_files(html_dir)
        sys.exit(0)

    n_html = count_html_files(html_dir)
    if n_html == 0:
        print(f"No .htm or .html files found under:\n  {html_dir}\n", file=sys.stderr)
        print(
            "Tip: run with --discover on the WarlpiriTablet folder, or in Explorer search *.htm.\n"
            "The *_files subfolder is usually images only; the main .htm is often one level up.",
            file=sys.stderr,
        )
        sys.exit(3)

    kw = tuple(args.keywords)
    mapping = build_clinical_map(html_dir, kw)
    write_output_py(args.out.resolve(), mapping, str(html_dir))
    print(f"Wrote {len(mapping)} entries to {args.out.resolve()}")
    if len(mapping) == 0:
        print(
            "No matches. Check --html-dir, open a sample .html in a browser, "
            "and adjust iter_pairs_from_soup() if class names differ.",
            file=sys.stderr,
        )
    else:
        print("Merge WARLPIRI_CLINICAL_MAP into api/bridge/warlpiri_dict.py as needed.")


if __name__ == "__main__":
    main()
