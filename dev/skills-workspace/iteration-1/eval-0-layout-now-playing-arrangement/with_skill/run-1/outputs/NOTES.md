# NowPlayingView for iPhone Duo — notes

## What changed and why

**`HStack` → `ArrangementView` (`.split`).**
The original `HStack { PlayerView(); TranscriptView() }` is a fixed two-column layout. On the
inner display, when the device is partially folded, the hinge lands wherever the HStack's
divider happens to be, so one pane (or the centered player artwork) straddles the fold.
`ArrangementView` (new in iOS 27.1) holds exactly two views — primary and secondary — and
positions them from size class, aspect ratio and the active division (fold) region. When the
device is folded it keeps each pane inside its own region. Apple's own worked example for this
API is Podcasts' Now Playing + transcript, and the migration table maps `HStack`/`VStack` to
`.split`.

`.split` was chosen over `.overlay` because player and transcript are a main/detail pair where
neither should be obscured. Default `.split` (both axes allowed) is used rather than
`.split.axes(.horizontal)`: with an axis restriction, a taller-than-wide arrangement would show
*only* the primary and silently drop the transcript. Unrestricted, it goes side-by-side when
wider than tall (open flat / landscape) and stacks vertically when taller than wide (open,
portrait) — the same "transcript inline when tall" behaviour Podcasts uses.

**Navigation stays outside the arrangement.** The `NavigationStack` wraps the `ArrangementView`;
the toolbar toggle lives on the stack, not inside a pane. Apple's hard rule: never put
`NavigationStack`/`NavigationSplitView`/`TabView` inside an arrangement, and never put an
arrangement inside a `List`/`ScrollView`.

**Collapsing when closed.** Size classes are the whole story on Duo: outer display = compact
width, inner display = regular width, regardless of pose or orientation. So the view branches
on `horizontalSizeClass` only:

- regular → `ArrangementView` with the transcript as the secondary pane, or `PlayerView` alone
  when the user toggles the transcript off;
- compact → `PlayerView` alone; the transcript is presented as a `.sheet` with
  medium/large detents. Sheets are system components, so they avoid the fold and the outer
  camera automatically and behave correctly in a narrow Split View multitasking slot too.

When the device opens while the sheet is showing, `onChange(of: isCompact)` dismisses the sheet
so the transcript reappears as a pane rather than a modal.

**Things deliberately not used.** No interface-orientation checks (the inner display ignores
the supported-orientation list), no `UIDevice.userInterfaceIdiom` (`.phone` can be
regular/regular now), no `UIScreen.main`, no fixed widths or breakpoints (Split View
multitasking and pinned PiP resize the app at runtime), and no `GeometryReader` fold math —
the arrangement container already does fold avoidance.

## Follow-ups the caller may want

- **`PlayerView` internals.** If `PlayerView` manually centers artwork/transport controls on
  the full width, they can still straddle the fold when the transcript is hidden and the player
  owns the whole inner display. Options: keep `isTranscriptVisible` on but render the secondary
  as a collapsed placeholder, or inside `PlayerView` query
  `proxy.reservedRegions(kind: .division)` from `onGeometryChange` and displace the control
  cluster toward the trailing region (book pose) / bottom region (laptop pose). Scrolling
  transcript text should *not* displace.
- **Safe area.** `PlayerView`'s tappable controls must stay inside the (asymmetric)
  safe area — SwiftUI does this by default; only background artwork should
  `.ignoresSafeArea()`.
- **Testing.** Xcode 27.1 → Device Hub → iPhone Duo simulator; use the fold/open/close/rotate
  buttons and drag the app to each side of the inner display for Split View.
