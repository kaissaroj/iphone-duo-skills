# Toolbar / vertical bar API reference

Verified 2026-09-12. **[DOC]** = published on developer.apple.com. **[TALK]** = appears verbatim in Apple's code samples for tech talk 111462 *Raise the bar with iPhone Duo* but not yet in the public documentation index; ships in the iOS 27.1 SDK. Anything not listed here is unverified — don't use it.

| Purpose | SwiftUI | UIKit | Status |
|---|---|---|---|
| Provide bars the system can relocate | `.toolbar { }` inside `NavigationStack` / `NavigationSplitView` / `TabView` | `UINavigationController`, `UITabBarController`; set `navigationItem.*` on the child VC | existing |
| Custom Back / Close | `ToolbarItem(placement: .cancellationAction)` | leading item + `navigationItem.leftItemsSupplementBackButton = false` (default) | existing |
| Prominent action (Done) | `ToolbarItem(placement: .topBarPinnedTrailing)` | `navigationItem.pinnedTrailingGroup = UIBarButtonItemGroup(…)` | [DOC] `topBarPinnedTrailing` iOS 27; `pinnedTrailingGroup` iOS 16 |
| Grouping | `ToolbarItemGroup` | `UIBarButtonItemGroup`; `navigationItem.leadingItemGroups` / `trailingItemGroups` | existing |
| Title + symbol on an item | `Label("Title", systemImage:)` | `UIBarButtonItem(title:image:…)` | existing |
| Axis preference | `ToolbarItem { }.axisBehavior(.verticalPreferred)` / `.axisBehavior(.horizontalOnly)` | `item.axisBehavior = .verticalPreferred` / `.horizontalOnly` | [TALK] |
| Badge | `.badge(7)` on toolbar content | `item.badge = .count(7)` | [DOC] iOS 26 |
| Detect vertical bar | `@Environment(\.toolbarVerticalEdge) var edge` — non-nil when items can be vertical | `traitCollection.verticalBarEdge` — unspecified when not | [TALK] |
| Compression preference | `.toolbarVerticalCompressionBehavior(.prefersToolbarItems)` | `navigationItem.verticalBarCompressionBehavior = .prefersBarItems` | [TALK] |
| System overflow menu | `ToolbarOverflowMenu { Button(…) … }` inside `.toolbar` | `navigationItem.additionalOverflowItems = UIDeferredMenuElement { provider in provider(items) }` | [DOC] iOS 27 |
| Visibility priority | `.visibilityPriority(.high)`; `ToolbarItemVisibilityPriority.high / .low / .automatic`, `init(higherThan:)`, `init(lowerThan:)` | `item.visibilityPriority = .high`; `UIBarButtonItemVisibilityPriority.high / .low / .standard`, `init(higherThan:)`, `init(lowerThan:)` | [DOC] iOS 27 |
| Disable vertical bar | `.toolbarVerticalBehavior(.disabled)` on `NavigationStack` content | `override var preferredVerticalBarBehavior: UIVerticalBarBehavior { .disabled }` | [TALK] |
| Tab bar as sidebar on inner display | `TabView { }.defaultTabBarPlacement(.sidebar)` | `tabBarController.sidebar.preferredPlacement = .sidebar` | existing (iOS 18) |

Documented pages:
- https://developer.apple.com/documentation/swiftui/toolbaritemvisibilitypriority
- https://developer.apple.com/documentation/swiftui/toolbaroverflowmenu
- https://developer.apple.com/documentation/swiftui/toolbaritemplacement/topbarpinnedtrailing
- https://developer.apple.com/documentation/uikit/uibarbuttonitemvisibilitypriority
- https://developer.apple.com/documentation/uikit/uinavigationitem/additionaloverflowitems
- https://developer.apple.com/documentation/uikit/uinavigationitem/pinnedtrailinggroup

## Behavior facts (from the talk narration)

- Vertical bars appear on the outer display in all orientations and the inner display in landscape; inner-display portrait keeps horizontal bars.
- Items with an icon move vertical; text-only items stay horizontal; custom views stay horizontal unless `.verticalPreferred`.
- Split views: only the detail column participates; inspectors get no bar of their own.
- Sheets: vertical bar on the outer display; centered + horizontal on the inner display; with `preferredPlacement`, right-placed sheets get a vertical bar and left-placed don't.
- The bar is on the same physical side in RTL. In Split View multitasking each app's bar is on its outer edge.
- Vertical bar: fixed width, flexible height. Flexible spacers are zero-size; fixed spacers keep their minimum.
- No scroll-edge effect; background appears under Reduce Transparency.
- Items overflow bottom → top by default. Toolbar compresses before tab bar by default.
- Keyboard accessory bars stay attached to the keyboard.
- Apps must be built with the iOS 27.1 SDK to get vertical bars and edge-to-edge layout.
