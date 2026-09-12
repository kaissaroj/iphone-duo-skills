# iPhone Duo Design Guidelines

An agent skill that teaches Claude Code, Codex, Cursor, Copilot, Windsurf, Gemini CLI and Cline how to **build and review apps for iPhone Duo** — Apple's folding, dual-display iPhone (iOS 27.1). SwiftUI, UIKit, React Native, and Expo.

```bash
npx skills add kaissaroj/iphone-duo-skills
```

## What it does

Once installed, the agent applies Apple's iPhone Duo guidelines automatically:

- **While you code** — "build the Now Playing screen, it should work on iPhone Duo" → it uses size classes not orientation, keeps controls off the hinge, uses system bars so they go vertical, uses the *real* iOS 27.1 API names.
- **When you ask for a check** — "review `NowPlaying.swift` for iPhone Duo", "check this screenshot", "audit `src/` for the folding iPhone" → you get `file:line — problem — fix`, grouped by severity.

That's it. One skill, one rules file.

<p align="center"><img src="docs/example-review.png" width="640" alt="A Now Playing screen on the iPhone Duo inner display, partially folded. Numbered boxes mark the album art and Play button sitting on the hinge line, a text-only Edit item in the vertical bar strip, and a hand-built horizontal toolbar that never moved to the side."></p>
<p align="center"><sub>A review of a Now Playing screen: album art and Play button on the hinge (1–3), a hand-built toolbar that stays horizontal (4), a text-only item in the vertical strip (5), content centered on the full width instead of the safe area (6), a second overflow menu (7).</sub></p>

## Why a skill

Apple published the [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) HIG and six tech talks in September 2026 — after every model's training data. Several APIs (`ArrangementView`, `reservedRegions`, `axisBehavior`, `toolbarVerticalEdge`, `onHingeChange`) aren't even in Apple's public docs index yet, only in tech-talk code samples. Without the guidelines, agents confidently invent `usesVerticalBars` traits and 24-point "hinge gutters". With them, in our tests, correctness on Duo-specific checks went from 67% to 100% with zero invented symbols.

Every API in [GUIDELINES.md](skills/iphone-duo-design-guidelines/GUIDELINES.md) is traceable to Apple's samples — see [research/VERIFIED-APIS.md](research/VERIFIED-APIS.md).

## Install

```bash
npx skills add kaissaroj/iphone-duo-skills          # this project, every agent detected
npx skills add kaissaroj/iphone-duo-skills -g       # user-level, all projects
```

Or copy `skills/iphone-duo-design-guidelines/` into `.claude/skills/`, `.codex/skills/`, `.cursor/skills/`, or your agent's equivalent.

## Try

- "Make this `HStack` of player and queue work on iPhone Duo."
- "Add Share and Filter to this toolbar — we target iOS 27."
- "Review `src/screens/` against the iPhone Duo guidelines."
- *(paste a screenshot)* "What breaks when this is folded?"
- "Does this Expo app need changes for the new iPhone?"

## React Native

The guidelines give every rule its RN equivalent where one exists (`useWindowDimensions`, `useSafeAreaInsets` with separate left/right, native-stack and native tabs so bars go vertical) and say plainly where none does yet (reserved regions, arrangement views, hinge — native code required).

## Repo

```
skills/iphone-duo-design-guidelines/   SKILL.md · GUIDELINES.md · assets/ (5 HIG diagrams)
research/                              verified API list · 19 HIG diagrams · 6 talk transcripts + code samples
dev/                                   evals, fixtures, earlier multi-skill version
```

## Sources

[HIG: Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) · Tech talks [111461](https://developer.apple.com/videos/play/tech-talks/111461) · [111462](https://developer.apple.com/videos/play/tech-talks/111462) · [111463](https://developer.apple.com/videos/play/tech-talks/111463) · [111464](https://developer.apple.com/videos/play/tech-talks/111464) · [111465](https://developer.apple.com/videos/play/tech-talks/111465) · [111466](https://developer.apple.com/videos/play/tech-talks/111466)

Apple diagrams and transcripts © Apple Inc., included for reference. Everything else MIT.
