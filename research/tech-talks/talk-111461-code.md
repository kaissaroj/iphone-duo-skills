# Prepare your app for iPhone Duo

## 2:59 - Read size classes
```swift
// SwiftUI
@Environment(\.horizontalSizeClass)
private var horizontalSizeClass

@Environment(\.verticalSizeClass)
private var verticalSizeClass

// UIKit
traitCollection.horizontalSizeClass
traitCollection.verticalSizeClass
```

## 4:16 - Access the screen from the window scene
```swift
// Avoid referencing the main screen on a two-display device.
// Access the screen dynamically from the window scene instead.
let screen = window?.windowScene?.screen
```

## 4:30 - Match the screen corners with Concentricity
```swift
// SwiftUI
ConcentricRectangle()
    .fill(Color.green)
    .padding(8.0)
    .ignoresSafeArea()

// UIKit
// UICornerConfiguration
```

## 5:44 - Show a sidebar on the inner display
```swift
// SwiftUI
TabView { … }
    .defaultTabBarPlacement(.sidebar)

// UIKit
tabBarController.sidebar.preferredPlacement = .sidebar
```

## 6:52 - Align foreground content to the safe area
```swift
// UIKit
foreground.frame = view.bounds.inset(by: view.safeAreaInsets)
```

## 7:07 - Let background content extend past the safe area
```swift
// SwiftUI
.ignoresSafeArea()

// UIKit
backgroundView.frame = view.bounds
```

## 7:30 - Handle asymmetric safe area insets
```swift
// Avoid assuming insets on opposite sides are equal
let width = view.bounds.width - view.safeAreaInsets.left * 2

// Handle each side independently
let width = view.bounds.inset(by: view.safeAreaInsets).width
```

## 9:25 - Replace main screen references
```swift
func updateThumbnail(from image: UIImage) {
    // Before
    let screenScale = UIScreen.main.scale

    // After
    let screenScale = traitCollection.displayScale
    // ...
}
```
