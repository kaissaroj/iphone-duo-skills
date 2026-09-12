# Arrangement views

Source: HIG "Designing for iPhone Duo" → *Arrangement views*; tech talk 111463 *Strike a pose with adaptive layouts on iPhone Duo*. API names verbatim from Apple's samples. iOS 27.1 SDK.

## What an arrangement is

Apple's framing: a layout container sits *between* navigation containers (`NavigationStack`, `NavigationSplitView`, `TabView`) and content containers (`List`, `ScrollView`). It arranges **two views** — primary and secondary — according to a set of rules.

An *arrangement* is a function from inputs → outputs:

- Inputs: horizontal and vertical size class, the view's aspect ratio (width / height), whether any division regions are active.
- Outputs: whether to show each view at all, and each view's frame.

In iOS 27.1 you get system-provided arrangements instead of writing that function yourself. The worked example is Podcasts' Now Playing + transcript: side-by-side when wide, transcript inline when tall, and the Now Playing view stays constrained to the left region when folded rather than re-centering under the hinge.

## API

### SwiftUI

```swift
NavigationStack {
    ArrangementView {
        PlayerView()          // primary
    } secondary: {
        UpNextView()          // secondary
    }
    .arrangementViewStyle(.split)                      // default
    // .arrangementViewStyle(.split.axes(.horizontal)) // restrict
    // .arrangementViewStyle(.overlay)
}
```

### UIKit

```swift
let arrangementVC = UIArrangementViewController()
let navController = UINavigationController(rootViewController: arrangementVC)

arrangementVC.setViewController(PlayerViewController(), for: .primary)
arrangementVC.setViewController(UpNextViewController(), for: .secondary)

arrangementVC.updateArrangement(.split.axes(.horizontal))   // UISplitArrangement
```

## Split arrangement

- Divides its bounds between primary and secondary.
- Splits **horizontally when wider than tall**, **vertically when taller than wide** (iPad landscape, iPhone Duo open flat → horizontal; rotate to portrait → vertical).
- `.axes(.horizontal)` (or `.vertical`) restricts which axes it may use. If the arrangement's *primary* axis (from aspect ratio) isn't allowed, it **shows only the primary view**. E.g. axes = horizontal, view is taller than wide → only `PlayerView` appears.
- Adapts to the fold automatically.

## Overlay arrangement

- Prefers positioning primary **on top of** secondary (above/below in z).
- When the display is **partially folded**, moves primary and secondary **side by side** into the two regions instead.
- The HIG notes you can collapse the secondary view when you don't want it to appear.

Respond to which mode you're in via the z-index:

```swift
// SwiftUI — read inside the primary or secondary view
struct UpNextView: View {
    @Environment(\.overlayArrangementZIndex) private var zIndex: Int

    var body: some View {
        UpNextList(minimization: zIndex > 0 ? .collapsed : .expanded)
    }
}

// UIKit
let primaryState = arrangementVC.state(for: .primary)
myModel.minimization = (primaryState?.zIndex ?? 0) > 0 ? .collapsed : .expanded
```

`zIndex > 0` means the view is stacked on top of the other (overlay mode) — show a compact version. `0` means it has its own region (folded, side-by-side) — expand to use the room.

## Choosing

1. **Follow the pattern you already have.** An `HStack`/`VStack` two-pane layout → `.split`. A `ZStack` layered layout → `.overlay`. These translate directly and gain fold support for free.
2. **No existing pattern?** Ask about the relationship:
   - Clear **foreground/background** and it's fine if the background is partly obscured (Accessibility Reader: controls over scrollable readable text) → `.overlay`.
   - **Main/detail** where neither may ever be hidden (Podcasts: episode + transcript; an audio-notes player + up-next list) → `.split`.
3. **When *not* to use one:**
   - It provides **no navigation infrastructure**. Never put `NavigationSplitView`, `NavigationStack` or `TabView` *inside* it. Put them *around* it.
   - Don't put an `ArrangementView` **inside a `List` or `ScrollView`** — the scrolling container fights the arrangement's sizing.
   - If you need columns that expand/collapse with navigation state (sidebar, supplementary, detail), that's `NavigationSplitView`, not an arrangement.

## Audit hint

Apple's suggested starting point: "audit your app's centered layouts. Consider whether you can make it a two-column layout, or what displacement pattern makes sense." A single view centered on the full inner display is the most common thing that ends up straddling the fold.
