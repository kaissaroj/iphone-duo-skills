# Raise the bar with iPhone Duo

## 2:24 - Use system containers for vertical bar in SwiftUI
```swift
var body: some View {
    NavigationStack {
        ContentView()
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    ...
                }
            }
    }
}
```

## 2:39 - Use navigation containers for vertical bar in UIKit
```swift
// Content from a custom bars (UINavigationBar, UITabBar, UIToolbar)
// won't be considered. Prefer UINavigationController 
// and UITabBarController, which manage their own bars.
let toolbar = UIToolbar()
toolbar.items = [...]
```

## 5:00 - Place a back or close button
```swift
// SwiftUI
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        ...
    }
}

// UIKit
navigationItem.leftItemsSupplementBackButton = false
navigationItem.leadingItemGroups
    = [UIBarButtonItemGroup(...)]
```

## 5:24 - Place prominent actions
```swift
// SwiftUI
.toolbar {
    ToolbarItem(placement: .topBarPinnedTrailing) {
        ...
    }
}

// UIKit
navigationItem.pinnedTrailingGroup
    = UIBarButtonItemGroup(...)
```

## 8:08 - Set a preferred axis for a custom view
```swift
// SwiftUI
var body: some View {
    ContentView()
        .toolbar {
            ToolbarItem {
                ProfileView()
            }
            .axisBehavior(.verticalPreferred)
        }
}

// UIKit
let item = UIBarButtonItem(customView: ProfileView())
item.axisBehavior = .verticalPreferred
```

## 8:36 - Keep an item in the horizontal bar
```swift
// SwiftUI
var body: some View {
    ContentView()
        .toolbar {
            ToolbarItem {
                SelectOrDoneButton()
            }
            .axisBehavior(.horizontalOnly)
        }
}

// UIKit
item.axisBehavior = .horizontalOnly
```

## 8:52 - Allow a custom view go in vertical bar
```swift
// SwiftUI
var body: some View {
    ContentView()
        .toolbar {
            ToolbarItem {
                CompassView()
            }
            .axisBehavior(.verticalPreferred)
        }
}

// UIKit
let item = UIBarButtonItem(customView: CompassView())
item.axisBehavior = .verticalPreferred
```

## 9:27 - Use badges
```swift
// SwiftUI
var body: some View {
    ContentView()
        .toolbar {
            ToolbarItem(...) {
                InboxButton()
                    .badge(7)
            }
        }
}

// UIKit
let item = UIBarButtonItem(...)
item.badge = .count(7)
```

## 10:36 - Read the vertical bar edge
```swift
// SwiftUI
struct ContentView: View {
    @Environment(\.toolbarVerticalEdge) var edge

    var body: some View {
        switch edge {
            ...
        }
    }
}

// UIKit
switch traitCollection.verticalBarEdge {
    ...
}
```

## 12:23 - Configure toolbar compression behavior
```swift
// SwiftUI
var body: some View {
    TabView {
        Tab("Recents", systemImage: "clock") {
            ContentView()
                .toolbarVerticalCompressionBehavior(.prefersToolbarItems)
        }
    }
}

// UIKit
navigationItem.verticalBarCompressionBehavior = .prefersBarItems
```

## 12:43 - Use system overflow menu
```swift
// SwiftUI
var body: some View {
    ContentView()
        .toolbar {
            ToolbarOverflowMenu {
                Button("Scan") { ... }
                Button("Connect") { ... }
            }
        }
}

// UIKit
navigationItem.additionalOverflowItems = UIDeferredMenuElement({ provider in
    provider(self.persistentOverflowItems())
})
```

## 13:21 - Set item visibility priority
```swift
// SwiftUI
var body: some View {
    ContentView()
        .toolbar {
            ToolbarItem {
                Button(...) { ... }
            }
            .visibilityPriority(.high)
        }
}

// UIKit
let item = UIBarButtonItem(...)
item.visibilityPriority = .high
```

## 14:47 - Disable the vertical bar
```swift
// SwiftUI
var body: some View {
    NavigationStack {
        ContentView()
            .toolbarVerticalBehavior(.disabled)
    }
}

// UIKit
class MyViewController: UIViewController {
    override var preferredVerticalBarBehavior: UIVerticalBarBehavior {
        .disabled
    }
}
```
