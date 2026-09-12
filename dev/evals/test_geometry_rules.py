#!/usr/bin/env python3
"""Unit test for skills/iphone-duo-inspect/scripts/geometry_rules.py. Run: python3 evals/test_geometry_rules.py"""
import json, pathlib, subprocess, sys
root = pathlib.Path(__file__).resolve().parent.parent
script = root / "skills/iphone-duo-inspect/scripts/geometry_rules.py"
g = root / "evals/geometry"
out = subprocess.run([sys.executable, script, g/"elements_folded.json", g/"pose_folded.json", g/"elements_closed.json"],
                     capture_output=True, text=True, check=True).stdout
f = json.loads(out)["findings"]
got = {(x["rule"], x["element"], x["severity"]) for x in f}
want = {("H2", "play", "blocking"),      # play button straddles the fold
        ("D1", "share", "blocking"),     # share button under the trailing bar strip
        ("D4", "title", "should-fix"),   # title centered on full width, not safe area
        ("I1", "filter", "blocking")}    # filter exists closed, missing open
missing, extra = want - got, got - want
assert not missing and not extra, f"missing={missing} extra={extra}"
print(f"ok — {len(f)} findings, all expected")
