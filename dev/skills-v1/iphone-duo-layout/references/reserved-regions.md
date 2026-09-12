# Reserved regions

Source: HIG "Designing for iPhone Duo" → *Reserved regions*; tech talk 111463 *Strike a pose with adaptive layouts on iPhone Duo*; tech talk 111461 *Prepare your app for iPhone Duo*. API names are taken verbatim from Apple's code samples. Requires the iOS 27.1 SDK.

## Concept

A reserved region is an area of the display that content avoids covering, or that components adapt to. Treat them like the window controls on iPadOS: part of the environment your layout already adapts to. The type is `ReservedRegion` in SwiftUI and `UIViewReservedRegion` in UIKit.

There are two **kinds**:

- **Division** — divides a larger area into multiple smaller areas. On iPhone Duo the **fold** is a division region. It is *active* only when the device is partially folded; when flat it is *inactive* and has **zero width**.
- **Occlusion** — a smaller frame inside your view's bounds that occludes content. On iPhone Duo the **inner front camera** is an occlusion region. Active while the camera is in use, inactive otherwise (the camera is invisible under the display when inactive).

The outer front camera is also a reserved region, but when bars are vertical the system positions everything around it, so you rarely query it.

## API

### SwiftUI

Query from a `GeometryProxy` — either inside `GeometryReader` or via `onGeometryChange`:

```swift
GeometryReader { proxy in
    let regions = proxy.reservedRegions(kind: .division)
    let frames  = regions.map(\.frame)      // CGRect per region, in the proxy's coordinate space
    // …
}
```

Options:

```swift
proxy.reservedRegions(kind: .division, options: .includeInactive)
proxy.reservedRegions(kind: .occlusion)
```

By default only *active* regions are returned. `.includeInactive` returns inactive ones too.

### UIKit

```swift
let regions = view.reservedRegions(kind: .division)
let frames  = regions.map(\.frame)
```

(The SwiftUI sample shows `options:`; the UIKit sample only shows `kind:`. Assume the same option exists but confirm against the SDK before relying on it.)

## Using active vs inactive

- **Active** regions drive frame-level layout: shift a control out of `frame`, widen a gutter, pick which region a floating element lives in.
- **Inactive** regions drive *structural* decisions that shouldn't flip as the user folds. Apple's example: prefer an even number of grid columns whenever a division region exists at all, regardless of active state. If you only looked at active regions, the grid would reflow every time the hinge crossed the threshold.

## What the system already handles

You get fold avoidance for free from: sheets, alerts, action sheets, context menus, popovers, menus, toolbar buttons, `NavigationSplitView` / `UISplitViewController` (columns go to an even 50/50 split and adjust margins), `List`, `ScrollView`, `TabView`, `NavigationStack`. Apple's phrasing: "Use these components whenever possible to get the same fold avoidance behavior in your app."

The API is for the remainder — Apple's guidance is to "identify the highest priority manually laid-out controls in your views and consider adopting the ReservedRegions API to implement your own displacement where needed."

## Displacement design patterns

*Displacement* = adjusting the frame of existing elements based on the available space so they stay visible, reachable and unobstructed when folded. It's about moving, resizing or reorganizing what's already there — never removing functionality.

Scope:
- If an element can adapt on its own, move it on its own (a single centered button → the region that supports its purpose).
- If elements work together, move them together to preserve the relationship (a selected photo + its context menu align around the fold as a pair; don't center the menu in the far region).
- Displacement can scale from one button up to a whole container.
- Be mindful of excessive movement — distance weakens the visual relationship. Favor small adjustments; controls that disappear or shift dramatically are harder to find.

What *doesn't* displace: continuous scrolling content (articles, feeds, documents, lists). It already adapts through scrolling.

Where things go, by pose:

| Pose | Guidance |
|---|---|
| Partially folded like a **book** | Move elements like alerts to the **trailing** side — closer to where they'll be when the device closes and the experience continues on the outer display. |
| **Laptop** / propped on a table | Top region = content that benefits from visibility at a distance (media, the same alert). Bottom region = interactive controls (media controls) — a more stable surface for touch. |
| Multiple regions suitable | Keep it contextual: a search field stays over the view it's searching, like it stays over the keyboard on iPhone. Its width/position adapt as the device folds. |

Beyond position and size, other properties can adapt: a grid can keep its outer margins but widen the spacing around the hinge so each container stays inside its region.

## Layout-only vs interaction

Reserved regions and arrangement views are the tools for **layout**. If you want to react to the fold *angle* for an effect or interaction, use `onHingeChange` / `UIHingeInteraction` instead (see SKILL.md §5).
