# iPhone Duo Readiness Audit

**Scope:** `/Users/saroj/Projects/Personal/OpenSources/iphoneDuoSkills/evals/fixture`
**Files reviewed:** `Bad.swift` (UIKit, 17 lines), `Grid.swift` (SwiftUI, 12 lines)
**Date:** 2026-09-12

## Summary

The project is **not ready** for a dual-display / foldable iPhone. Both files assume a single fixed-size screen with one size class, one orientation, and a static safe area. On a device whose canvas changes when it folds, unfolds, or spans a hinge, the current code will (a) lay out against the wrong screen size, (b) refuse to rotate, (c) center content on top of the hinge, and (d) hard-code a width that ignores the larger unfolded canvas entirely.

| Priority | Count | Theme |
|---|---|---|
| P0 – Blocker | 4 | Fixed-size / fixed-orientation assumptions that break on fold or span |
| P1 – High | 5 | Device-class and screen-based queries that give wrong answers on Duo |
| P2 – Medium | 4 | Toolbar / navigation / lifecycle hygiene that degrades the experience |
| P3 – Low | 2 | Code-quality issues that will make the fixes harder |

---

## P0 – Blockers

### P0-1. Locked to portrait — `Bad.swift:15`
```swift
override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
```
A folding device is routinely held in landscape (book/laptop posture) and can change its effective orientation as it opens. Returning `.portrait` forces the system to letterbox or rotate the content against the hinge. Return `.all` (or `.allButUpsideDown`) and let Auto Layout / size classes drive layout instead of orientation.

### P0-2. Hard-coded `.frame(width: 390)` — `Grid.swift:8`
```swift
.frame(width: 390)
```
390 pt is the width of a single-screen iPhone. When the device is unfolded the root view stays 390 pt wide on a canvas that may be ~2x as wide, leaving the second panel empty (or clipping the `NavigationSplitView` sidebar+detail pair into one panel). Remove the fixed width and rely on the container, or use `containerRelativeFrame` / `GeometryReader` if you need proportional sizing.

### P0-3. Layout derived from `UIScreen.main.bounds` — `Bad.swift:4`
```swift
let w = UIScreen.main.bounds.width
```
`UIScreen.main` is deprecated and, on a multi-display device, reports the *screen*, not the *window scene*. A folded/spanned window can occupy any portion of one or both panels, so `w` will be wrong whenever the app is not full-screen on a single panel. Use `view.window?.windowScene?.screen.bounds` at minimum, and preferably size to `view.bounds` / the trait collection instead of the screen at all.

### P0-4. Content centered on the hinge — `Bad.swift:13`
```swift
card.center = view.center
```
When the window spans both panels, `view.center` sits exactly on the hinge seam. Any hero card, dialog, or CTA placed there is bisected. Prefer a two-column layout when the horizontal size class is `.regular`, or align content to one panel. (Also see P3-1: `card` is not declared in this file.)

---

## P1 – High

### P1-1. Orientation used as a layout signal — `Bad.swift:6`
```swift
if UIDevice.current.orientation.isLandscape { }
```
`UIDevice.orientation` describes the physical device, not the window, and is unreliable at `viewDidLoad` (often `.unknown`). On Duo the window can be landscape-shaped while the device reports portrait. Branch on `traitCollection.horizontalSizeClass` / `verticalSizeClass` or `view.bounds` aspect, and react in `viewWillTransition(to:with:)` / `traitCollectionDidChange`.

### P1-2. Idiom check used as a layout signal — `Bad.swift:7`
```swift
if UIDevice.current.userInterfaceIdiom == .pad { }
```
An unfolded Duo is still `.phone` idiom but presents an iPad-like regular-width canvas. Any "iPad-only" two-column or split behaviour gated on `.pad` will be withheld from the unfolded phone. Gate on size class, not idiom.

### P1-3. Display scale read from `UIScreen.main` — `Bad.swift:5`
```swift
let scale = UIScreen.main.scale
```
Same problem as P0-3: two panels may not share the same scale factor, and the value is fixed at load. Use `traitCollection.displayScale`, which is per-view and updates when the view moves between displays.

### P1-4. Safe-area math assumes symmetric insets — `Bad.swift:8`
```swift
let width = view.bounds.width - view.safeAreaInsets.left * 2
```
This assumes `left == right`. On a spanned window the hinge introduces an asymmetric inset (or, depending on the OS, no inset at all on the hinge side while the outer edge still has one). Subtract `left + right` individually, and better still use `safeAreaLayoutGuide` / `layoutMarginsGuide` constraints rather than manual arithmetic. Note also that `safeAreaInsets` are not yet valid in `viewDidLoad` — this value is `0` here regardless of device.

### P1-5. All sizing done once in `viewDidLoad` — `Bad.swift:3-14`
Every value above is computed exactly once. A foldable changes its window size at runtime (fold, unfold, span, un-span). None of this logic re-runs. Move size-dependent work into `viewWillLayoutSubviews`, `viewWillTransition(to:with:)`, or trait-change callbacks, or eliminate it in favour of Auto Layout constraints.

---

## P2 – Medium

### P2-1. `NavigationStack` wrapping `NavigationSplitView` — `Grid.swift:5-7`
```swift
NavigationStack {
    ArrangementView { NavigationSplitView { ... } detail: { ... } } secondary: { Text("c") }
}
```
Nesting a `NavigationSplitView` inside a `NavigationStack` is unsupported and produces double navigation bars and broken back behaviour. On Duo the split view is exactly the component that should own the two panels; the outer stack prevents it from doing so. Make `NavigationSplitView` (or the `ArrangementView`) the root and put stacks *inside* the columns if needed.

### P2-2. `ArrangementView` primary/secondary content is not designed for the seam — `Grid.swift:6`
The primary pane is a full split view and the secondary is a single `Text("c")`. If `ArrangementView` maps primary/secondary to the two panels, the primary panel will try to show sidebar+detail in half the canvas while the secondary panel shows one word. Decide what belongs on each panel (e.g. sidebar on primary, detail on secondary) rather than nesting a split inside one side.

### P2-3. Toolbar items with no actions, no labels — `Bad.swift:10-12`, `Grid.swift:9`
```swift
UIBarButtonItem(image: UIImage(systemName: "square"), style: .plain, target: nil, action: nil)
UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: nil)
ToolbarItem { Image(systemName: "gear") }
```
None of these have a `target`/`action`, `menu`, or accessibility label, and the SwiftUI one is a bare `Image` rather than a `Button`. On a wider unfolded canvas toolbars gain room; the system can promote items to labelled buttons only if they are proper actions. Give each item an action (or `menu`) and an `accessibilityLabel`. The `UIToolbar()` at `Bad.swift:9` is also never added to the hierarchy.

### P2-4. `columns` declared but never used — `Grid.swift:3`
```swift
let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
```
Presumably intended for a `LazyVGrid`. If it is wired up later, a fixed 3-column grid will produce very wide cells when unfolded and cramped cells when folded. Prefer `GridItem(.adaptive(minimum:))` so the column count follows the available width.

---

## P3 – Low

### P3-1. Undefined identifier `card` — `Bad.swift:13`
`card` is referenced but never declared; the file does not compile as written. Fix before any of the layout changes above can be verified.

### P3-2. `super.viewDidLoad()` never called — `Bad.swift:3`
Standard lifecycle hygiene; omission will bite once trait-change handling is added.

---

## Recommended order of work

1. **Unlock orientation** (P0-1) and **remove the fixed width** (P0-2) — one-line changes with the biggest payoff.
2. **Replace `UIScreen.main` / `UIDevice` queries** (P0-3, P1-1, P1-2, P1-3) with trait-collection and view-bounds based logic.
3. **Move sizing out of `viewDidLoad`** (P1-5) and fix the safe-area arithmetic (P1-4).
4. **Re-architect the SwiftUI root** (P2-1, P2-2) so `NavigationSplitView` / `ArrangementView` is the top-level container.
5. **Fix hinge-centred content** (P0-4) once the layout is size-class driven.
6. Clean up toolbar items and the unused grid (P2-3, P2-4), then compile fixes (P3-1, P3-2).

## Verification checklist

- Run on a Duo simulator in folded, unfolded-portrait, unfolded-landscape and spanned states; confirm no content sits on the seam.
- Rotate in every posture; confirm the VC rotates and re-lays out.
- Toggle fold at runtime; confirm sizes recompute (no stale 390 pt or `UIScreen` values).
- Enable Dynamic Type at the largest accessibility size on the folded panel to confirm the toolbar collapses gracefully.
