---
name: iphone-duo-audit
license: MIT
description: Audit an existing SwiftUI or UIKit iOS app for iPhone Duo readiness (Apple's folding, dual-display iPhone, iOS 27.1) and produce a prioritized findings report. Runs a grep-based scan for known-bad patterns (UIScreen.main, orientation/idiom checks, fixed widths, symmetric safe-area math, custom UIToolbar/UINavigationBar, missing item titles, custom overflow menus, odd grid columns, navigation inside ArrangementView) then walks a checklist from Apple's HIG and tech talks. Use this whenever someone asks "does my app work on iPhone Duo / the foldable iPhone", "make this Duo-ready", "is this iOS 27 adaptive", "review for the new iPhone", "what breaks when the device folds", or wants an app-resizability review of iOS code — even without naming the device. Not for writing new layout code (use iphone-duo-layout) or toolbar code (iphone-duo-toolbars).
---

# iPhone Duo readiness audit

iPhone Duo is Apple's folding iPhone (September 2026, iOS 27.1). It has an outer display (compact width, wider and shorter than other iPhones), an inner display (regular/regular, divided by a hinge), vertical toolbars on the side, asymmetric safe areas, Split View multitasking, and a fold that splits the inner display in two. Most of what breaks is ordinary non-adaptive iOS code — the same things that break in Split View on iPad or iPhone Mirroring — plus a handful of Duo-specific items.

This skill produces a **report**, not code changes. Its value is knowing *what* to look for; the fixes are small and are described inline. The API names it references are verified against Apple's samples (see the `iphone-duo-layout` and `iphone-duo-toolbars` skills for the full API surface).

## Procedure

### 1. Scope

Find the Swift sources (`find . -name '*.swift' -not -path '*/Pods/*' -not -path '*/.build/*' | wc -l`). Note whether it's SwiftUI, UIKit, or mixed, and whether there's a games / camera component — those get extra checklist sections. Check the deployment target and SDK in `project.pbxproj` — everything Duo-specific needs the **iOS 27.1 SDK / Xcode 27.1**; if the project is older, say so up front, because vertical bars and edge-to-edge layout simply won't appear until it's rebuilt.

### 2. Mechanical scan

Run the bundled script from the repo root:

```bash
bash <skill-path>/scripts/duo_audit.sh .
```

It prints `[CATEGORY] file:line: text` for candidate matches grouped A–L, matching the sections of [references/checklist.md](references/checklist.md). These are **candidates**: a `UIScreen.main.scale` in a screenshot utility is real; a `supportedInterfaceOrientations` override in a video player may be intentional. Open each hit and decide.

If the script can't run (no bash, restricted tools), do the same greps by hand — the regexes are readable in the script.

### 3. Read for the things grep can't see

The scan misses the highest-impact issues, which are structural. For each main screen, ask:

- **Is anything centered on the full inner display?** A hero image, a player, a floating action panel, a modal card. When the device folds, that thing straddles the hinge. Candidates for a `NavigationSplitView`, an `ArrangementView` (split for main/detail, overlay for foreground/background), or explicit displacement via `reservedRegions(kind: .division)`.
- **Does the hierarchy change between compact and regular?** It must be the *same* hierarchy with one more level visible on the inner display — not a different app. Mail: list *or* message closed, both open.
- **Do the bars come from the system?** `.toolbar` inside `NavigationStack`/`TabView`, or `navigationItem` under `UINavigationController`. Anything hand-built stays horizontal and steals vertical space.
- **What overflows first?** On the outer display in landscape, items overflow constantly. Is there a compression preference and are visibility priorities set on the actions that matter (Compose, New, badged items)?
- **Would a control be unreachable if the bar were on the *left*?** Split View puts the left app's bar on its left edge. Any layout that pins interactive content to the leading edge with a fixed offset is at risk.
- **Games:** locked orientation is fine, but does it fill every pose without letterboxing?

Load the full checklist at [references/checklist.md](references/checklist.md) and go through it section by section, marking each item pass / fail / n/a with a file reference.

### 4. Report

Write the report in this shape. Severity is about user impact when the device is opened, closed, folded, or split — not about how hard the fix is.

```markdown
# iPhone Duo readiness — <app name>

**SDK:** <deployment target / Xcode> — <ready | needs iOS 27.1 SDK rebuild>
**Stack:** SwiftUI / UIKit / mixed · <N> screens reviewed

## Summary
<3–5 sentences: overall shape, the one or two things that would most embarrass the app on a Duo, and the good news.>

## Blocking  (content hidden, controls unreachable, crashes)
- **<Title>** — `path/File.swift:123`
  What: …  Why on Duo: …  Fix: … (API)

## Should fix  (works but degraded: wasted space, jumpy layout, wrong overflow)
- …

## Nice to have  (polish: sidebar on inner display, hinge effects, laptop-pose layout)
- …

## Checklist
| Section | Status | Notes |
|---|---|---|
| A. Screen references | ✅ / ⚠️ / ❌ | … |
| … | | |

## Test plan
Poses to verify in Device Hub (Xcode 27.1): closed portrait, closed landscape, open portrait, open landscape, book fold, Split View left, Split View right, PiP pinned. Note the screens most likely to fail in each.
```

Keep each finding to one file reference and one concrete fix. Don't pad with generic advice — if a section is clean, say so in one line.

## Severity guide

| Blocking | Should fix | Nice to have |
|---|---|---|
| `UIScreen.main` for layout; orientation-gated layout; fixed widths that overflow in Split View; controls under the vertical bar; custom bars carrying primary actions; centered interactive UI under the fold | Missing item titles; text where a badge would do; no visibility priority; custom overflow menu; odd grid columns; symmetric inset math that happens to work today; `.horizontalOnly` missing on symbol⇄text toggles | Sidebar tab placement; `ArrangementView` migration of a working `HStack`; hinge-driven effects; laptop-pose layout; concentric corners |

## Related

- `iphone-duo-layout` — size classes, safe areas, reserved regions, arrangement views, hinge (the fixes for sections A–D, G–K)
- `iphone-duo-toolbars` — vertical bars, ordering, overflow, priority (the fixes for E–F)
- Apple's own **App Resizability** skill ships with Xcode 27.1 and covers SwiftUI + iPhone Duo; recommend running it as a second pass.
- HIG: https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo
- Tech talk *Prepare your app for iPhone Duo*: https://developer.apple.com/videos/play/tech-talks/111461
