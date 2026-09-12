# Notes: MessageListViewController+Toolbar.swift

Choices, mapped to the iPhone Duo vertical-bar guidance (iOS 27.1 SDK).

## Use the system's bars, not a custom UIToolbar
All items are set on `navigationItem` and `toolbarItems`; the enclosing
`UINavigationController` / `UITabBarController` own the bars. Only system-managed
items are relocated to the vertical strip.

## Order in the strip
Top to bottom: Back (automatic) → Select/Done (`pinnedTrailingGroup`, the screen's
prominent action) → bottom-bar items (Filter, Inbox, Compose) → tab bar. The bottom
toolbar keeps Mail's Filter / status / Compose order; the flexible spaces are
zero-size in a vertical bar, so they only matter for the horizontal layout and no
manual spacing is added.

## Symbol + title on every item
Compose, Filter and Inbox all get `title` *and* `image`, which makes them eligible
for the vertical bar and gives the overflow menu a label to show.

## "Inbox (12)" becomes a badge
A text-only button would be pinned to the horizontal bar. The count only reinforces
the symbol, so it is now `tray` + `badge = .count(n)`; the count is also exposed as
`accessibilityValue`. Badged status items are given `.high` priority so they stay
visible longer than Filter.

## Select ⇄ Done stays horizontal
It is a custom text toggle, so `axisBehavior = .horizontalOnly` — related items
must not change axis between poses. It also has `.high` visibility priority so Done
never disappears mid-selection. While selecting, Compose and Filter are hidden
because they don't act on the selection.

## One overflow menu, no custom ellipsis
Archive All / Mark All as Read / Settings are provided through
`navigationItem.additionalOverflowItems` (a `UIDeferredMenuElement`) instead of a
"More" ellipsis button. The ellipsis is reserved for the system overflow on iPhone,
and folding our actions in means everything that gets compressed off the bar ends
up in the same menu.

## Priorities
- Compose: `UIBarButtonItemVisibilityPriority(higherThan: .high)` — most important, overflows last.
- Inbox, Select/Done: `.high`.
- Filter: `.low` — first into the overflow menu.

## Compression
Default left as-is (toolbar compresses before the tab bar) because this is a
navigation-focused screen inside a tab bar controller; Compose survives via its
priority. `verticalBarCompressionBehavior = .prefersBarItems` is noted in code as
the switch if actions should win over tabs.

## Not done
- No `preferredVerticalBarBehavior = .disabled` — a list screen is exactly the case
  the vertical bar is for.
- Availability: written against a 27.1 deployment target, so no `#available`
  guards. Add them around `axisBehavior`, `visibilityPriority`,
  `additionalOverflowItems` (iOS 27) and `badge` (iOS 26) if the target is lower.
- The extension assumes a small contract on the main class (state properties and
  action methods), listed at the top of the file.
