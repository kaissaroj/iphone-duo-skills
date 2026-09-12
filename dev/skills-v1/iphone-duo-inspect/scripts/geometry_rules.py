#!/usr/bin/env python3
"""Apply iPhone Duo geometric rules to an accessibility tree.

Usage:
    geometry_rules.py <elements.json> <pose.json> [<elements_other_pose.json>] > findings.json

elements.json — a flat list extracted from argent `describe` (frames are
normalized 0–1 fractions of the screen, same as argent):
[
  {"id": "playButton", "label": "Play", "role": "button", "interactive": true,
   "frame": {"x": 0.45, "y": 0.60, "w": 0.10, "h": 0.06}},
  ...
]

pose.json — what the device is doing right now:
{
  "display": "inner" | "outer",
  "folded": true | false,               # partially folded (book/laptop)
  "orientation": "landscape" | "portrait",
  "bar_edge": "trailing" | "leading" | null,   # side the vertical bar is on (null = horizontal bars)
  "bar_width_norm": 0.11,               # width of the vertical strip as a fraction; measure from the status-bar frame
  "fold_x_norm": 0.5,                   # hinge line (landscape) — or
  "fold_y_norm": 0.5,                   # hinge line (portrait, laptop pose)
  "fold_band_norm": 0.06                # width of the region to keep interactive elements out of
}

Optional third argument: the element list captured in a *different* pose.
Interactive elements present in one but missing (by id/label) in the other
are reported — "same functionality in every pose".

Prints findings.json in the format annotate.py consumes (box_norm).
"""
import json, sys

def load(p):
    with open(p) as fh: return json.load(fh)

def rect(e):
    f = e["frame"]; return f["x"], f["y"], f["w"], f["h"]

def key(e):
    return e.get("id") or e.get("label") or ""

def main():
    if len(sys.argv) < 3: print(__doc__); sys.exit(1)
    els = load(sys.argv[1]); pose = load(sys.argv[2])
    other = load(sys.argv[3]) if len(sys.argv) > 3 else None
    findings = []; n = 0
    def add(sev, title, e, rule, note=""):
        nonlocal n; n += 1
        x, y, w, h = rect(e)
        findings.append({"id": n, "severity": sev, "title": title, "rule": rule,
                         "element": key(e), "box_norm": [x, y, w, h], "note": note})

    interactive = [e for e in els if e.get("interactive")]
    text_like = [e for e in els if e.get("role", "").lower() in ("statictext", "text", "label", "image")]

    # Rule H2 — interactive element inside the fold band while partially folded.
    if pose.get("folded"):
        band = pose.get("fold_band_norm", 0.06) / 2
        if "fold_x_norm" in pose:
            fx = pose["fold_x_norm"]
            for e in interactive:
                x, y, w, h = rect(e)
                if x < fx + band and x + w > fx - band:
                    add("blocking", f"'{key(e)}' crosses the fold — hard to tap on the curve", e, "H2",
                        "Displace it into one region (reservedRegions(kind: .division)) or use a system component that avoids the fold.")
        if "fold_y_norm" in pose:
            fy = pose["fold_y_norm"]
            for e in interactive:
                x, y, w, h = rect(e)
                if y < fy + band and y + h > fy - band:
                    add("blocking", f"'{key(e)}' crosses the horizontal fold (laptop pose)", e, "H2",
                        "Move controls to the bottom region; keep glanceable content on top.")
            # Rule H5 — laptop pose: interactive elements should prefer the bottom half.
            top_interactive = [e for e in interactive if rect(e)[1] + rect(e)[3] < fy - band]
            if len(top_interactive) > len(interactive) / 2 and len(interactive) >= 4:
                for e in top_interactive[:3]:
                    add("should-fix", f"'{key(e)}' is in the top region in laptop pose", e, "H5",
                        "Tappable controls belong on the stable bottom half; the top is for content viewed at a distance.")

    # Rule D1 — interactive element overlapping the vertical-bar strip.
    if pose.get("bar_edge"):
        bw = pose.get("bar_width_norm", 0.11)
        x0, x1 = (1 - bw, 1.0) if pose["bar_edge"] == "trailing" else (0.0, bw)
        for e in interactive:
            x, y, w, h = rect(e)
            if x < x1 and x + w > x0 and not e.get("system_bar"):
                add("blocking", f"'{key(e)}' sits under the vertical bar strip", e, "D1",
                    "Keep interactive content inside the safe area; only background art may extend under the bar.")
        # Rule F3 — text in the vertical strip suggests a text-only item that couldn't go vertical
        # (it would normally stay in a horizontal bar) or a custom view placed there manually.
        for e in text_like:
            x, y, w, h = rect(e)
            if x >= x0 and x + w <= x1 and w > bw * 0.6 and e.get("system_bar"):
                add("should-fix", f"Text '{key(e)}' in the vertical bar — prefer a symbol + title", e, "F3",
                    "Give the item a symbol; text-only items belong in a horizontal bar or the overflow menu.")

    # Rule D4 — content centered on the full width when a bar is present (asymmetric safe area ignored).
    if pose.get("bar_edge"):
        bw = pose.get("bar_width_norm", 0.11)
        content_center = (1 - bw) / 2 if pose["bar_edge"] == "trailing" else 0.5 + bw / 2
        for e in els:
            x, y, w, h = rect(e)
            cx = x + w / 2
            if w > 0.5 and abs(cx - 0.5) < 0.01 and abs(cx - content_center) > 0.02 and not e.get("system_bar"):
                add("should-fix", f"'{key(e)}' is centered on the full display, not the safe area", e, "D4",
                    "Fine only for immersive, non-scrolling visuals with nothing tappable under the bar. Otherwise inset by the safe area.")

    # Rule I1 — same functionality across poses.
    if other is not None:
        here = {key(e) for e in interactive if key(e)}
        there = {key(e) for e in other if e.get("interactive") and key(e)}
        for k in sorted(there - here):
            e = next(e for e in other if key(e) == k)
            add("blocking", f"'{k}' is reachable in the other pose but missing here", e, "I1",
                "Provide the same controls in every pose; let the toolbar overflow rather than dropping actions.")

    json.dump({"findings": findings,
               "guides": {k: v for k, v in (("fold_x_norm", pose.get("fold_x_norm")),
                                            ("bar_edge", pose.get("bar_edge")),
                                            ("bar_width_norm", pose.get("bar_width_norm"))) if v is not None}},
              sys.stdout, indent=2)

if __name__ == "__main__":
    main()
