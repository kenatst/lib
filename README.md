# EMBER

A premium adult relationship and intimacy wellness application for iOS. EMBER helps adults reconnect with desire, attraction, anticipation and emotional/physical connection through three journeys:

| Journey | Promise |
| --- | --- |
| **My Desire** | "I want to feel desire again." |
| **Their Desire** | "I miss feeling wanted." — improving the *conditions* around attraction (connection, novelty, confidence, communication, playfulness). EMBER never manipulates another person's feelings, behavior, consent or desire. |
| **Our Desire** | "We want our spark back." — a paired experience for two adults with an explicit consent gate. Private reflections stay private; they are never surfaced to a partner automatically. |

## Status

**Mission 003 — commercial credibility, true personalization, production couple architecture.** Building on the complete product (18+ age gate, welcome arc, journey selection, adaptive onboarding, qualitative desire profile, 21-day guided journeys in English and French, evening check-ins, private journal, evolving sketch illustrations, opt-in local reminders, full data deletion), this mission added:

* **Persistence truth machine** — absent vs unreadable vs corrupt files are distinct states; a locked-device launch can never clobber private data; corruption is quarantined byte-for-byte; deletion failure is surfaced honestly instead of faked.
* **JourneyPlanner** — deterministic personalization: intention × desire-profile × completed days × evening check-ins decide which day comes next (bounded reordering with protected anchor days), today's dose (reduced/steady/raised), and which authored copy variants are served. Guarded dimensions lower challenge; "nothing changed" visibly slows the journey.
* **Three genuinely different journeys** — each intention has its own 21-day theme sequence and its own rotation through theme pools (title, idea, practice, evening question always belong to one theme). Same day number, different journey → different experience.
* **Production couple architecture** — `CoupleService` protocol defines the two-device contract (anonymous identity, pairing, shared completions, explicit hand-offs to the opposite role only, unpair revocation) with no API through which a partner could request the other's private reflections. The shipped same-device mode is labeled honestly as a demo reality.
* **StoreKit 2 monetization** — one annual subscription, free preview of days 1–3, time-aware entitlement gates, restore purchases with an honest "nothing to restore" state, SKTestSession integration tests covering purchase/reload/refund. No dark patterns anywhere on the paywall.
* **CI** — GitHub Actions build + test workflow.

81 Swift Testing tests across 16 suites, including adversarial persistence tests and real StoreKit integration tests.

## Requirements

* iOS 18.0+ (iPhone, portrait-first)
* Xcode 16 or newer (developed against Xcode 26 / Swift 6 toolchain)
* No third-party dependencies. No signing credentials required for simulator builds.

## Open & run

Select the Ember scheme and an iPhone simulator, then Cmd+R. Command line:

```shell
xcodebuild -project Ember.xcodeproj -scheme Ember \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

xcodebuild -project Ember.xcodeproj -scheme Ember \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Bundle identifier: `com.kenatst.ember`. Development team is deliberately unset.

## Architecture

Pragmatic feature-oriented architecture. Folders map to responsibilities; Xcode uses file-system synchronized groups, so new files inside `Ember/` are picked up automatically.

```
Ember/
├── App/             EmberApp (@main), AppState phase machine, AppRouter/AppRoute,
│                    RootView (typed route→view mapping), DemoLauncher (DEBUG-only screen seeding)
├── Core/            String resolution helper, privacy-conscious os.Logger,
│                    ReminderScheduler (opt-in local notifications only)
├── Domain/          Pure value logic: Onboarding questions & branching,
│                    DesireProfile derivation, JourneyCatalog (21 days),
│                    CheckIn adaptation engine
├── Data/            EmberStore — the single persistence owner (see Privacy)
├── DesignSystem/
│   ├── Foundation/  Palette (semantic tokens), Typography (serif/sans voices),
│   │                Spacing, Radius, Motion (Reduce-Motion-aware), Haptics
│   └── Components/  PaperBackground, EmberButton, EditorialText helpers,
│                    SketchCurve + SketchMotifView (parametric hand-drawn motifs)
└── Features/
    ├── Welcome/         Opening arc + 18+ age gate
    ├── Journey/         Journey selection, Home ("today")
    ├── Onboarding/      Adaptive questionnaire (branches by journey)
    ├── DesireProfile/   Qualitative portrait (no scores shown)
    ├── DailySession/    Discover → Reflect (private note w/ autosave) → Experiment
    ├── EveningCheckIn/  The Return: one honest tap that shapes pacing
    ├── Progress/        Evolving motif + chapters + Journal entry point
    ├── Couple/          Our Desire: consent gate, asymmetric steps, hand-offs
    └── Settings/        Privacy statement, deletion, reminders, restart
EmberTests/           Swift Testing suite (46 tests across 10 suites)
tools/                gen_strings.py (String Catalog generator, EN+FR),
                      content_strings.py (21-day editorial content), capture_screens.sh
```

Key decisions:

* **State**: `AppState` is a small `@Observable` phase machine (ageGate → firstRun → active). `AppRouter` holds `[AppRoute]` for one `NavigationStack`; route→view mapping lives centrally in `RootView`.
* **Persistence**: `EmberStore` owns everything. JSON in Application Support with `.completeFileProtection`, excluded from backups, schema-versioned; unreadable files are quarantined, never silently destroyed. Reflections and drafts are keyed by space (`solo`/`partnerOne`/`partnerTwo`) — there is no API to read another partner's space.
* **Design system**: semantic tokens only. Motifs are generated geometry (`SketchCurve`): deterministic polylines with hand-tremor, evolving across the journey — progress is drawn, not counted.
* **Localization**: every user-facing string lives in `Resources/Localizable.xcstrings` (EN source, full FR), generated from `tools/gen_strings.py` + `tools/content_strings.py`. Never hardcode production-facing strings.
* **Accessibility**: style-based fonts scale with Dynamic Type, all animations flow through `Motion.resolved(_:reduceMotion:)`, controls meet 44pt targets, decorative art is labeled and hidden from reading order where appropriate.
* **Concurrency**: approachable-concurrency settings with MainActor default isolation; pure value types are explicitly `nonisolated`.

## Privacy constraints (binding for all future work)

EMBER processes highly sensitive relationship and intimacy data.

* Collect the minimum necessary data; privacy by default. No accounts, no analytics, no tracking; `PrivacyInfo.xcprivacy` declares zero collection.
* Everything stays on device: file protection at rest, excluded from backups. Deletion in Settings is immediate and real.
* Private reflections are space-keyed and can never surface to a partner without an explicit hand-off written by their author.
* Couple mode requires an explicit consent confirmation before any content is unlocked; its daily steps are designed so nothing scripts covert behavior change of a partner.
* Never log user content; `EmberLog` carries static diagnostics strings only.
* No secrets or AI keys in the client. If AI is ever introduced it must run server-side with the same boundaries.

> **ATTENTION — future coding agents**
>
> Extend the existing structure; keep every file purposeful; keep user-facing copy in the String Catalog via `tools/gen_strings.py` (regenerate after editing); keep tests meaningful and green before committing. The couple-mode ethics rules above are non-negotiable.
