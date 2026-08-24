# EMBER

A premium adult relationship and intimacy wellness application for iOS. EMBER helps adults reconnect with desire, attraction, anticipation and emotional/physical connection through three journeys:

| Journey | Promise |
| --- | --- |
| **My Desire** | "I want to feel desire again." |
| **Their Desire** | "I miss feeling wanted." — improving the *conditions* around attraction (connection, novelty, confidence, communication, playfulness). EMBER never manipulates another person's feelings, behavior, consent or desire. |
| **Our Desire** | "We want our spark back." — a paired experience for two adults with an explicit consent gate. Private reflections stay private; they are never surfaced to a partner automatically. |

## Status

**Mission 004 — the ongoing daily engine.** EMBER is no longer a 21-day program: it is an ongoing daily guide. Every calendar day the engine freezes one coherent experience (Discover / Reflect / Act / Return), chosen from the authored seed library by journey intention × desire profile × learned signals − recency saturation. There is no final day; missed days create no backlog; a returning user simply gets today.

Key systems:

- **DailyEngine** — idempotent `planForToday()`: today's plan is created once and frozen forever (IDs only, localized at render). Deterministic: same state → same plan.
- **ContentLibrary** — the original 21-day arc plus theme pools (6 variants per theme for Discover/Reflect/Act, 4 Return prompts) as addressable content units with per-movement cooldowns.
- **ThemeSignals** — bounded, decaying per-theme resonance learned from evening Returns; the evolving layer above the immutable onboarding profile.
- **LocalDay** — canonical local calendar-day identity (DST/timezone-safe via injected Calendar).
- **Migration v4** — legacy numbered history becomes honest session records (no invented dates); journal, check-ins, profile, reflections all preserved; free-session allowance carries over.
- **AccessPolicy** — free = first three completed sessions ever (the calendar can never reset it); premium = unlimited ongoing adaptive guide. StoreKit 2 with true refund handling.
- **Couple mode** — OUR DESIRE plans freeze asymmetric assignments per partner from one shared plan identity; private reflections remain structurally unreachable by the partner.

142 Swift Testing tests across 28 suites — including 30/90/180-day user simulations asserting uniqueness, cooldown honesty, bounded signal drift and determinism. GitHub Actions CI green.

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
│                    DesireProfile derivation, ContentLibrary + DailyEngine (ongoing),
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
* **Localization**: every user-facing string lives in `Resources/Localizable.xcstrings` (EN source, full FR), generated by merging `tools/content_strings.py`, `tools/theme_titles_discovers.py`, `tools/theme_pools.py`, and `tools/ongoing_library.py` into `tools/gen_strings.py`. Never hardcode production-facing strings.
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
