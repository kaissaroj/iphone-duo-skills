# Duo inspection — `G` (Grid.swift)   (mode C — source, pose: static analysis, all poses)

Scanned with `iphone-duo-audit/scripts/duo_audit.sh` (4 hits on this file, all confirmed on read) and then read as a layout. No screenshot was supplied, so there is no annotated image; every finding below points at a line.

| # | Severity | Rule | Element | Problem | Fix |
|---|---|---|---|---|---|
| 1 | blocking | G1 | `ArrangementView { NavigationSplitView … }` (line 6) | Navigation container *inside* an arrangement view. `ArrangementView` provides no navigation infrastructure; nesting `NavigationSplitView` in it (and both inside a `NavigationStack`) gives a different structure inner vs. outer and breaks the split view's own collapse / fold avoidance. | Navigation on the outside, arrangement on the inside: `NavigationSplitView` at the root, `ArrangementView` in the detail column. |
| 2 | blocking | C (fixed metrics) / D4 | `.frame(width: 390)` (line 8) | Hard-coded outer-display width. On the inner display the view sits at 390 pt centered in the full width — it straddles the fold when folded and is off-center against the vertical bar. In Split View / PiP it doesn't shrink. | Delete the modifier; let the container fill the safe area. |
| 3 | should-fix | H4 | `columns` — 3 × `GridItem(.flexible())` (line 3) | Odd column count puts the middle column on the hinge when the device is partially folded. | Even count whenever a division region exists, decided with `.includeInactive` so it doesn't reflow mid-fold. |
| 4 | should-fix | F3 | `ToolbarItem { Image(systemName: "gear") }` (line 9) | Symbol-only item with no title. In the vertical bar's overflow / expanded form the item has no name; also not a button, so it's not tappable. | `Button { … } label: { Label("Settings", systemImage: "gear") }`. |

## Fixes

Minimal diff, in the file's own style. `columns` is declared but never used in the body; the fix for #3 assumes it feeds a `LazyVGrid` (shown so the even-count logic has somewhere to live — drop the grid if you don't need it yet).

### 1. G1 — move navigation outside the arrangement

```swift
// before
NavigationStack {
    ArrangementView { NavigationSplitView { Text("a") } detail: { Text("b") } } secondary: { Text("c") }
}

// after — the split view is the navigation hierarchy (collapses when closed, avoids the fold when open);
// the arrangement only pairs the two non-navigating panes inside the detail column
NavigationSplitView {
    Text("a")
} detail: {
    ArrangementView { Text("b") } secondary: { Text("c") }
        .arrangementViewStyle(.split)
}
```

If `a` was never meant to be a sidebar, the simpler form is just `NavigationStack { ArrangementView { Text("a") } secondary: { Text("b") } }` — either way, no `Navigation…` inside `ArrangementView`.

### 2. Fixed width — remove `.frame(width: 390)`

```swift
// before
        }
        .frame(width: 390)
        .toolbar { … }

// after
        }
        .toolbar { … }
```

Nothing replaces it. If you need the outer-display width as a *maximum* for readability, use `.frame(maxWidth: …)` plus `.frame(maxWidth: .infinity)` on the container so the view still centers inside the safe area, not the full display — but for this screen the container should simply fill.

### 3. H4 — even column count from the division region

```swift
// before
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

// after — 3 columns on a single flat display; 4 whenever a fold exists (active or not),
// so the grid doesn't reflow every time the hinge crosses the threshold
    private func columns(for proxy: GeometryProxy) -> [GridItem] {
        let hasFold = !proxy.reservedRegions(kind: .division, options: .includeInactive).isEmpty
        return Array(repeating: GridItem(.flexible()), count: hasFold ? 4 : 3)
    }
    // … in body, where the grid lives:
    GeometryReader { proxy in
        ScrollView {
            LazyVGrid(columns: columns(for: proxy)) { /* cells */ }
        }
    }
```

If the grid should be 2-up on the outer display and 4-up on the inner one, branch on `horizontalSizeClass` (compact → 2, regular → 4) — never on `UIScreen`, orientation, or idiom.

### 4. F3 — title on the toolbar item

```swift
// before
        .toolbar { ToolbarItem { Image(systemName: "gear") } }

// after
        .toolbar {
            ToolbarItem {
                Button { /* open settings */ } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
```

The system shows the symbol in the vertical bar and the title in overflow / expanded forms. Keep it a `Button` (or `NavigationLink`) so the item is actually interactive.

## Resulting file (all four applied)

```swift
import SwiftUI
struct G: View {
    private func columns(for proxy: GeometryProxy) -> [GridItem] {
        let hasFold = !proxy.reservedRegions(kind: .division, options: .includeInactive).isEmpty
        return Array(repeating: GridItem(.flexible()), count: hasFold ? 4 : 3)
    }
    var body: some View {
        NavigationSplitView {
            Text("a")
        } detail: {
            ArrangementView { Text("b") } secondary: { Text("c") }
                .arrangementViewStyle(.split)
        }
        .toolbar {
            ToolbarItem {
                Button { /* open settings */ } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
    }
}
```

## Not checked

- No screenshot or running simulator, so H2 (what actually sits on the hinge), D1 (content under the bar), H5 (laptop pose) and I1 (parity across poses) could not be measured — only inferred from the fixed width and odd column count.
- `columns` is unused in the current body; the H4 fix is only meaningful once a `LazyVGrid` consumes it.
- `reservedRegions(kind:options:)`, `ArrangementView`, `.arrangementViewStyle(.split)` are iOS 27.1 SDK names from Apple's Duo samples; build against the 27.1 SDK to confirm signatures.
