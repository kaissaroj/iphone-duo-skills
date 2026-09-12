---
name: iphone-duo-inspect
license: MIT
description: Inspect a single iOS screen for iPhone Duo problems and show them visually — as numbered boxes drawn on a screenshot — with a fix for each. Three inputs — (A) the live app in an iPhone Duo simulator via argent MCP tools (experimental until Xcode 27.1 is common), (B) a screenshot, design export or photo of a screen the user provides, (C) the SwiftUI/UIKit source of one screen. Use this whenever someone shares an image of an iOS screen and asks how it looks on iPhone Duo / the folding iPhone / when folded / on the outer display, asks "check this screen", "what's wrong with this on Duo", "will this straddle the fold", "is anything under the side bar", wants a visual review of a running app in the simulator, or wants a specific view file checked while they're writing it. Not for whole-project audits (iphone-duo-audit) or for writing new layout/toolbar code (iphone-duo-layout, iphone-duo-toolbars).
---

# iPhone Duo screen inspection

One screen in, an **annotated picture plus a fix list** out. The rules are Apple's — HIG *Designing for iPhone Duo* and the September 2026 tech talks — and the fixes use only verified iOS 27.1 API names (listed in the `iphone-duo-layout` and `iphone-duo-toolbars` skills). What this skill adds is *seeing*: a box on the Play button that straddles the hinge is worth more than a paragraph about reserved regions.

Pick the mode from what you were given:

| You have | Mode | Section |
|---|---|---|
| The app running in an iPhone Duo simulator and argent MCP tools (`mcp__argent__*`) | **A — live** | §A |
| A PNG/JPG (simulator capture, Figma export, photo) | **B — image** | §B |
| A `.swift` file for one view / view controller | **C — code** | §C |

Modes combine: with source *and* a screenshot, do C then B and cross-reference (the code tells you *why*; the image tells you *where*).

## What you're checking for

Every mode checks the same rules. Rule ids match `iphone-duo-audit/references/checklist.md`.

![Reserved regions on the inner display](assets/safe-area-inner-camera.png) ![Vertical bar anatomy](assets/tab-bar-toolbar-layout.png)

| Rule | Blocking when… | Fix |
|---|---|---|
| **H2 fold** | An interactive element's frame crosses the hinge line while the device is partially folded. Text/images crossing it are *should-fix* (hard to read on the curve). | System component that avoids the fold (sheet, alert, menu, split view), `ArrangementView`, or displacement via `reservedRegions(kind: .division)`. |
| **D1 bar strip** | Interactive content sits under the vertical bar (trailing edge normally; *leading* edge for the left app in Split View). | Lay out inside the safe area; only backgrounds use `.ignoresSafeArea()` / `view.bounds`. |
| **D4 centering** | Content is centered on the full display width while a vertical bar is present, so it's visually off-center relative to the safe area. *Should-fix* unless the screen is immersive and non-scrolling. | Center within the safe area; or mix — full-width background, inset foreground. |
| **F3 text in the strip** | A text-only or text+symbol item appears in the vertical bar, or a wide control (segmented control) does. | Symbol + title; counts as `.badge`; text-carrying items `.axisBehavior(.horizontalOnly)`. |
| **F1 custom bar** | A hand-built toolbar (buttons in a horizontal row at the bottom) is still horizontal while system bars have gone vertical. | Move items to `.toolbar` / `navigationItem` so the system relocates them. |
| **F7 overflow** | Two "more" menus; an ellipsis on a non-overflow menu; primary actions (Compose, New) already overflowed while minor ones are visible. | `ToolbarOverflowMenu` / `additionalOverflowItems`; `visibilityPriority`. |
| **I1 parity** | A control reachable in one pose is missing in another. | Let the toolbar overflow; never drop actions per pose. |
| **H4 grid** | An odd number of grid columns puts a column on the hinge. | Even column count, decided with `.includeInactive`. |
| **H5 laptop pose** | In the propped-up pose, tappable controls are on the top half. | Controls bottom, glanceable content top. |
| **G1 hierarchy** | The inner display shows a *different* structure from the outer, not one more level of the same hierarchy. | `NavigationSplitView` / `ArrangementView`; same hierarchy inside and out. |

Severity is user impact when the device is opened, closed, folded or split — not fix difficulty.

## A — Live simulator (experimental)

Needs the iPhone Duo runtime (Xcode 27.1 → Device Hub) and the argent MCP tools. Follow the `argent-device-interact` skill for tool mechanics; this section is only what's Duo-specific. Before the first tap, read that skill's tapping rule — frames come from `describe`, never from pixels.

1. `list-devices` → pick the booted iPhone Duo. If none is booted, say so and stop; don't fall back to a regular iPhone (the geometry is wrong).
2. For each pose you can reach — closed portrait, closed landscape, open landscape, open portrait, and folded if the user or Device Hub's controls can set it (posing is a Device Hub UI action; ask the user to fold/open if you can't drive it):
   - `screenshot` (baseline) and `describe` → the accessibility tree with normalized frames.
   - Convert the tree to the flat element list `scripts/geometry_rules.py` expects: one entry per element with `id`/`label`, `role`, `interactive` (buttons, toggles, text fields, tab items, cells with actions), `frame` `{x,y,w,h}` in 0–1 fractions. Mark elements that belong to the system bar (`system_bar: true`) — status bar, Dynamic Island, toolbar/tab-bar items on the vertical strip — so they're not reported as "content under the bar".
   - Write `pose.json`: `display`, `folded`, `orientation`, `bar_edge` (`trailing`/`leading`/null — read it off the tree: where are the toolbar items?), `bar_width_norm` (width of the status-bar/toolbar column), `fold_x_norm` or `fold_y_norm` (0.5 on the inner display when folded).
3. Run the rules, then annotate the screenshot:
   ```bash
   python3 <skill>/scripts/geometry_rules.py elements.json pose.json [elements_other_pose.json] > findings.json
   python3 <skill>/scripts/annotate.py screenshot.png findings.json annotated-<pose>.png
   ```
   Pass the element list from a *second* pose as the third argument to get parity findings (I1).
4. Read the annotated PNG yourself to sanity-check the boxes, then add anything the geometric rules can't see (G1 hierarchy, F7 overflow choices, D4 judgement calls) as extra findings.
5. Report (§Report). Note in the summary which poses were checked and which weren't reachable.

Why "experimental": Apple's Duo simulator, its describe-tree shape, and Device Hub's pose controls were all released in September 2026 and haven't been exercised by this skill on real hardware/simulators yet. The rules themselves are pose-independent geometry and are unit-tested; the wiring may need adjustment (e.g. how the fold shows up in the tree). Say this in the report.

## B — Screenshot or image

1. Read the image. Establish the pose from what you see: is there a vertical strip of controls (which edge)? is the aspect wide (outer/landscape) or near-square (inner)? is there a visible hinge/curve, or a Split View seam? If the user told you the pose, trust that instead.
2. Identify elements and their pixel boxes. Be precise — you're going to draw these. For each rule above, decide if it applies. Prefer few, certain findings over many speculative ones; if you can't tell whether something is interactive, say so in the note rather than marking it blocking.
3. Write `findings.json` (format in `scripts/annotate.py`'s docstring): pixel `box` per finding, plus `guides` — `fold_x_norm: 0.5` when the device is open (inner display), and `bar_edge` / `bar_width_norm` when a vertical bar is visible. The guides draw the hinge line and shade the strip so the reader sees *why* a box is a problem.
4. Render: `python3 <skill>/scripts/annotate.py input.png findings.json annotated.png`. If Pillow isn't installed the script writes `annotated.html` (same overlay as SVG) — deliver that, and mention `python3 -m venv .venv && .venv/bin/pip install pillow` for PNG output next time. **Read the annotated result back** and fix any box that landed on the wrong element before delivering.
5. If it's a design mockup rather than a capture, also check what's *missing*: no vertical bar drawn at all is the most common — designers still mock up horizontal bars. Flag it once (F1), not per item.

## C — Source of one screen

1. Run the mechanical scan on just that file (or its folder): `bash <audit-skill>/scripts/duo_audit.sh <dir>` from the `iphone-duo-audit` skill, or grep by hand for: `UIScreen.main`, orientation/idiom checks, `.frame(width:` with literals, `safeAreaInsets.left * 2`, `UIToolbar(`, `UIBarButtonItem(image:` without a title, `"ellipsis"` on a non-overflow menu, `ArrangementView {` containing a `Navigation…`, grids with 3/5 columns, `card.center = view.center`-style centering.
2. Then read the view as a layout: what's the root container? where do the two panes come from (HStack → `ArrangementView(.split)` candidate; ZStack → `.overlay`)? what's centered on the full width? which bars are system-managed?
3. Write the fix **as code**, not prose — a before/after snippet per finding, using only verified API names. If the user is mid-edit, keep the diff minimal and in their style.
4. If you also have a screenshot, map each code finding to a box (mode B) so the report has both.

## Report

```markdown
# Duo inspection — <screen name>   (<mode A/B/C>, pose: <…>)

![annotated](annotated.png)

| # | Severity | Rule | Element | Problem | Fix |
|---|---|---|---|---|---|
| 1 | blocking | H2 | Play button | crosses the hinge when folded | wrap player + queue in `ArrangementView(.split)` — see snippet |
| 2 | … | | | | |

## Fixes
### 1. …
```swift
// before … / after …
```

## Not checked
<poses not reachable; things the image couldn't show; "experimental" note for mode A>
```

Keep it to what you can point at. A screen with nothing wrong gets a one-line report and the annotated image with guides only — that's a useful result too.

## Files

- `scripts/annotate.py` — draws boxes/labels/guides on a PNG (Pillow), or an HTML/SVG overlay without it
- `scripts/geometry_rules.py` — H2 / D1 / D4 / F3 / I1 / H5 over a normalized element list
- `assets/` — HIG diagrams of reserved regions, the vertical bar, and Split View for reference
- Rule details and fixes: `iphone-duo-audit/references/checklist.md`, `iphone-duo-layout/references/*.md`, `iphone-duo-toolbars/references/api.md`
