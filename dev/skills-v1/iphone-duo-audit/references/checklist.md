# iPhone Duo readiness checklist

Each item: what to check → why it matters on iPhone Duo → how to fix. Categories match the letters printed by `scripts/duo_audit.sh`. Sources: HIG "Designing for iPhone Duo" and tech talks 111461–111466 (September 2026).

## A. Screen references

- [ ] No `UIScreen.main` (bounds, scale, nativeScale, screens).
  *Why:* A two-display device makes "the main screen" ambiguous; Apple says it will be deprecated.
  *Fix:* environment / trait collection / scene bounds. `window?.windowScene?.screen` if you truly need a screen; `traitCollection.displayScale` for scale.

## B. Orientation and idiom

- [ ] No layout decisions from interface orientation.
  *Why:* The inner display doesn't honor your supported orientations, so those branches don't run as expected.
- [ ] No layout decisions from `userInterfaceIdiom == .phone`.
  *Why:* The inner display is regular/regular on a `.phone` idiom.
  *Fix for both:* horizontal/vertical size classes (`@Environment(\.horizontalSizeClass)`, `traitCollection.horizontalSizeClass`).

## C. Fixed metrics

- [ ] No fixed widths, breakpoints, or per-device constants.
  *Why:* Sizes change on open/close, in Split View (half the inner display), with pinned Picture in Picture (app shrinks vertically live), and with iPhone Mirroring.
  *Fix:* size classes + layout margins + safe-area insets; let content expand into available space.

## D. Safe areas and margins

- [ ] Foreground/interactive content is inside the safe area (SwiftUI default; UIKit `safeAreaLayoutGuide` / `bounds.inset(by: safeAreaInsets)`).
- [ ] Background/full-bleed content may extend past it (`.ignoresSafeArea()` / `view.bounds`).
- [ ] No code assumes left == right or leading == trailing inset.
  *Why:* The vertical bar is a leading *or* trailing inset — right normally, left for the left app in Split View. Margins are asymmetric too.
- [ ] Nothing centered on the full display unless it's immersive, non-scrolling, and no interactive element can land under the bar.
- [ ] Corners use `ConcentricRectangle` / `UICornerConfiguration` (updated for Duo's screen shape).
- [ ] Tested with the app on both sides of Split View.

## E. Bars come from the system

- [ ] No hand-built `UIToolbar` / `UINavigationBar` / `UITabBar` carrying real actions.
  *Why:* Their contents aren't considered for the vertical bar.
  *Fix:* `.toolbar` inside `NavigationStack` / `NavigationSplitView` / `TabView`; `navigationItem` groups under `UINavigationController` / `UITabBarController`.
- [ ] No manual spacers between items (flexible spacers collapse to zero vertically anyway).

## F. Toolbar item content and order

- [ ] Order: Back/Close (`.cancellationAction`) → Done/Save (`.topBarPinnedTrailing` / `pinnedTrailingGroup`) → grouped items → tab bar.
- [ ] Every symbol item has a title (used in overflow/expanded forms).
- [ ] Text-only items minimized; text+symbol items reconsidered (does the text carry information, or just reinforce the symbol?).
- [ ] Counts use `.badge` / `item.badge`, not inline text.
- [ ] Symbol⇄text toggles use `.axisBehavior(.horizontalOnly)`; vertical-capable custom views use `.verticalPreferred` and read `toolbarVerticalEdge` / `verticalBarEdge`.
- [ ] Controls stay near the pane they act on (leading-pane controls stay above that pane).
- [ ] One overflow menu: `ToolbarOverflowMenu` / `additionalOverflowItems`. Ellipsis reserved for it; other menus have distinct symbols.
- [ ] Compression preference set per screen (`toolbarVerticalCompressionBehavior` / `verticalBarCompressionBehavior`): navigation-focused → toolbar compresses (default); task-focused → tab bar minimizes.
- [ ] `visibilityPriority` set (groups first, then items) so primary actions (Compose, New) and badged items survive longest.
- [ ] Vertical bar disabled (`toolbarVerticalBehavior(.disabled)` / `preferredVerticalBarBehavior`) only for single-page bottom-heavy layouts or single-button sheets.

## G. Two-pane layouts

- [ ] Hierarchy is the same on both displays (inner shows one more level, never a different structure).
- [ ] `NavigationSplitView` / `UISplitViewController` used for navigation hierarchy; they collapse when closed and avoid the fold when open.
- [ ] Custom `HStack`/`VStack` two-pane layouts considered for `ArrangementView(.split)`; `ZStack` overlays for `.overlay`.
- [ ] No navigation container inside an `ArrangementView`; no `ArrangementView` inside `List` / `ScrollView`.
- [ ] Tab bar promoted to sidebar on the inner display only where it fits (dense apps).

## H. Reserved regions and the fold

- [ ] System components used for anything that must avoid the fold (sheets, alerts, menus, popovers, toolbar buttons, split views).
- [ ] Manually positioned custom controls query `reservedRegions(kind: .division)` and move out of the fold; nothing important sits under the inner camera (`.occlusion`) when it may activate.
- [ ] Grids prefer even column counts; decided with `.includeInactive` so they don't reflow mid-fold.
- [ ] Displacement is minimal and purposeful: related elements move together; scrolling content doesn't displace; nothing disappears.
- [ ] Book pose → trailing region; laptop pose → glanceable content top, controls bottom.

## I. Poses and orientation

- [ ] Same functionality and control positions in every pose; an optional laptop-pose layout keeps the full control set and hierarchy.
- [ ] Landscape supported on the outer display (tent pose) where reasonable.
- [ ] Games: fill the screen in every pose; prefer aspect-ratio change to letterboxing; artwork in any unavoidable padding; text/control sizes stable during resize.

## J. Hinge

- [ ] Hinge API (`onHingeChange` / `UIHingeInteraction`) used only for interactions/effects, not layout.
- [ ] `context.hinge == nil` handled (non-folding devices); state reset in the non-`.partiallyOpen` branch.

## K. Scenes

- [ ] Split View multitasking works (no assumption of full-width).
- [ ] Multi-scene apps handle scene-request failure; `UIWindowSceneActivationAction` used for "new window" affordances (new windows are inner-display only).

## L. Build and test

- [ ] Built with the iOS 27.1 SDK (Xcode 27.1). Without it: no vertical bars, no edge-to-edge.
- [ ] Tested in Device Hub's iPhone Duo simulator: closed portrait, closed landscape, open flat portrait, open landscape, partially folded (book), Split View on both sides, PiP pinned.
- [ ] Apple's *App Resizability* skill (Xcode 27.1) run as a second opinion.
- [ ] Camera apps: Virtual Front Camera vs explicit inner/outer cameras + `AVCaptureDeviceDirectionCoordinator` decided; rotation coordinator adopted. (Out of scope here — see the *Build a great camera experience for iPhone Duo* tech talk.)
