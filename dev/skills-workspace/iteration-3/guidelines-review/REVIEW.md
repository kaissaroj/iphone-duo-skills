# iPhone Duo guidelines review

Reviewed against `skills/iphone-duo-design-guidelines/GUIDELINES.md` (iOS 27.1).
Paths are relative to `dev/evals/`.

## fixture-rn/NowPlaying.tsx (React Native / Expo)

### Blocking

- fixture-rn/NowPlaying.tsx:7 — `Dimensions.get('window')` at module scope; cached width is stale after open/close, Split View, PiP — `const { width, height } = useWindowDimensions()` inside `NowPlaying`
- fixture-rn/NowPlaying.tsx:8 — `ART` sized from the cached `SCREEN_W`; artwork is the wrong size after a fold or in a 50/50 split — compute from `useWindowDimensions().width` in the component
- fixture-rn/NowPlaying.tsx:16 — fixed `width: SCREEN_W` / `SCREEN_W / 2` on the column; in Split View (half width) the column overflows and transport buttons land off-screen — drop the explicit width, use `flex: 1` / `alignSelf: 'stretch'`
- fixture-rn/NowPlaying.tsx:15 — `paddingHorizontal: insets.left` mirrors one side's inset; when the strip is on the right (Split View right, outer landscape) the transport row sits behind it, unreachable — `paddingLeft: insets.left, paddingRight: insets.right, paddingTop: insets.top, paddingBottom: insets.bottom`, or wrap in `SafeAreaView` with `edges`
- fixture-rn/NowPlaying.tsx:17 — artwork `alignSelf: 'center'` on a full-width column; on the inner display the hero image straddles the hinge — two-pane layout: `flexDirection: width > height ? 'row' : 'column'`, art in one even half, controls in the other
- fixture-rn/NowPlaying.tsx:21 — Play button is the horizontal center of a centered row (`styles.transport`, :36); it sits exactly on the fold in book pose — same two-pane fix; keep the transport row off the hinge line and in the stable bottom half in laptop pose
- fixture-rn/NowPlaying.tsx:38 — hand-built `position: 'absolute', bottom: 0` bar is JS-drawn: it never moves to the vertical strip and ignores `insets.bottom` — move Lyrics/Queue/Share/AirPlay to `@react-navigation/native-stack` `headerRight` (symbols, narrow) or native tabs (Expo Router `NativeTabs` / `react-native-bottom-tabs`)

### Should fix

- fixture-rn/NowPlaying.tsx:12 — `Platform.isPad` used as "wide layout"; `.phone` idiom is regular×regular on the inner display so this is always false there — `const isWide = width > height` (or a width threshold) from `useWindowDimensions()`
- fixture-rn/NowPlaying.tsx:13 — `ScreenOrientation.lockAsync(PORTRAIT_UP)`; the inner display ignores supported orientations, so the lock silently doesn't hold when open and the layout must not assume portrait — remove the lock (tent pose needs landscape on the outer display anyway); size from window dimensions
- fixture-rn/NowPlaying.tsx:4 — `@react-navigation/bottom-tabs` is JS-drawn and stays at the bottom instead of joining the strip — Expo Router `NativeTabs` or `react-native-bottom-tabs` (`UITabBarController`)
- fixture-rn/NowPlaying.tsx:26 — `'•••'` ellipsis item on a hand-rolled bar; the ellipsis is reserved for the system overflow menu — put items in the native header/tab bar and let the system supply the single overflow; a custom menu gets a distinct symbol
- fixture-rn/NowPlaying.tsx:26 — text-only items (`Lyrics`, `Queue`, `Share`, `AirPlay`); text stays horizontal and wastes strip height — symbol items, counts as badges

### Nice to have

- fixture-rn/NowPlaying.tsx:5 — `expo-screen-orientation` imported only to lock; once the lock is removed, drop the dependency so orientation state can't creep into layout later
- fixture-rn/NowPlaying.tsx:33 — `alignItems: 'center'` on root plus centered title (:35) is a full-display-centered hero with tappable content under it; reserve full-width centering for immersive non-interactive visuals

## fixture/Bad.swift (UIKit)

### Blocking

- fixture/Bad.swift:4 — `UIScreen.main.bounds.width` cached as layout width; ambiguous on a two-display device and wrong in Split View / after open-close — `view.bounds` / `view.safeAreaLayoutGuide` at layout time, `window?.windowScene?.screen` if a screen is truly needed
- fixture/Bad.swift:8 — `view.bounds.width - view.safeAreaInsets.left * 2` mirrors the left inset; with the strip on the right, content ends up behind it — `view.bounds.inset(by: view.safeAreaInsets).width`
- fixture/Bad.swift:13 — `card.center = view.center` centers on the full display; on the inner display the card straddles the hinge and on the outer display sits partly under the strip — constrain to `safeAreaLayoutGuide`, or if it's a foreground/background pair use `UIArrangementViewController` (`.updateArrangement(.overlay)`)

### Should fix

- fixture/Bad.swift:5 — `UIScreen.main.scale` — `traitCollection.displayScale`
- fixture/Bad.swift:6 — `UIDevice.current.orientation.isLandscape` for layout; the inner display ignores orientation — `traitCollection.horizontalSizeClass == .regular`
- fixture/Bad.swift:7 — `userInterfaceIdiom == .pad` to decide wide layout; iPhone Duo is `.phone` and regular×regular when open — size classes, not idiom
- fixture/Bad.swift:9 — `UIToolbar()` hand-built; its items are not considered for the vertical strip — put items in `navigationItem` groups under a `UINavigationController`
- fixture/Bad.swift:10 — `UIBarButtonItem(image:style:target:action:)` with no title; the strip needs a title for overflow/expanded forms — `UIBarButtonItem(title: "…", image: UIImage(systemName: "square"), …)`
- fixture/Bad.swift:11 — custom item using the `"ellipsis"` symbol; reserved for the system overflow — `navigationItem.additionalOverflowItems = UIDeferredMenuElement { … }`, or a distinct symbol for a separate menu
- fixture/Bad.swift:12 — `.flexibleSpace` for manual spacing; flexible spacers are zero-size in the vertical strip — group with `UIBarButtonItemGroup`, no manual spacing
- fixture/Bad.swift:15 — `supportedInterfaceOrientations { .portrait }`; honored on the outer display only, the inner display ignores it, so nothing may assume portrait (see :6) — remove the lock unless it's a game that fills the screen in every pose

### Nice to have

- fixture/Bad.swift:3 — layout computed once in `viewDidLoad`; the app resizes on open/close, Split View and PiP — do size-dependent layout in `viewWillLayoutSubviews` / `viewWillTransition(to:with:)` or with Auto Layout against the safe-area guide
