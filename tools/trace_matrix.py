"""
trace_matrix.py - Generate the Tandem requirements traceability matrix (RTM).

Reads the SysML v2 model files and writes a Markdown report:
  1. Requirements -> scenarios (ID, name, shall text, verify method, traces)
  2. Scenarios -> requirements (per use case, every action and what covers it)
  3. Gaps (unlinked requirements, uncovered actions, broken references)

The model stays the single source of truth; this is just a renderer.

Usage (from the repo root):
    python3 tools/trace_matrix.py
    python3 tools/trace_matrix.py --model model_v2 --out docs/traceability_matrix.md
"""
import argparse
import re
from collections import defaultdict
from datetime import date
from pathlib import Path

# ---------- patterns (match the conventions used in model_v2) ----------
PACKAGE = re.compile(r"^\s*package\s+(\w+)\s*\{", re.M)
REQUIREMENT = re.compile(
    r"requirement\s+<'([^']+)'>\s+(\w+)\s*:\s*\w+\s*\{(.*?)\n\s*\}", re.S)
DOC = re.compile(r"doc\s*/\*(.*?)\*/", re.S)
VERIFY = re.compile(r"comment\s+Verify\s*/\*(.*?)\*/", re.S)
USE_CASE = re.compile(r"use case def\s+(\w+)\s*\{")
ACTION = re.compile(r"action\s+(\w+)\s*\{\s*doc\s*/\*(.*?)\*/", re.S)
DEPENDENCY = re.compile(r"dependency\s+from\s+(\w+)\s+to\s+([\w:]+)\s*;")


def clean(text):
    """Collapse whitespace and escape Markdown table pipes."""
    return " ".join(text.split()).replace("|", "\\|")


def owner_at(pos, markers):
    """Return the name of the last marker (package / use case) before pos."""
    name = ""
    for start, marker_name in markers:
        if start > pos:
            break
        name = marker_name
    return name


def id_sort_key(req_id):
    """Sort 'FLW-10' after 'FLW-9' (prefix, then number)."""
    prefix, _, num = req_id.partition("-")
    return (prefix, int(num) if num.isdigit() else 0)


def parse_requirements(text):
    packages = [(m.start(), m.group(1)) for m in PACKAGE.finditer(text)]
    reqs = {}
    for m in REQUIREMENT.finditer(text):
        req_id, name, body = m.groups()
        doc = DOC.search(body)
        verify = VERIFY.search(body)
        reqs[name] = {
            "id": req_id,
            "name": name,
            "package": owner_at(m.start(), packages),
            "doc": clean(doc.group(1)) if doc else "",
            "verify": clean(verify.group(1)) if verify else "",
        }
    return reqs


def parse_use_cases(text):
    use_cases = [(m.start(), m.group(1)) for m in USE_CASE.finditer(text)]
    actions = defaultdict(list)          # use case -> [(action, doc)]
    for m in ACTION.finditer(text):
        uc = owner_at(m.start(), use_cases)
        actions[uc].append((m.group(1), clean(m.group(2))))
    return [name for _, name in use_cases], actions


def build_report(reqs, uc_order, actions, deps):
    known_targets = set(uc_order)
    for uc, acts in actions.items():
        known_targets.update(f"{uc}::{a}" for a, _ in acts)

    req_links = defaultdict(list)        # requirement name -> [targets]
    target_links = defaultdict(list)     # target -> [requirement IDs]
    broken = []
    for src, dst in deps:
        if src not in reqs:
            broken.append(f"`{src}` -> `{dst}`: no requirement named `{src}`")
            continue
        if dst not in known_targets:
            broken.append(f"`{src}` -> `{dst}`: no use case or action named `{dst}`")
            continue
        req_links[src].append(dst)
        target_links[dst].append(reqs[src]["id"])

    ordered = sorted(reqs.values(), key=lambda r: id_sort_key(r["id"]))
    n_actions = sum(len(a) for a in actions.values())
    covered = sum(1 for uc, acts in actions.items()
                  for a, _ in acts if target_links.get(f"{uc}::{a}"))
    unlinked = [r for r in ordered if not req_links[r["name"]]]

    out = ["# Tandem - Requirements Traceability Matrix", "",
           f"Generated {date.today().isoformat()} by `tools/trace_matrix.py` from `model_v2/`. "
           "Do not edit by hand; change the model and re-run.", "",
           "## Summary", "",
           "| | Count |", "|---|---|",
           f"| Requirements | {len(reqs)} |",
           f"| Requirements with at least one trace | {len(reqs) - len(unlinked)} |",
           f"| Scenario actions | {n_actions} |",
           f"| Actions covered by a requirement | {covered} |",
           f"| Trace links | {len(deps)} |",
           f"| Broken references | {len(broken)} |", ""]

    # 1. Requirements -> scenarios
    out += ["## 1. Requirements to scenarios", ""]
    current_pkg = None
    for r in ordered:
        if r["package"] != current_pkg:
            current_pkg = r["package"]
            out += ["", f"### {current_pkg}", "",
                    "| ID | Name | Requirement | Verify | Traces to |",
                    "|---|---|---|---|---|"]
        targets = "<br>".join(f"`{t}`" for t in req_links[r["name"]]) or "**none**"
        out.append(f"| {r['id']} | `{r['name']}` | {r['doc']} | {r['verify']} | {targets} |")

    # 2. Scenarios -> requirements
    out += ["", "## 2. Scenarios to requirements", ""]
    for uc in uc_order:
        out += [f"### {uc}", ""]
        whole = target_links.get(uc)
        if whole:
            out += [f"Whole use case: {', '.join(sorted(set(whole), key=id_sort_key))}", ""]
        out += ["| Action | Step | Covered by |", "|---|---|---|"]
        for a, doc in actions.get(uc, []):
            ids = sorted(set(target_links.get(f"{uc}::{a}", [])), key=id_sort_key)
            out.append(f"| `{a}` | {doc} | {', '.join(ids) or '-'} |")
        out.append("")

    # 3. Gaps
    out += ["## 3. Gaps", "", "### Requirements with no trace", ""]
    out += [f"- {r['id']} `{r['name']}`" for r in unlinked] or ["None."]
    out += ["", "### Actions not covered by any requirement", "",
            "Some are deliberate (operator steps or references to other use cases).", ""]
    gaps = [f"- `{uc}::{a}`: {doc}" for uc in uc_order
            for a, doc in actions.get(uc, []) if not target_links.get(f"{uc}::{a}")]
    out += gaps or ["None."]
    out += ["", "### Broken references", ""]
    out += [f"- {b}" for b in broken] or ["None."]
    return "\n".join(out) + "\n"


def build_html(reqs, uc_order, actions, deps):
    """A real grid: requirements down the side, scenario actions across the top."""
    from html import escape

    links = set(deps)
    # Columns: whole use case first (for mission-wide links), then its actions.
    cols = []                                         # (use case, action or None, tooltip)
    for uc in uc_order:
        if any(dst == uc for _, dst in deps):
            cols.append((uc, None, f"{uc} (whole use case)"))
        for a, doc in actions.get(uc, []):
            cols.append((uc, a, doc))

    def target(col):
        uc, a, _ = col
        return uc if a is None else f"{uc}::{a}"

    ordered = sorted(reqs.values(), key=lambda r: id_sort_key(r["id"]))
    col_hit = {target(c): any((r["name"], target(c)) in links for r in ordered) for c in cols}

    # Header row 1: use case names spanning their columns.
    spans, row1 = [], ['<th class="corner" rowspan="2">Requirement</th>']
    for c in cols:
        if spans and spans[-1][0] == c[0]:
            spans[-1][1] += 1
        else:
            spans.append([c[0], 1])
    for i, (uc, n) in enumerate(spans):
        row1.append(f'<th class="uc g{i % 2}" colspan="{n}">{escape(uc)}</th>')

    # Header row 2: action names, rotated; uncovered actions flagged.
    group_of, i = {}, -1
    last = None
    for c in cols:
        if c[0] != last:
            i, last = i + 1, c[0]
        group_of[target(c)] = i % 2
    row2 = []
    for c in cols:
        t = target(c)
        name = "(whole)" if c[1] is None else c[1]
        gap = "" if col_hit[t] else " gap"
        row2.append(f'<th class="act g{group_of[t]}{gap}" title="{escape(c[2])}">'
                    f'<span>{escape(name)}</span></th>')

    body, current_pkg = [], None
    for r in ordered:
        if r["package"] != current_pkg:
            current_pkg = r["package"]
            body.append(f'<tr class="pkg"><th colspan="{len(cols) + 1}">{escape(current_pkg)}</th></tr>')
        hits = [(r["name"], target(c)) in links for c in cols]
        gap = "" if any(hits) else " gap"
        cells = "".join(f'<td class="g{group_of[target(c)]}">{"●" if h else ""}</td>'
                        for c, h in zip(cols, hits))
        body.append(f'<tr><th class="req{gap}" title="{escape(r["doc"])} [Verify: {escape(r["verify"])}]">'
                    f'{escape(r["id"])} <small>{escape(r["name"])}</small></th>{cells}</tr>')

    n_gap_cols = sum(1 for v in col_hit.values() if not v)
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<title>Tandem Trace Matrix</title>
<style>
  :root {{ --bg:#fff; --fg:#1d2330; --line:#d8dce3; --g0:#f6f7f9; --g1:#ffffff;
          --head:#2f3a4c; --headfg:#fff; --dot:#2563eb; --gap:#fde2e1; --gapfg:#a1261d; }}
  @media (prefers-color-scheme: dark) {{
    :root {{ --bg:#16181d; --fg:#e4e7ec; --line:#2c313b; --g0:#1c1f26; --g1:#16181d;
            --head:#2a3240; --headfg:#e4e7ec; --dot:#6ea8ff; --gap:#4a1f1d; --gapfg:#ffb4ab; }}
  }}
  body {{ margin:0; padding:16px; background:var(--bg); color:var(--fg);
         font:13px/1.3 system-ui, sans-serif; }}
  h1 {{ font-size:18px; margin:0 0 4px; }}
  p.meta {{ margin:0 0 12px; opacity:.75; }}
  .wrap {{ overflow:auto; max-height:calc(100vh - 90px); border:1px solid var(--line); }}
  table {{ border-collapse:separate; border-spacing:0; }}
  th, td {{ border-right:1px solid var(--line); border-bottom:1px solid var(--line); }}
  thead th {{ position:sticky; z-index:2; background:var(--head); color:var(--headfg); }}
  thead tr:first-child th {{ top:0; height:24px; }}
  thead tr:nth-child(2) th {{ top:25px; }}
  th.corner {{ left:0; z-index:4; min-width:230px; text-align:left; padding:4px 8px; }}
  th.uc {{ font-weight:600; padding:4px 6px; white-space:nowrap; }}
  th.act {{ height:150px; width:22px; min-width:22px; vertical-align:bottom; padding:4px 0;
           font-weight:400; }}
  th.act span {{ writing-mode:vertical-rl; transform:rotate(180deg); white-space:nowrap; }}
  th.act.gap {{ background:var(--gap); color:var(--gapfg); }}
  tbody th.req {{ position:sticky; left:0; z-index:1; background:var(--bg); text-align:left;
                 padding:3px 8px; white-space:nowrap; font-weight:600; }}
  tbody th.req small {{ font-weight:400; opacity:.7; }}
  tbody th.req.gap {{ background:var(--gap); color:var(--gapfg); }}
  tr.pkg th {{ position:sticky; left:0; text-align:left; padding:6px 8px; background:var(--g0);
              font-weight:700; }}
  td {{ text-align:center; color:var(--dot); font-size:14px; height:22px; }}
  td.g0 {{ background:var(--g0); }} td.g1 {{ background:var(--g1); }}
  tbody tr:hover td, tbody tr:hover th.req {{ outline:1px solid var(--dot); outline-offset:-1px; }}
</style></head><body>
<h1>Tandem trace matrix</h1>
<p class="meta">Generated {date.today().isoformat()} from model_v2 · {len(reqs)} requirements ·
{len(cols)} columns · {len(deps)} links · red = no link ({n_gap_cols} uncovered columns).
Hover a name for its text.</p>
<div class="wrap"><table>
<thead><tr>{''.join(row1)}</tr><tr>{''.join(row2)}</tr></thead>
<tbody>{''.join(body)}</tbody>
</table></div>
</body></html>
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    ap.add_argument("--model", default="model_v2", help="folder with the .sysml files")
    ap.add_argument("--out", default="docs/traceability_matrix.md", help="Markdown output path")
    ap.add_argument("--html", default="docs/traceability_matrix.html", help="HTML grid output path")
    args = ap.parse_args()

    model = Path(args.model)
    reqs = parse_requirements((model / "requirements.sysml").read_text())
    uc_order, actions = parse_use_cases((model / "use_cases.sysml").read_text())
    deps = DEPENDENCY.findall((model / "traceability.sysml").read_text())

    for path, content in ((args.out, build_report(reqs, uc_order, actions, deps)),
                          (args.html, build_html(reqs, uc_order, actions, deps))):
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        Path(path).write_text(content)
    print(f"Wrote {args.out} and {args.html}: {len(reqs)} requirements, {len(deps)} links")


if __name__ == "__main__":
    main()