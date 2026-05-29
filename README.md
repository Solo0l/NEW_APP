# PACE — Watch-First Running App

A local-only iOS 17 + watchOS 10 running companion for the solo runner. No accounts. No social layer. No cloud dependency. Just running data, immediately available on your wrist.

---

## Product Vision

PACE is built around a single observation: the best running apps are the ones that get out of your way. Every interaction in PACE is optimized for one of three contexts — before a run (3 taps to start), during a run (glanceable at full sprint), and after a run (insight in under 10 seconds).

The Watch experience is the primary interface. The iPhone is for post-run review. This inversion — Watch first, phone second — drives every architectural and UX decision in the codebase.

**Three immutable principles:**
- **3 seconds to run.** Tap the start card. Countdown begins. No configuration required.
- **Watch-first.** The Watch app is fully independent. GPS, HR, splits, summary — all on wrist.
- **Local-first.** SwiftData is the database. HealthKit is an export layer. No network calls, no accounts, no sync dependencies.

---

## Core Features

### iPhone App
| Feature | Description |
|---|---|
| Instant start | Tap START → 3-second countdown → run begins. Zero friction path is the primary path. |
| Optional config | Context-menu on START reveals per-run goal and lap interval settings. Discoverable but not mandatory. |
| Active run screen | Full-screen, status-bar-hidden. Two swipeable metric pages. Long-press to pause (prevents accidental triggers). |
| Pace indicator | Current pace displayed large (Zone A, top 45% of screen). Color shifts cyan→orange when pace drops below goal. |
| Lap arc | Visual arc in Zone C fills as current lap distance accumulates toward the configured interval. |
| Pause overlay | Slides up from bottom on pause: RESUME / Mark Lap / End Run with two-tap end confirmation. |
| Post-run insight | Personal record detection shown as highlighted card at the top of every summary screen. |
| Route map | `UIViewRepresentable` wrapping `MKMapView` with `MKPolylineRenderer`. Tappable to expand to full-screen interactive map. |
| Splits accordion | Collapsed by default. Each split shows a pace bar (cyan = faster than avg, orange = slower). |
| HR zone bar | Proportional colored bar showing time spent in each of 5 zones per run. |
| GPX export | Available from summary overflow menu via `UIActivityViewController`. |
| 12-week chart | Bar chart in History. Current week highlighted in cyan. |
| Goals | Weekly distance, weekly run count, monthly distance. Inline progress ring on Home. |
| Incomplete run recovery | Detects runs left in `.inProgress` state on app launch and prompts save or discard. |

### Apple Watch App
| Feature | Description |
|---|---|
| Independent tracking | `HKWorkoutSession` + `HKLiveWorkoutBuilder`. Runs without the iPhone present. |
| Two metric pages | Page 1: current pace / km / time / HR. Page 2: avg pace / elevation / lap pace & number. Swipe to switch. |
| Long-press pause | Primary pause mechanism. Follows watchOS HIG — side button is unreliable for custom gestures. |
| Two-tap end | Tap "End Run" → confirm with "Finish". Prevents accidental session end. |
| Auto-lap haptics | Crown haptic on each split (via `WKInterfaceDevice.current().play(.notification)`). |
| Post-run summary | 3 swipeable pages: main stats / splits list / "full details on iPhone" CTA. |
| Toolbar pause button | Secondary pause affordance via top-right toolbar button. |
| Double-tap lap | Double-tap anywhere on the metrics view to mark a manual lap (active state only). |

### Data & Privacy
- All data stored locally via **SwiftData** (`@Model` classes, `ModelContext`)
- HealthKit used for HR during runs (read) and workout records (write on completion)
- No network calls anywhere in the codebase
- No user account, no login, no analytics SDK
- Route data stored as flat `[Double]` parallel arrays (O(1) access, no JSON decode on read)

---

## Architecture Overview

### Service Layer Pattern

All services use Swift 5.9's `@Observable` macro. There is **no `ObservableObject` conformance** anywhere — mixing the two creates undefined behavior. Services are injected via `.environment(service)` and consumed with `@Environment(Service.self)`.

```
RunService          — Run state machine, owns all live metrics
LocationManager     — CLLocationManager wrapper, pace calculation (10s rolling window)
HealthKitManager    — HKWorkoutSession lifecycle + HR streaming
PACEAnalytics       — Stateless enum, static functions only (no state = no @Observable)
PACEGoals           — Stateless enum, static functions only
```

**Why stateless enums for Analytics and Goals?**  
These have no mutable state that needs to be observed. Using `@Observable class` would allocate a new instance every time a computed property on a view called them — creating O(n) allocations per render cycle. Static functions on enums solve this completely.

### Run State Machine

```
idle ──→ countdown(n) ──→ active ──→ paused ──→ active
                                 └──→ ended(runID: UUID)
```

`RunPhase` is defined in `PACE/Models/Enums.swift` (not in `RunService.swift`) so the Watch target can import it from the shared `PACE/Models` source directory without importing the full iOS service layer.

`RunPhase.ended` carries a `UUID`, not a `Run` object. This allows the phase to be Equatable without making `Run` Equatable, and makes the cross-target sharing straightforward.

### Data Model

```
User (1)
  └── UserPreferences (embedded struct, not a @Model)

Run (many)
  ├── routeLatitudes: [Double]      ← flat arrays, O(1) access
  ├── routeLongitudes: [Double]     ← no JSON decode
  ├── splits: [Split]               ← cascade delete
  └── metrics: [HealthMetricSnapshot] ← cascade delete

Goal (many)
  └── status: .active | .completed | .missed | .abandoned

Achievement (many)
```

All numeric data is stored in SI units (meters, seconds/meter) and converted at display time using `PACEFormatter`. This ensures a single source of truth regardless of the user's distance unit preference.

### Design System

| Token | Value | Usage |
|---|---|---|
| `backgroundPrimary` | `#0A0A0A` | All screen backgrounds |
| `surface` | `#141414` | Cards, list rows |
| `surfaceElevated` | `#1E1E1E` | Input controls, secondary buttons |
| `accentCyan` | `#00D4FF` | Primary interactive elements, active metric highlight |
| `accentOrange` | `#FF6B35` | Below-goal pace indicator, slower-than-avg splits |
| `textSecondary` | `#606060` | Labels, captions, timestamps |
| `separator` | `#2A2A2A` | Dividers, card borders |
| `success` | `#30D158` | Completed goals, GPS acquired |
| `error` | `#FF3B30` | End run, delete actions |

Typography uses SF Pro Display for large metric numbers (weight 100–200, tracked tightly) and SF Pro Text for all UI copy. Both accessed via system font descriptors, no custom font assets needed.

---

## iPhone Flow

### First Launch (Onboarding)
1. **Welcome** — App name, tagline, single "Get Started" button
2. **Permissions** — Two rows (Location, Health) with required badge. "Allow & Start Running" triggers both permission dialogs in sequence.

### Every Subsequent Launch
3. **Home** — `PACE` wordmark in nav bar. START card (large, centered, pulsing ring on appear). Inline goal progress ring if active goal exists. Up to 3 recent runs below.
4. **Incomplete run alert** — If a run was left in `.inProgress` state more than 2 hours ago, an alert prompts save or discard before home content appears.

### Starting a Run
5. **Tap START** → `immediateStart()` reads saved preferences (lap interval) and calls `runService.startCountdown(lapInterval:)`. No sheet appears.
6. **Context-menu** → Long-press START card → "Set Goal Before Running" → `PreRunConfigView` sheet. Select lap interval and optional distance/time goal → "Start".
7. **Countdown** — Full-screen black. Numbers 3 → 2 → 1 with scale/opacity transition. Location tracking starts during countdown to give GPS time to acquire.

### During a Run
8. **Active Run** — Full-screen, status bar hidden, system overlays hidden.
   - Zone A (top 45%): Current pace in large type. `/km` unit below. Goal-pace arrow indicator (↑ cyan / ↓ orange) if a per-run goal is set.
   - Zone B (middle 30%): Three secondary metrics. Swipe horizontally to switch between `primary` (km / time / bpm) and `secondary` (avg pace / elevation / lap pace) sets. Page dots indicate current set.
   - Zone C (bottom 25%): Lap flag button (left), Pause button (center, long-press to activate), Lap arc progress ring (right).
9. **Lap feedback** — Toast banner fades in at top right: "Lap N" after each auto-lap or manual lap.
10. **Pause** — Long-press pause button → `PauseOverlayView` slides up from bottom: RESUME / Mark Lap / End Run.
11. **End confirmation** — Two taps: "End Run" text button → "Finish" destructive button.

### After a Run
12. **Post-Run Summary** — `RunSummaryView` presented full-screen via `.fullScreenCover`.
    - Insight card at top (personal record or comparison vs average)
    - Distance headline + time/pace pair
    - Route map (tap to expand to interactive full-screen map)
    - 2×N stats grid (best pace, elevation, avg HR, max HR, calories, paused time)
    - Splits accordion (collapsed by default, pace bars visualize each split vs average)
    - HR zone bar (proportional color blocks for zones 1–5)
    - Overflow menu: Export GPX / Delete Run

---

## Apple Watch Flow

### Home
1. **Watch Home** — "PACE" label + single "RUN" button (full-width cyan).
2. Tap RUN → `service.startCountdown()` begins.

### Running
3. **Countdown** — Large digit counting from 3 to 0, then transitions to active run view.
4. **Active Run Page 1** — Current pace dominates (top 60%). Divider. KM / TIME in two columns. HR row below if available.
5. **Active Run Page 2** — Swipe left. AVG PACE / ELEVATION / LAP PACE + LAP # in 2×2 grid layout.
6. **Pause** — Long-press anywhere on the metrics view → `pauseRun()`. The pause view slides up from the bottom of the screen.
7. **Pause View** — RESUME (full cyan) / Mark Lap (secondary) / End Run (red text). Tapping "End Run" shows a two-button confirmation row ("No" / "Finish") in place of the "End Run" button.
8. **Double-tap** — Marks a lap when in `.active` state.

### Post-Run
9. **Watch Summary Page 1** — ✓ Run Complete / distance large / time + avg pace / HR.
10. **Watch Summary Page 2** — Swipe left. Splits list (index + pace per km).
11. **Watch Summary Page 3** — Swipe left. iPhone icon + "Full details on iPhone" — nudges user to open the iPhone app.

---

## Folder Structure

```
NEW_APP/
├── project.yml                         # XcodeGen configuration (single source of truth)
├── prototype.html                      # Interactive UI prototype (open in browser)
│
├── PACE/                               # iOS App Target
│   ├── PACEApp.swift                   # @main entry point, service graph setup
│   │
│   ├── Models/                         # SwiftData @Model classes (also compiled into Watch target)
│   │   ├── Enums.swift                 # RunPhase, GoalType, HeartRateZone, etc. (SHARED)
│   │   ├── Run.swift                   # Primary run record
│   │   ├── Split.swift                 # Per-lap record
│   │   ├── Goal.swift                  # Goal with progress tracking
│   │   ├── User.swift                  # Singleton user prefs
│   │   ├── Achievement.swift           # Milestone records
│   │   └── HealthMetricSnapshot.swift  # Time-series HR data
│   │
│   ├── Services/                       # @Observable service classes
│   │   ├── RunService.swift            # State machine: idle→countdown→active→paused→ended
│   │   ├── LocationManager.swift       # CLLocationManager + pace window
│   │   ├── HealthKitManager.swift      # HKWorkoutSession + HR streaming
│   │   ├── GoalService.swift           # enum PACEGoals — stateless static functions
│   │   └── AnalyticsEngine.swift       # enum PACEAnalytics — stateless static functions
│   │
│   ├── DesignSystem/                   # Design tokens (SHARED with Watch)
│   │   ├── PACEColors.swift
│   │   ├── PACEFonts.swift
│   │   ├── PACESpacing.swift
│   │   └── PACEComponents.swift        # ProgressRing, PACEPrimaryButton, etc.
│   │
│   ├── Views/
│   │   ├── RootView.swift              # TabView (Home / History / Settings) + phase routing
│   │   ├── Onboarding/
│   │   │   └── OnboardingView.swift    # 2-screen onboarding (Welcome → Permissions)
│   │   ├── Home/
│   │   │   └── HomeView.swift          # START card, goal card, recent runs
│   │   ├── Run/
│   │   │   ├── ActiveRunView.swift     # Full-screen 3-zone metric display
│   │   │   ├── CountdownView.swift     # 3-2-1 countdown
│   │   │   ├── PauseOverlayView.swift  # Resume / Lap / End sheet
│   │   │   └── PreRunConfigView.swift  # Optional pre-run goal/lap config
│   │   ├── Summary/
│   │   │   └── RunSummaryView.swift    # Post-run detail: map, stats, splits, HR zones
│   │   ├── History/
│   │   │   └── HistoryView.swift       # 12-week chart + filtered run list
│   │   ├── Goals/
│   │   │   └── GoalsView.swift         # Active goal, past goals, suggestions
│   │   └── Settings/
│   │       └── SettingsView.swift      # Preferences + Max HR + Goals nav link
│   │
│   ├── Utilities/
│   │   ├── Formatters.swift            # PACEFormatter: pace, distance, HR, elevation (SHARED)
│   │   └── Extensions.swift            # CLLocationCoordinate2D+boundingRegion, etc. (SHARED)
│   │
│   └── Resources/
│       └── Info.plist
│
└── PACEWatch/                          # watchOS App Target
    ├── PACEWatchApp.swift              # @main + WatchRunService injection
    │
    ├── Services/
    │   └── WatchRunService.swift       # @Observable, HKWorkoutSession, WatchSplitSnapshot
    │
    ├── Views/
    │   ├── WatchHomeView.swift         # PACE wordmark + RUN button
    │   ├── WatchActiveRunView.swift    # 2-page TabView metric display
    │   ├── WatchPauseView.swift        # Resume / Lap / End with 2-tap confirm
    │   └── WatchSummaryView.swift      # 3-page post-run summary
    │
    └── Resources/
        └── Info.plist
```

**Files shared between iOS and Watch targets** (configured in `project.yml`):
- `PACE/Models/` — all model types including `Enums.swift` (defines `RunPhase`)
- `PACE/Utilities/Formatters.swift`
- `PACE/Utilities/Extensions.swift`
- `PACE/DesignSystem/PACEColors.swift`
- `PACE/DesignSystem/PACEFonts.swift`
- `PACE/DesignSystem/PACESpacing.swift`

---

## Dependencies

| Dependency | Source | Version | Purpose |
|---|---|---|---|
| **SwiftData** | Apple SDK | iOS 17+ | Local persistence, `@Model`, `@Query` |
| **HealthKit** | Apple SDK | iOS 17+ | HR streaming, workout write, HKObserverQuery |
| **WorkoutKit** | Apple SDK | watchOS 10+ | `HKWorkoutSession`, `HKLiveWorkoutBuilder`, `HKLiveWorkoutDataSource` |
| **CoreLocation** | Apple SDK | iOS 17+ | GPS tracking, elevation, background location |
| **MapKit** | Apple SDK | iOS 17+ | Route map display (`MKMapView`, `MKPolylineRenderer`) |
| **XcodeGen** | Homebrew | 2.40+ | `.xcodeproj` generation from `project.yml` |

**Zero third-party Swift packages.** No SPM dependencies. No CocoaPods.

---

## Setup Instructions

### Prerequisites

| Tool | Version | Install |
|---|---|---|
| Xcode | 15.0+ | App Store |
| XcodeGen | 2.40+ | `brew install xcodegen` |
| macOS | 14 Sonoma+ | System Update |

A **physical device** is strongly recommended for development. The Simulator does not support GPS location updates or HealthKit heart rate streaming.

### 1. Clone and generate the project

```bash
git clone <repo-url> NEW_APP
cd NEW_APP
xcodegen generate
```

This reads `project.yml` and generates `PACE.xcodeproj` with both targets properly configured, including the shared source directories for the Watch target.

> **Note:** Never commit `PACE.xcodeproj` to version control. Re-generate it from `project.yml` on each machine. The `.xcodeproj` is listed in `.gitignore`.

### 2. Open in Xcode

```bash
open PACE.xcodeproj
```

### 3. Configure signing

In Xcode:
1. Select the `PACE` target → **Signing & Capabilities** → set your **Team**
2. Select the `PACEWatch` target → **Signing & Capabilities** → set the same **Team**

Both targets need matching team IDs for the Watch app to install alongside the iPhone app.

### 4. HealthKit capability (if regenerating project)

XcodeGen handles HealthKit entitlements via `project.yml`. If you manually modify the project, verify that both targets have:
- **HealthKit** capability enabled
- `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` keys in `Info.plist`

### 5. Background Location (iPhone)

`Info.plist` must include:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
<key>NSLocationWhenInUseUsageDescription</key>
<string>PACE uses your location to track your running route and distance.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>PACE uses your location in the background to track runs when your screen is off.</string>
```

These are pre-configured in `PACE/Resources/Info.plist`.

---

## Build Instructions

### iPhone App

1. Select scheme: **PACE**
2. Select target: iPhone device (iOS 17+) or Simulator
3. Product → Run (`⌘R`)

> On Simulator: GPS is simulated. Use Debug → Simulate Location to set a route. HealthKit HR will not stream — `currentHeartRate` stays nil.

### Watch App

1. Select scheme: **PACEWatch**
2. Select target: paired Apple Watch (watchOS 10+)
3. Product → Run (`⌘R`)

> The Watch app must be installed via the paired iPhone scheme first. After the iPhone app is installed on the device, switching to PACEWatch scheme and running will deploy the Watch companion.

### Running Both Simultaneously

1. Select the **PACE** (iPhone) scheme
2. Run once to install on device
3. Switch to **PACEWatch** scheme
4. Run again — Xcode will deploy the Watch app to the paired watch

For day-to-day Watch development, the Watch can be debugged independently once both apps are installed.

### Clean Build

If `xcodegen generate` was re-run after structural changes to `project.yml`:

```bash
# In Xcode
Product → Clean Build Folder (⇧⌘K)
# Then rebuild
Product → Build (⌘B)
```

---

## Future Roadmap

### v1.1 — Audio & Feedback
- Audio split cues: AVSpeechSynthesizer announcing pace and distance at each km
- Below-goal pace audio warning (configurable threshold)
- Haptic patterns for lap, pause, end (iPhone)
- Watch crown haptic on auto-lap (already stubbed in `WatchRunService`)

### v1.2 — Structured Training
- Fixed weekly training plan templates (5K, 10K beginner/intermediate/advanced)
- Pace zones for workouts (easy / tempo / interval targets)
- Run streaks tracked in `Achievement` model (data model already supports this)
- Watch complication for daily run status and weekly distance

### v1.3 — Advanced Metrics
- Running cadence from CoreMotion `CMPedometer`
- Race predictor using Riegel formula (`t₂ = t₁ × (d₂/d₁)^1.06`)
- Treadmill mode: manual distance entry, no GPS requirement
- Weather conditions stored with run (current temp, wind, conditions from on-device CoreLocation + WeatherKit)

### v2.0 — Optional Sync
- iCloud sync via CloudKit (opt-in, disabled by default)
- Share single run summary as image (no social feed, no accounts)
- Configurable metric layouts on Watch (user can reorder the 2 pages)
- Vertical oscillation and ground contact time if Apple exposes via HealthKit/CMMotionActivity

### Deferred (Removed from MVP)
The following were considered and explicitly removed during product review:
- **Social features** — accounts, leaderboards, friends, kudos. Out of scope permanently.
- **Cloud backend** — server sync, remote storage. May revisit as opt-in CloudKit only.
- **Coaching AI** — real-time pace coaching. Adds complexity, deferred to v1.3+.
- **Nutrition/hydration tracking** — scope creep; separate concern.
- **Sleep/recovery data** — HRV and recovery scores exist in HealthKit but are out of scope for a run-first app.
