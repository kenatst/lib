# EMBER

A premium adult relationship and intimacy wellness application for iOS.
EMBER helps adults reconnect with desire, attraction, anticipation and
emotional/physical connection through three journeys:

| Journey       | Promise                        |
| ------------- | ------------------------------ |
| **My Desire** | "I want to feel desire again." |
| **Their Desire** | "I want to feel wanted again." — improving the *conditions* around attraction (connection, novelty, confidence, communication, playfulness). EMBER never manipulates another person's feelings, behavior, consent or desire. |
| **Our Desire** | "We want our spark back." — a paired experience for two adults. Private reflections stay private; they are never automatically exposed to a partner. |

## Status

**Mission 001 — native foundation.** The repository contains a buildable,
tested Xcode project with the app skeleton: app state machine, typed routing,
domain seed model, structural design-system foundation, localization-ready
resources and a Swift Testing suite. There is intentionally **no product UI,
no backend, no persistence and no visual design system yet.**

## Requirements

- iOS 18.0+ (iPhone, portrait-first)
- Xcode 16 or newer (developed against Xcode 26 / Swift 6 toolchain)
- No third-party dependencies. No signing credentials required for simulator builds.

## Open & run

```bash
open Ember.xcodeproj
# select the Ember scheme and an iPhone simulator, then Cmd+R
```

Command line:

```bash
xcodebuild -project Ember.xcodeproj -scheme Ember \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

xcodebuild -project Ember.xcodeproj -scheme Ember \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Bundle identifier: `com.kenatst.ember` (temporary). Development team is
deliberately unset.

## Architecture

Pragmatic feature-oriented architecture. Folders map to responsibilities;
Xcode uses file-system synchronized groups, so new files inside `Ember/` are
picked up automatically without editing the project file.

```
Ember/
├── App/           EmberApp (@main), AppState, AppRouter/AppRoute, RootView
├── Core/          Cross-cutting utilities (privacy-conscious os.Logger)
├── Domain/        Pure value types (DesireIntention)
├── Data/          Future persistence/repositories (empty by design)
├── DesignSystem/
│   ├── Foundation/  Spacing, Radius, Typography, Palette tokens
│   ├── Components/  Future reusable components (empty by design)
│   ├── Motion/      Reduce Motion-aware animation resolution
│   └── Haptics/     Subtle feedback wrapper
├── Features/
│   ├── Welcome/      Temporary technical landing screen
│   ├── Onboarding/   Temporary root-phase scaffold
│   ├── Journey/      Placeholder destination proving typed navigation
│   ├── DailySession/ EveningCheckIn/ Couple/ Progress/ Paywall/ Settings/  (reserved)
│   └── DesireIntention+Presentation.swift   UI copy mapping for domain intents
└── Resources/     Localizable.xcstrings (String Catalog), Assets.xcassets
EmberTests/        Swift Testing suite (state machine, routing, domain, motion)
```

Key decisions:

- **State**: `AppState` is a small `@Observable` phase machine
  (`onboarding → active`). It will later grow first-launch detection,
  session and journey states backed by real persistence.
- **Routing**: one `NavigationStack` driven by `[AppRoute]` in `AppRouter`.
  Route→view mapping lives centrally in `RootView`. Routes carry payloads and
  are `Hashable`, so deep links can be added without redesign.
- **Dependency wiring**: `@Observable` objects injected via `.environment()`;
  views read them with `@Environment`. No singletons, no global mutable state.
- **Design system**: semantic token namespaces only (`Spacing`, `Radius`,
  `Typography`, `Palette`, `Motion`). Current color values are provisional
  placeholders; the visual identity arrives in a dedicated design mission.
- **Localization**: all user-facing copy lives in
  `Resources/Localizable.xcstrings` (source language: English; French planned
  early). Never hardcode production-facing strings in Swift files.
- **Accessibility**: Dynamic Type scales through text-style-based fonts,
  Reduce Motion is honored via `Motion.resolved(_:reduceMotion:)`,
  controls meet minimum touch targets, rows are combined for VoiceOver.
- **Concurrency**: modern approachable concurrency settings with MainActor
  default isolation; pure value types are explicitly `nonisolated`.

## Deliberately not implemented yet

Authentication, persistence (SwiftData/Core Data), networking, backend,
AI services, StoreKit/paywall, push notifications, analytics, couple pairing,
questionnaires, recommendation logic, journey content, and the final visual
design system. External SDKs (Supabase, RevenueCat, Firebase, AI providers)
are intentionally absent.

## Privacy constraints (binding for all future work)

EMBER will process highly sensitive relationship and intimacy data.

- Collect the minimum necessary data; privacy by default.
- Private reflections must remain private — never surfaced to a partner automatically.
- Never log user content or sensitive answers; `EmberLog` is for non-sensitive diagnostics only.
- Never place sensitive information in analytics events.
- No secrets or AI provider keys in the client. AI-assisted features must run server-side.
- Account/data deletion must remain supported as these systems are added.

> **ATTENTION — future coding agents**
>
> Do NOT invent product functionality without explicit direction from the
> Ember product specification. Do not add screens, content flows, paywalls,
> backend integrations or dependencies on your own initiative. Extend the
> existing structure; keep every file purposeful; keep user-facing copy in
> the String Catalog; keep tests meaningful. When in doubt, stop and ask.
