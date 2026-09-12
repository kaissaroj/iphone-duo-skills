# NowPlayingView — notes

## What changed

The original view was a `NavigationStack { HStack { PlayerView(); TranscriptView() } }` with the
transcript toggled on/off. That has two problems on a folding device:

1. An `HStack` with two flexible children splits the width proportionally, so on an unfolded
   iPhone Duo the seam between the two views rarely lands on the hinge — controls and text end up
   straddling the fold.
2. When the device closes, the width drops to a compact size class and the same `HStack` squeezes
   both views into one narrow column.

## Approach

The rewrite resolves one of three layouts from **size classes + the proposed container size**
(via `GeometryReader`), instead of branching on device model:

| State                                  | Layout      | Details |
|----------------------------------------|-------------|---------|
| Unfolded (regular width, >= 640 pt)    | `twoPane`   | Player left, transcript right. Each pane is pinned to exactly half the width with `containerRelativeFrame(.horizontal, count: 2, span: 1)`, and a 24 pt centre gutter is carved from each pane's inner edge so nothing crosses the middle. |
| Closed, tall (compact width, >= 700 pt)| `stacked`   | Player on top (layout priority 1), transcript below. |
| Closed & short, or transcript hidden   | `single`    | Player only. If the transcript is enabled, a bottom "Show Transcript" button opens it as a `.medium/.large` detent sheet. |

Layout switches are animated with `.snappy` so opening/closing the device or flipping the toggle
transitions smoothly.

## Why not read the hinge directly

Deliberately no UIKit, no hard-coded hinge rects, and no device-model checks. Halving the
container width keeps the seam on the hinge for any symmetric fold, and the size-class guard
handles the closed state. If iOS 27.1 ships a SwiftUI environment value for the fold/hinge
region, the `centreGutter` constant is the single place to swap in that value.

## Assumptions

- `PlayerView()` and `TranscriptView()` exist and are flexible (fill their proposed size).
- The `twoPaneMinimumWidth` (640) and stacked-height threshold (700) are tunable constants;
  adjust once real Duo dimensions are confirmed.
