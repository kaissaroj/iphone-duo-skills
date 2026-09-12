# Notes: MessageListViewController+Toolbar.swift

## Choices

- **Compose is a system item (`.compose`) with `.prominent` style** and is placed at the reachable end of the bottom bar. It is never spaced with a flexible spacer on vertical bars so it stays adjacent to the other actions rather than being pushed to a far corner. It is disabled (not hidden) while selecting so the layout doesn't jump.
- **Every item is an SF Symbol, not text.** Text buttons ("Inbox (12)", "Filter") are the first thing to truncate or wrap on a narrow vertical rail. Symbols stack cleanly in either orientation.
- **Inbox count is a badge, not a text button.** The tray symbol gets a small red numeric pill rendered into the image, and the full "Inbox, 12 unread" string is exposed via `accessibilityLabel` / `accessibilityValue`. Counts over 99 show "99+".
- **Select ↔ Done is a single `UIBarButtonItem`** whose image/title/style are swapped by `updateSelectState()`. Keeping one item avoids re-creating the nav bar items and losing its position during the transition.
- **More menu uses `UIDeferredMenuElement.uncached`** so the archive label ("Archive All" vs "Archive Selected") and the disabled state of "Mark All as Read" are computed at the moment the menu opens. Settings is separated into its own inline group.
- **Layout is trait-driven.** `registerForTraitChanges` re-runs `applyToolbarLayout()` on size-class or layout-direction changes, so switching iPhone Duo between horizontal and vertical bars re-distributes the items without a view reload.
- **Vertical vs horizontal detection** is a heuristic in `UITraitCollection.usesVerticalBars`. If the iOS 27.1 SDK exposes a dedicated trait for bar orientation, replace that computed property with it — it is the only place that needs to change.
- **Host contract** is expressed as `MessageListToolbarActions` so this extension compiles independently; the real `MessageListViewController` conforms to it. Item references are kept in an associated `MessageListToolbarStore` because extensions cannot add stored properties.

## Integration

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    configureToolbarItems()
}

// whenever unread count / filter / selection changes:
refreshToolbarState()
```
