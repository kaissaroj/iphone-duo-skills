# iPhone Duo — Verified API Reference

Every symbol below was confirmed from one of two sources on 2026-09-12:

- **[DOC]** — has a published page on developer.apple.com (checked via the `/tutorials/data/documentation/*.json` API).
- **[TALK]** — appears verbatim in Apple's own code samples on a tech talk page (`research/tech-talks/talk-*-code.md`). Not yet in the public doc index as of today; ships in the **iOS 27.1 SDK / Xcode 27.1**.

Nothing here is inferred. If a symbol isn't in this file, do not use it in a skill.

## Platform facts (from "Prepare your app for iPhone Duo", 111461)

| Fact | Source |
|---|---|
| Apps built without iOS 27 SDK still run; on outer display they get the space left of the status bar/camera; on inner display, a familiar size/aspect. | 111461 |
| Built with iOS 27 SDK: app extends left of the status bar on inner display. | 111461 |
| Built with **iOS 27.1 SDK**: app extends to screen edge; standard bars lay out vertically under the status bar. | 111461 |
| Simulator: **Xcode 27.1** → Device Hub → iPhone Duo; controls at bottom to open / close / rotate / fold. Split View: drag app by home indicator to a side. | 111461 |
| Outer display size classes: portrait = compact W / regular H; landscape = compact W / compact H (like other iPhones). | 111461 |
| Inner display size classes: **regular W / regular H**. | 111461 |
| Inner display **does not honor supported interface orientations**; `UIRequiresFullScreen` honored but app still resizes on open/close; app scales on inner display incl. Split View. | 111461 |
| `UIScreen.main` is ambiguous on a two-display device and "will be deprecated in a future release". | 111461 |
| All apps participate in Split View multitasking (50/50). New windows/scenes can be created only on the inner display. | 111464, 111466 |
| Vertical bars: on outer display (all orientations) and inner display in landscape. Inner display portrait keeps horizontal bars. | 111462, 111466 |
| In split views only the detail column gets a vertical bar; inspectors don't. Sheets: vertical bar on outer display; centered w/ horizontal bars on inner. With `preferredPlacement`, right-placed sheets get a vertical bar, left-placed don't. | 111462 |
| Vertical bar stays on the same physical side in RTL languages. | 111462, HIG |
| Vertical bar: fixed width, flexible height. Flexible spacers are zero-size vertically; fixed spacers keep min size. No scroll-edge effect; gets a background under Reduce Transparency. | 111462 |
| Items overflow bottom-to-top by default. Default compression: toolbar compresses before tab bar. | 111462, HIG |
| Xcode 27.1 ships an **"App Resizability"** skill (renamed from the WWDC26 app-modernization skill) supporting SwiftUI + iPhone Duo. | 111461 |

## Size classes & screen

| SwiftUI | UIKit | Status |
|---|---|---|
| `@Environment(\.horizontalSizeClass)`, `@Environment(\.verticalSizeClass)` | `traitCollection.horizontalSizeClass` / `.verticalSizeClass` | [DOC] existing |
| — | `window?.windowScene?.screen` (instead of `UIScreen.main`) | [TALK 111461] |
| — | `traitCollection.displayScale` (instead of `UIScreen.main.scale`) | [DOC] existing |
| `ConcentricRectangle()` | `UICornerConfiguration` | [DOC] iOS 26, "updated for Duo screen shapes" |
| `TabView { }.defaultTabBarPlacement(.sidebar)` | `tabBarController.sidebar.preferredPlacement = .sidebar` | [DOC] existing (iOS 18) |
| `.ignoresSafeArea()` for backgrounds | `view.bounds` for background, `view.bounds.inset(by: view.safeAreaInsets)` for foreground | [DOC] existing |

## Reserved regions (iOS 27.1) — "Strike a pose", 111463

| SwiftUI | UIKit | Status |
|---|---|---|
| `proxy.reservedRegions(kind: .division)` on `GeometryProxy` (from `GeometryReader` or `onGeometryChange`) | `view.reservedRegions(kind: .division)` on `UIView` | [TALK] |
| `proxy.reservedRegions(kind: .division, options: .includeInactive)` | (same `options:` presumably; only SwiftUI shown) | [TALK] |
| `proxy.reservedRegions(kind: .occlusion)` | — | [TALK] |
| `regions.map(\.frame)` — each region has a `frame` | same | [TALK] |
| Type named `ReservedRegion` | Type named `UIViewReservedRegion` | [TALK 111461 narration] |

Semantics (from narration):
- **Division** region = the fold. Active only when partially folded; when flat it is inactive with **width zero**.
- **Occlusion** region = the inner front camera. Active only while the camera is active.
- Default query returns active regions only; `.includeInactive` returns both — use inactive regions for high-level decisions (e.g. prefer even column counts whenever a division region exists at all).
- Outer camera is a reserved region too but the system handles it automatically when bars are vertical (HIG).

## Arrangement views (iOS 27.1) — "Strike a pose", 111463

| SwiftUI | UIKit | Status |
|---|---|---|
| `ArrangementView { Primary() } secondary: { Secondary() }` | `UIArrangementViewController()`; `.setViewController(vc, for: .primary)` / `.secondary` | [TALK] |
| `.arrangementViewStyle(.split)` (default) | `arrangementVC.updateArrangement(.split)` | [TALK] |
| `.arrangementViewStyle(.split.axes(.horizontal))` | `arrangementVC.updateArrangement(.split.axes(.horizontal))` — type `UISplitArrangement` | [TALK] |
| `.arrangementViewStyle(.overlay)` | (overlay type not shown in samples) | [TALK] |
| `@Environment(\.overlayArrangementZIndex) var zIndex: Int` | `arrangementVC.state(for: .primary)?.zIndex` | [TALK] |

Semantics:
- **Split**: divides bounds between primary/secondary. Splits horizontally when wider than tall, vertically when taller than wide. If restricted `axes` can't satisfy the primary axis, only the primary view is shown.
- **Overlay**: layers primary over secondary; when partially folded, moves them side-by-side. `overlayArrangementZIndex > 0` ⇒ view is stacked on top (use to collapse); `0` ⇒ side-by-side (expand).
- Choose split for main–detail (neither may be obscured); overlay for foreground/background (background may be partly covered, e.g. scrollable content under controls).
- `HStack`/`VStack` layouts → split; `ZStack` → overlay.
- **Do not** put navigation containers (`NavigationSplitView`, etc.) *inside* an `ArrangementView`; wrap the arrangement in them instead.
- **Do not** put an `ArrangementView` inside `List` / `ScrollView`.

## Vertical bars & toolbars — "Raise the bar", 111462

| SwiftUI | UIKit | Status |
|---|---|---|
| Use `.toolbar { }` with `NavigationStack` / `NavigationSplitView` / `TabView` | Use `UINavigationController` / `UITabBarController`; custom `UIToolbar` / `UINavigationBar` / `UITabBar` content is **not** considered | [TALK] |
| `ToolbarItem(placement: .cancellationAction)` for custom Back/Close | leading item + `navigationItem.leftItemsSupplementBackButton = false` (default) | [DOC] existing |
| `ToolbarItem(placement: .topBarPinnedTrailing)` for prominent actions (Done) | `navigationItem.pinnedTrailingGroup = UIBarButtonItemGroup(...)` | [DOC] `topBarPinnedTrailing` iOS 27; `pinnedTrailingGroup` iOS 16 |
| `ToolbarItem { ... }.axisBehavior(.verticalPreferred)` / `.horizontalOnly` | `item.axisBehavior = .verticalPreferred` / `.horizontalOnly` | [TALK] |
| `.badge(7)` on toolbar content | `item.badge = .count(7)` | [DOC] iOS 26 |
| `@Environment(\.toolbarVerticalEdge) var edge` — populated when items can be vertical, `nil` otherwise | `traitCollection.verticalBarEdge` — "unspecified" when not vertical | [TALK] |
| `.toolbarVerticalCompressionBehavior(.prefersToolbarItems)` | `navigationItem.verticalBarCompressionBehavior = .prefersBarItems` | [TALK] |
| `ToolbarOverflowMenu { Button(...) }` in `.toolbar` | `navigationItem.additionalOverflowItems = UIDeferredMenuElement { provider in provider(items) }` | [DOC] iOS 27 |
| `ToolbarItem { }.visibilityPriority(.high)` / `.low` / `ToolbarItemVisibilityPriority(higherThan:)` / `(lowerThan:)` | `item.visibilityPriority = .high` / `.low` / `.standard` / `UIBarButtonItemVisibilityPriority(higherThan:)` | [DOC] iOS 27 |
| `.toolbarVerticalBehavior(.disabled)` on `NavigationStack` content | `override var preferredVerticalBarBehavior: UIVerticalBarBehavior { .disabled }` | [TALK] |
| `ToolbarItemGroup` | `UIBarButtonItemGroup` | [DOC] existing |
| `Label("Title", systemImage:)` on every item | `UIBarButtonItem` with both `title` and `image` | [DOC] existing |

Behavior rules (narration):
- Items with an icon go vertical; text-only items stay horizontal. Custom views (UIKit `customView`, complex SwiftUI views) stay horizontal unless `.verticalPreferred`.
- Items that swap between symbol and text (custom Select/Done) → `.horizontalOnly`. System Edit button already handles this.
- Text carrying real information (e.g. "$42 cart") → keep horizontal. Text merely reinforcing a symbol → drop it, use symbol + badge.
- Keyboard accessory bars never go vertical.
- Reserve the ellipsis symbol for the system overflow menu only.

## Hinge — "Leverage multiple displays", 111464

| SwiftUI | UIKit | Status |
|---|---|---|
| `.onHingeChange { previous, context in }` | `UIHingeInteraction` | [TALK] (UIKit name from narration only) |
| `context.hinge` is `nil` on devices without a hinge | | [TALK] |
| `hinge.status` — `.closed`, `.partiallyOpen`, `.fullyOpen` | | [TALK] `.partiallyOpen` in code; others from narration |
| `hinge.angle: Angle` — continuous | | [TALK] |

Use hinge for interactions/effects only; use arrangement + reserved-region APIs for layout.

## Scenes & accessories — 111464

| Symbol | Status |
|---|---|
| `UIWindowSceneActivationAction` — auto-hides when new windows unavailable (outer display) | [DOC] existing |
| `.sceneAccessory { CameraCaptureAccessory(isEnabled:) { View } }` | [TALK] |
| `CameraCaptureAccessory { }.onAvailabilityChange { Bool in }` | [TALK] |
| Accessory available only when app is full screen on inner display with active camera session; register on the same view as camera UI. | narration |

## Camera — "Build a great camera experience", 111465

| Symbol | Status |
|---|---|
| Virtual Front Camera — returned by `AVCaptureDeviceDiscoverySession` for `.front` + wide/ultrawide; auto-switches inner/outer. Caps at common features (1080p60, no depth). | narration |
| `.builtInOuterUltraWideCamera`, `.builtInInnerUltraWideCamera` device types | [TALK] |
| `AVCaptureDeviceDirectionCoordinator(view:deviceTypes:changeHandler:)` (AVKit); handler receives a map of `AVCaptureDeviceDescriptor` (main-actor-safe, Sendable) | [TALK] |
| One coordinator per view when using both displays | narration |
| `AVCaptureVideoPreviewLayer.videoGravity`, `AVCaptureDevice.dynamicAspectRatio` | [DOC] existing |
| `AVCapturePhotoOutput.isCameraSensorOrientationCompensationEnabled = false` after adopting the rotation coordinator | [TALK] |
| Outer UW: up to 4K120; inner UW: 1080p60. | narration |

## Sources

- HIG: https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo (published 2026-09-09)
- 111461 Prepare your app for iPhone Duo — https://developer.apple.com/videos/play/tech-talks/111461
- 111462 Raise the bar with iPhone Duo — https://developer.apple.com/videos/play/tech-talks/111462
- 111463 Strike a pose with adaptive layouts on iPhone Duo — https://developer.apple.com/videos/play/tech-talks/111463
- 111464 Leverage multiple displays and scenes on iPhone Duo — https://developer.apple.com/videos/play/tech-talks/111464
- 111465 Build a great camera experience for iPhone Duo — https://developer.apple.com/videos/play/tech-talks/111465
- 111466 Design for iPhone Duo — https://developer.apple.com/videos/play/tech-talks/111466
