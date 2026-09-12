# iPhone Duo readiness — evals/fixture

**SDK:** unknown — no `project.pbxproj` or `Info.plist` in the fixture (2 loose Swift files). Everything Duo-specific (vertical bars, edge-to-edge, `ArrangementView`, reserved regions) requires a rebuild with the **iOS 27.1 SDK / Xcode 27.1**; confirm the host project's deployment target before any of the fixes below will take effect.
**Stack:** mixed — UIKit (`Bad.swift`, one `UIViewController`) + SwiftUI (`Grid.swift`, one `View`) · 2 screens reviewed
**Scan:** `scripts/duo_audit.sh` reported 15 candidates; all 15 confirmed as real after reading the source. No false positives.

## Summary

Both screens are built with the non-adaptive patterns that break on iPhone Duo. `Bad.swift` is a textbook legacy UIKit controller: it sizes itself from `UIScreen.main`, branches on device orientation and idiom, assumes symmetric safe-area insets, builds its own `UIToolbar` (so its actions never reach the system vertical bar), and centers a card on `view.center` — which on the open inner display puts it directly across the hinge. `Grid.swift` locks its `NavigationStack` to a hard-coded 390pt width, nests a `NavigationSplitView` inside an `ArrangementView` (unsupported), and lays out a 3-column grid so the fold lands mid-column. The two things that would most embarrass the app on a Duo are the 390pt-wide SwiftUI screen (wrong size in every pose except closed-portrait, and clipped/letterboxed in Split View) and the `UIToolbar` whose items are invisible to the vertical bar. The good news: the fixes are all small, local, one-line-to-five-line replacements with well-known adaptive APIs, and the SwiftUI screen already uses `.toolbar` inside a `NavigationStack`, which is the right structure.

## Blocking  (content hidden, controls unreachable, crashes)

- **Layout sized from `UIScreen.main`** — `evals/fixture/Bad.swift:4`
  What: `let w = UIScreen.main.bounds.width` is used as a layout width.  Why on Duo: with two displays "the main screen" is ambiguous and the value does not track open/close, Split View (half width), or pinned PiP; Apple has said `UIScreen.main` will be deprecated. Content laid out to this width overflows or leaves gaps.  Fix: use `view.bounds.width` / `view.safeAreaLayoutGuide.layoutFrame.width`, or `view.window?.windowScene?.screen` if a screen is genuinely required.

- **Fixed 390pt width on a whole navigation screen** — `evals/fixture/Grid.swift:8`
  What: `.frame(width: 390)` applied to the `NavigationStack`.  Why on Duo: the outer display is wider than 390pt (content floats with empty margins), the inner display is far wider (huge dead space, hinge lands on content), and Split View / PiP make the window narrower than 390 (content is clipped, trailing toolbar and controls can be pushed off-window).  Fix: remove the modifier; let the stack fill the window and use `@Environment(\.horizontalSizeClass)` if the layout needs to change.

- **Actions live in a hand-built `UIToolbar`** — `evals/fixture/Bad.swift:9` (items at `:10-12`)
  What: `UIToolbar()` created manually and populated with `UIBarButtonItem`s.  Why on Duo: contents of custom bars are not considered for the vertical bar, so the bar stays horizontal, eats vertical space, and its items can sit under the system vertical bar (or, for the left app in Split View, collide with the left-edge bar). The actions are effectively unreachable/duplicated.  Fix: delete the toolbar; host the VC in a `UINavigationController` and set `navigationItem.rightBarButtonItems` / `navigationItem.pinnedTrailingGroup` / `additionalOverflowItems`. Drop the `.flexibleSpace` at `:12` — spacers collapse to zero in a vertical bar.

- **Card centered on the full view — straddles the hinge** — `evals/fixture/Bad.swift:13`
  What: `card.center = view.center`.  Why on Duo: on the open inner display the view's center is the fold; a card (especially an interactive one) split across the division is the single most visible Duo failure. It also ignores the asymmetric safe area, so it can sit partly under the vertical bar.  Fix: position relative to `view.safeAreaLayoutGuide` and, if it must be manually placed, query `view.reservedRegions(kind: .division)` (with `.includeInactive` to avoid reflow mid-fold) and displace to one side; or migrate the screen to a `UISplitViewController` / SwiftUI `ArrangementView(.overlay)` so the system does it.

- **Orientation-gated layout** — `evals/fixture/Bad.swift:6`
  What: `if UIDevice.current.orientation.isLandscape { }` guards layout.  Why on Duo: the inner display does not honour the app's supported orientations, and `UIDevice.orientation` reports the physical device, not the window; combined with the `.portrait` lock at `:15` this branch never runs as intended, so any landscape-specific layout is dead.  Fix: branch on `traitCollection.horizontalSizeClass` / `verticalSizeClass` (register with `registerForTraitChanges`).

- **Idiom-gated layout** — `evals/fixture/Bad.swift:7`
  What: `if UIDevice.current.userInterfaceIdiom == .pad { }` selects the "wide" layout.  Why on Duo: the open inner display is regular/regular on a `.phone` idiom, so the iPad-style branch never fires and the app shows its phone layout stretched across both halves.  Fix: same as above — size classes, not idiom.

## Should fix  (works but degraded: wasted space, jumpy layout, wrong overflow)

- **Symmetric safe-area math** — `evals/fixture/Bad.swift:8`
  What: `view.bounds.width - view.safeAreaInsets.left * 2`.  Why on Duo: the vertical bar is a *leading or trailing* inset only (right normally, left for the left app in Split View), so left ≠ right; this either double-subtracts the bar (content too narrow) or ignores it (content under the bar).  Fix: `view.bounds.inset(by: view.safeAreaInsets).width` or `view.safeAreaLayoutGuide.layoutFrame.width`.

- **`UIScreen.main.scale` for scale** — `evals/fixture/Bad.swift:5`
  What: display scale read from the main screen.  Why on Duo: ambiguous across two displays; wrong scale makes rasterised images blurry when the app moves between displays.  Fix: `traitCollection.displayScale`.

- **`NavigationSplitView` nested inside `ArrangementView`** — `evals/fixture/Grid.swift:6`
  What: `ArrangementView { NavigationSplitView { … } detail: { … } } secondary: { … }` inside a `NavigationStack`.  Why on Duo: navigation containers inside an `ArrangementView` are unsupported — the arrangement view manages the split/overlay around the fold, and a split view inside it fights it (double columns, collapse logic runs twice, jumpy transitions on open/close).  Fix: pick one. Either `NavigationSplitView { sidebar } detail: { detail }` at the top level (it collapses when closed and avoids the fold when open), or `ArrangementView` with plain content panes and no navigation container inside.

- **Odd (3) grid column count** — `evals/fixture/Grid.swift:3`
  What: three `.flexible()` `GridItem`s.  Why on Duo: with an odd column count the fold lands on the middle column, not a gutter.  Fix: prefer an even count (2 or 4), chosen via `reservedRegions(kind: .division, .includeInactive)` / size class so it doesn't reflow mid-fold. (Note: `columns` is declared but not yet used in `body` — the finding applies once it is.)

- **Symbol-only toolbar items without titles** — `evals/fixture/Bad.swift:10`, `evals/fixture/Grid.swift:9`
  What: `UIBarButtonItem(image: "square" …)` with no `title`; `ToolbarItem { Image(systemName: "gear") }` with no label.  Why on Duo: the vertical bar's overflow/expanded forms display the title; untitled items show as a bare glyph or blank row.  Fix: `UIBarButtonItem(title: "Select", image: …)`; SwiftUI `ToolbarItem { Button("Settings", systemImage: "gear") { … } }`.

- **Custom ellipsis menu competes with the system overflow** — `evals/fixture/Bad.swift:11`
  What: `UIBarButtonItem(image: "ellipsis", menu: nil)`.  Why on Duo: the ellipsis is reserved for the single system overflow menu; on the outer display in landscape the system will add its own, giving two "…" buttons.  Fix: move these actions to `navigationItem.additionalOverflowItems`; if a separate menu is needed, give it a distinct symbol and a title.

- **No visibility priority / compression preference** — `evals/fixture/Bad.swift:9-12`, `evals/fixture/Grid.swift:9`
  What: no `visibilityPriority` on any item or group, no `verticalBarCompressionBehavior` / `toolbarVerticalCompressionBehavior`.  Why on Duo: on the outer display in landscape items overflow constantly; without priorities the system picks arbitrarily and the primary action can disappear first.  Fix: set priorities on the primary item(s) once the bars come from the system.

- **Portrait orientation lock** — `evals/fixture/Bad.swift:15`
  What: `supportedInterfaceOrientations { .portrait }`.  Why on Duo: acceptable for a non-game if intentional, but the inner display ignores it and the app must still resize for every pose; combined with the orientation check at `:6` it's clearly not intentional here, and it blocks tent-pose landscape on the outer display.  Fix: remove the override (or keep it only for a genuinely portrait-only feature) and make the layout size-class driven.

## Nice to have  (polish: sidebar on inner display, hinge effects, laptop-pose layout)

- **Adopt system two-pane containers for `Bad.swift`** — once the toolbar and centering fixes land, consider wrapping the controller in a `UISplitViewController` so main/detail collapse when closed and avoid the fold when open.
- **Concentric corners** — no `UICornerConfiguration` / `ConcentricRectangle` usage in either file; adopt on the card at `Bad.swift:13` so its corners match Duo's screen shape.
- **Hinge / laptop pose** — nothing in scope uses `UIHingeInteraction` / `onHingeChange`; not needed, but the card in `Bad.swift` is a candidate for a laptop-pose layout (glanceable content top, controls bottom).
- **Sections J–K are clean** — no hinge API misuse and no multi-scene requests.

## Checklist

| Section | Status | Notes |
|---|---|---|
| A. Screen references | ❌ | `UIScreen.main.bounds.width` (`Bad.swift:4`), `UIScreen.main.scale` (`Bad.swift:5`) |
| B. Orientation and idiom | ❌ | `UIDevice.current.orientation.isLandscape` (`Bad.swift:6`), `userInterfaceIdiom == .pad` (`Bad.swift:7`) |
| C. Fixed metrics | ❌ | `.frame(width: 390)` on the whole screen (`Grid.swift:8`) |
| D. Safe areas and margins | ❌ | `safeAreaInsets.left * 2` (`Bad.swift:8`); card centered on full view (`Bad.swift:13`); no concentric corners |
| E. Bars come from the system | ❌ | Hand-built `UIToolbar` with `.flexibleSpace` (`Bad.swift:9,12`); `Grid.swift` correctly uses `.toolbar` in a `NavigationStack` ✅ |
| F. Toolbar item content and order | ❌ | Untitled symbol items (`Bad.swift:10`, `Grid.swift:9`); custom ellipsis (`Bad.swift:11`); no priorities/compression |
| G. Two-pane layouts | ❌ | `NavigationSplitView` inside `ArrangementView` (`Grid.swift:6`); `Bad.swift` has no adaptive container |
| H. Reserved regions and the fold | ❌ | 3-column grid (`Grid.swift:3`); `view.center` card with no `reservedRegions` query (`Bad.swift:13`) |
| I. Poses and orientation | ⚠️ | `.portrait` lock (`Bad.swift:15`) — fine only if intentional; no landscape on outer display; no games |
| J. Hinge | ✅ | No hinge API usage — nothing to fix |
| K. Scenes | ✅ | No scene requests; Split View correctness depends on fixing C/D |
| L. Build and test | ⚠️ | No project file in fixture — cannot confirm iOS 27.1 SDK; no evidence of Device Hub testing |

## Test plan

Poses to verify in Device Hub (Xcode 27.1) after the fixes:

| Pose | Screens most likely to fail | What to look for |
|---|---|---|
| Closed portrait | `Grid.swift` | 390pt frame vs the wider outer display — empty side margins |
| Closed landscape | `Bad.swift` | Toolbar overflow with no priorities; `.portrait` lock blocks the pose entirely |
| Open portrait | `Bad.swift` | Card across the hinge; phone layout stretched (idiom branch never fires) |
| Open landscape | `Bad.swift`, `Grid.swift` | Orientation branch dead; split/arrangement double-columns |
| Book fold | `Bad.swift`, `Grid.swift` | Card and middle grid column under the division; content should displace to trailing region |
| Split View left | `Bad.swift` | Vertical bar on the *left*; `safeAreaInsets.left * 2` math and left-pinned controls |
| Split View right | `Grid.swift` | Window narrower than 390 → clipping; toolbar pushed off-window |
| PiP pinned | both | Live vertical shrink; anything sized from `UIScreen.main` won't update |

Run Apple's *App Resizability* skill (Xcode 27.1) as a second pass once the SDK is confirmed.
