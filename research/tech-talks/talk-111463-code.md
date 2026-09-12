# Strike a pose with adaptive layouts on iPhone Duo

## 6:46 - Query reserved regions in SwiftUI
```swift
// SwiftUI
GeometryReader { proxy in
  let regions = proxy.reservedRegions(
    kind: .division)
}
```

## 7:03 - Query reserved regions in UIKit
```swift
// UIKit
let regions = view.reservedRegions(
  kind: .division)

// Query the frame to incorporate it into your own layout
let frames = regions.map(\.frame)
```

## 7:22 - Include inactive regions
```swift
// SwiftUI
GeometryReader { proxy in
  let regions = proxy.reservedRegions(
    kind: .division, options: .includeInactive)

  let frames = regions.map(\.frame)
  // ...
}
```

## 8:07 - Query occlusion regions
```swift
// SwiftUI
GeometryReader { proxy in
  let regions = proxy.reservedRegions(
    kind: .occlusion)

  let frames = regions.map(\.frame)
  // ...
}
```

## 11:23 - Add an ArrangementView
```swift
// SwiftUI
var body: some View {
  NavigationStack {
    ArrangementView {
      PlayerView()
    } secondary: {
      UpNextView()
    }
  }
}
```

## 11:26 - Add a UIArrangementViewController
```swift
// UIKit
let arrangementVC = UIArrangementViewController()
let navController = UINavigationController(rootViewController: arrangementVC)

let playerVC = PlayerViewController()
arrangementVC.setViewController(playerVC, for: .primary)

let upNextVC = UpNextViewController()
arrangementVC.setViewController(upNextVC, for: .secondary)
```

## 12:00 - Specify the split arrangement style
```swift
// SwiftUI
var body: some View {
  NavigationStack {
    ArrangementView {
      PlayerView()
    } secondary: {
      UpNextView()
    }
    .arrangementViewStyle(.split)
  }
}
```

## 12:41 - Restrict the split to one axis
```swift
// SwiftUI
var body: some View {
  NavigationStack {
    ArrangementView {
      PlayerView()
    } secondary: {
      UpNextView()
    }
    .arrangementViewStyle(
      .split.axes(.horizontal))
  }
}
```

## 13:07 - Update the arrangement in UIKit
```swift
// UIKit
let arrangementVC = UIArrangementViewController()

// ...

arrangementVC.updateArrangement(.split.axes(.horizontal))
```

## 13:26 - Switch to the overlay arrangement
```swift
// SwiftUI
var body: some View {
  NavigationStack {
    ArrangementView {
      UpNextView()
    } secondary: {
      PlayerView()
    }
    .arrangementViewStyle(.overlay)
  }
}
```

## 14:07 - Respond to the overlay Z index
```swift
// SwiftUI
enum UpNextMinimization {
  case collapsed; case expanded
}

struct UpNextView: View {
  @Environment(\.overlayArrangementZIndex)
  private var zIndex: Int

  var body: some View {
    UpNextList(minimization: minimization)
  }

  var minimization: UpNextMinimization {
    zIndex > 0 ? .collapsed : .expanded
  }
}
```

## 14:21 - Read the Z index in UIKit
```swift
// UIKit
let arrangementVC = UIArrangementViewController()

// ...

let primaryState = arrangementVC.state(for: .primary)
myModel.minimization = (primaryState?.zIndex ?? 0) > 0
  ? .collapsed : .expanded
```
