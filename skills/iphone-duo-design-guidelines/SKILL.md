---
name: iphone-duo-design-guidelines
description: Build and review iOS apps (SwiftUI, UIKit, React Native, Expo) for iPhone Duo — Apple's folding, dual-display iPhone (iOS 27.1). Use whenever a task mentions iPhone Duo, the foldable or folding iPhone, the fold or hinge, dual displays, vertical toolbars, device poses, or making an iPhone app adaptive for iOS 27 — while writing layout or toolbar code, and when asked to "check", "review", or "audit" a file, folder, screenshot, or running app for iPhone Duo. Even if the user only says "the new iPhone".
license: MIT
metadata:
  author: saroj
  version: "1.0.0"
  argument-hint: <file, folder, or screenshot>
---

# iPhone Duo Design Guidelines

Apply Apple's iPhone Duo guidelines while building, or review against them.

## How it works

1. Read [GUIDELINES.md](GUIDELINES.md) — the rules, the API names for Swift and React Native, the list of symbols that *don't* exist, and the output format.
2. **Building**: apply the rules as you write. Size classes not orientation, asymmetric safe areas, system bars not custom ones, even grid columns, nothing centered on the hinge. Use only API names from the guidelines — the iOS 27.1 APIs are newer than your training data and easy to invent.
3. **Reviewing**: read the file(s), folder, or screenshot the user named. Check every rule. Output `file:line — rule — fix` grouped by severity (blocking → should fix → nice to have). For a screenshot, describe the location instead of a line. For a running app, use the simulator/accessibility tools you have to read the screen, then the same format.
4. If no target was given, ask which files or screen to review.

## Quick grep before a code review

These catch the mechanical mistakes; the guidelines cover the rest.

```
UIScreen\.main | interfaceOrientation | UIDevice\.current\.orientation | userInterfaceIdiom ==
\.frame\(width: [0-9]{3} | safeAreaInsets\.(left|right) \* 2 | UIToolbar\( | UIBarButtonItem\(image:
"ellipsis" | ArrangementView \{[^}]*Navigation | GridItem.*count: [357]\b
Dimensions\.get\( | Platform\.isPad | paddingHorizontal: insets\. | createBottomTabNavigator | @react-navigation/stack\b
```

## Not covered

Camera pipelines beyond the one-line note, and native modules to bridge `reservedRegions` / `ArrangementView` / hinge to React Native (no binding exists yet — the guidelines say so where it matters).
