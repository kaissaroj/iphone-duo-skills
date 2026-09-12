#!/usr/bin/env python3
"""Grade eval outputs for the iPhone Duo skills.

Usage: grade.py <iteration-dir>

For each eval-*/{with_skill,without_skill}/outputs/ it checks the assertions
below and writes grading.json next to the outputs dir. Assertions are regexes
over the concatenated text of every file in outputs/. 'invented' assertions
pass when NONE of the listed hallucination-prone symbols appear.
"""
import json, re, sys, pathlib

# Symbols that do NOT exist (or aren't in Apple's samples) but which models
# plausibly invent for a folding phone. Any hit = the output is guessing.
INVENTED = [
    r"\bFoldableView\b", r"\bHingeView\b", r"\bDualScreen[A-Za-z]*\b", r"\bTwoPane[A-Za-z]*\b",
    r"\bfoldState\b", r"\bisFolded\b", r"\bfoldingRegion\b", r"\bfoldRegion\b", r"\bhingeAngle\b",
    r"\bUIFold[A-Za-z]*\b", r"\bUIHinge(?!Interaction)\w*\b", r"\bUIDisplay(Pose|Posture)\b",
    r"\bdevicePosture\b", r"\bUISplitArrangementView\b",
    r"\bArrangementStyle\.split\b(?!\.axes)", r"\.arrangementStyle\(", r"\bSplitArrangementView\b",
    r"\breservedRegion\(", r"\breservedAreas\b", r"\bsafeAreaRegions\b", r"\bcutoutRegions\b",
    r"\bverticalToolbar\b", r"\btoolbarAxis\b", r"\.toolbarPlacement\(\.vertical", r"\bverticalBarBehavior\s*=",
    r"\bUIBarButtonItem\.Axis\b", r"\bpreferredAxis\b", r"\btoolbarOrientation\b",
    r"\bUIVerticalToolbar\b", r"\bsideBar(Items|Placement)\b",
]

EVALS = {
    "eval-0-layout-now-playing-arrangement": {
        "uses ArrangementView with primary/secondary closure": r"ArrangementView\s*\{[\s\S]*?\}\s*secondary:\s*\{",
        "sets .arrangementViewStyle(.split…)": r"\.arrangementViewStyle\(\s*\.split",
        "arrangement is inside NavigationStack (not the reverse)": r"NavigationStack\s*\{[\s\S]*?ArrangementView",
        "no navigation container inside ArrangementView": r"^(?![\s\S]*ArrangementView\s*\{[^}]*Navigation(Stack|SplitView))",
        "no HStack used for the two panes": r"^(?![\s\S]*HStack\s*\{[\s\S]{0,200}PlayerView)",
        "does not use UIScreen.main or orientation checks": r"^(?![\s\S]*(UIScreen\.main|interfaceOrientation|isLandscape))",
        "invented": INVENTED,
    },
    "eval-1-toolbar-mail-style-actions": {
        "no custom UIToolbar instantiated": r"^(?![\s\S]*UIToolbar\()",
        "items configured via navigationItem groups or pinnedTrailingGroup": r"navigationItem\.(leadingItemGroups|trailingItemGroups|pinnedTrailingGroup|centerItemGroups|additionalOverflowItems)",
        "Select/Done item uses axisBehavior = .horizontalOnly": r"axisBehavior\s*=\s*\.horizontalOnly",
        "Inbox count uses badge = .count(…)": r"\.badge\s*=[^\n]*\.count\(",
        "More menu merged into additionalOverflowItems": r"additionalOverflowItems\s*=",
        "Compose has visibilityPriority = .high": r"visibilityPriority\s*=\s*\.high",
        "every UIBarButtonItem has both title and image": r"^(?![\s\S]*UIBarButtonItem\(\s*image:[^,)]*,\s*(style|menu|primaryAction))",
        "does not put ellipsis on a non-overflow menu": r"^(?![\s\S]*UIBarButtonItem\([^)]*ellipsis[^)]*menu:)",
        "invented": INVENTED,
    },
    "eval-2-audit-legacy-uikit-project": {
        "flags UIScreen.main (Bad.swift:4/5)": r"UIScreen\.main",
        "flags orientation check (Bad.swift:6)": r"orientation|isLandscape",
        "flags userInterfaceIdiom (Bad.swift:7)": r"userInterfaceIdiom|idiom",
        "flags symmetric safe-area math (Bad.swift:8)": r"safeAreaInsets\.left\s*\*\s*2|asymmetric|symmetr",
        "flags custom UIToolbar (Bad.swift:9)": r"UIToolbar",
        "flags image-only bar items need a title (Bad.swift:10)": r"title",
        "flags ellipsis on custom More menu (Bad.swift:11)": r"ellipsis",
        "flags card.center (Bad.swift:13) / fold": r"center",
        "flags supportedInterfaceOrientations (Bad.swift:15)": r"supportedInterfaceOrientations",
        "flags NavigationSplitView inside ArrangementView (Grid.swift:6)": r"ArrangementView[\s\S]{0,300}Navigation|Navigation[\s\S]{0,300}ArrangementView",
        "flags 3-column grid (Grid.swift:3)": r"(three|3)[ -]column|even (number of )?columns|odd",
        "flags fixed .frame(width: 390) (Grid.swift:8)": r"390",
        "recommends reservedRegions or ArrangementView as fix": r"reservedRegions|ArrangementView",
        "recommends additionalOverflowItems / ToolbarOverflowMenu": r"additionalOverflowItems|ToolbarOverflowMenu",
        "cites file:line references": r"\.swift:\d+",
        "has severity tiers": r"(?i)blocking|critical|high",
        "invented": INVENTED,
    },
}

def gather(outdir: pathlib.Path) -> str:
    parts = []
    for p in sorted(outdir.rglob("*")):
        if p.is_file():
            try: parts.append(p.read_text(errors="replace"))
            except Exception: pass
    return "\n".join(parts)

def grade(text: str, assertions: dict):
    results = []
    for name, rule in assertions.items():
        if name == "invented":
            hits = [pat for pat in rule if re.search(pat, text)]
            results.append({"text": "no invented / unverified API names",
                            "passed": not hits,
                            "evidence": "hits: " + ", ".join(hits) if hits else "none found"})
        else:
            m = re.search(rule, text, re.M)
            results.append({"text": name, "passed": bool(m),
                            "evidence": (m.group(0)[:120] if m else "not found")})
    return results

def main():
    it = pathlib.Path(sys.argv[1])
    summary = {}
    for ev, assertions in EVALS.items():
        for cfg in ("with_skill", "without_skill"):
            outdir = it / ev / cfg / "run-1" / "outputs"
            if not outdir.exists():
                outdir = it / ev / cfg / "outputs"
            if not outdir.exists():
                continue
            res = grade(gather(outdir), assertions)
            passed = sum(r["passed"] for r in res)
            (outdir.parent / "grading.json").write_text(json.dumps({
                "expectations": res,
                "summary": {"passed": passed, "total": len(res), "pass_rate": passed / len(res)},
            }, indent=2))
            summary[f"{ev}/{cfg}"] = f"{passed}/{len(res)}"
            print(f"{ev}/{cfg}: {passed}/{len(res)}")
            for r in res:
                if not r["passed"]:
                    print(f"   ✗ {r['text']} — {r['evidence']}")
    return summary

if __name__ == "__main__":
    main()
