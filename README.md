# PACE — Personal Running Experience

A Watch-first solo running app for iPhone and Apple Watch.

## Requirements

- Xcode 15+
- iOS 17+ target device or simulator
- watchOS 10+ target device or simulator
- Swift 5.9+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for project generation)

## Setup

### 1. Install XcodeGen

```bash
brew install xcodegen
```

### 2. Generate the Xcode project

```bash
cd path/to/PACE
xcodegen generate
```

### 3. Open in Xcode

```bash
open PACE.xcodeproj
```

### 4. Configure signing

In Xcode, select the PACE and PACEWatch targets and set your Team in Signing & Capabilities.

### 5. Build & Run

- Select the **PACE** scheme for the iPhone app
- Select the **PACEWatch** scheme for the Watch app
- Run on a real device for GPS and HealthKit (simulators don't support GPS)

---

## Project Structure

```
PACE/
├── project.yml               # XcodeGen configuration
├── PACE/                     # iOS App
│   ├── PACEApp.swift         # App entry point
│   ├── Models/               # SwiftData models
│   │   ├── Enums.swift
│   │   ├── User.swift
│   │   ├── Run.swift
│   │   ├── Split.swift
│   │   ├── Goal.swift
│   │   ├── Achievement.swift
│   │   └── HealthMetricSnapshot.swift
│   ├── Services/             # Business logic
│   │   ├── RunService.swift       # Run state machine
│   │   ├── LocationManager.swift  # GPS + pace calculation
│   │   ├── HealthKitManager.swift # HealthKit read/write
│   │   ├── GoalService.swift      # Goal tracking
│   │   └── AnalyticsEngine.swift  # Post-run insights
│   ├── DesignSystem/
│   │   ├── PACEColors.swift
│   │   ├── PACEFonts.swift
│   │   ├── PACESpacing.swift
│   │   └── PACEComponents.swift
│   ├── Views/
│   │   ├── RootView.swift
│   │   ├── Onboarding/
│   │   ├── Home/
│   │   ├── Run/              # Countdown, Active Run, Pause
│   │   ├── Summary/
│   │   ├── History/
│   │   ├── Goals/
│   │   └── Settings/
│   ├── Utilities/
│   │   ├── Formatters.swift
│   │   └── Extensions.swift
│   └── Resources/
│       └── Info.plist
└── PACEWatch/                # watchOS App
    ├── PACEWatchApp.swift
    ├── Services/
    │   └── WatchRunService.swift
    ├── Views/
    │   ├── WatchHomeView.swift
    │   ├── WatchActiveRunView.swift
    │   ├── WatchPauseView.swift
    │   └── WatchSummaryView.swift
    └── Resources/
        └── Info.plist
```

---

## Architecture

- **Local-first**: SwiftData, no network required
- **Watch-first UX**: Watch runs independently via HKWorkoutSession
- **HealthKit**: Writes HKWorkout on completion, reads live HR
- **RunService state machine**: `.idle → .countdown → .active → .paused → .ended`

## Design System

| Token | Value |
|---|---|
| Background | `#0A0A0A` |
| Surface | `#141414` |
| Accent Cyan | `#00D4FF` |
| Accent Orange | `#FF6B35` |
| Primary Font | SF Pro Rounded |

## MVP Sprint Plan

| Sprint | Focus | Duration |
|---|---|---|
| 1 | Models, RunService, LocationManager, ActiveRunView | 2 weeks |
| 2 | Watch app, WorkoutKit, sync | 2 weeks |
| 3 | Summary, History, HealthKit write | 2 weeks |
| 4 | Countdown, audio cues, haptics | 1 week |
| 5 | Onboarding, Settings, GPX export | 1 week |
| 6 | Goals, insights, weekly chart | 1 week |
| 7 | QA, edge cases, App Store submission | 1 week |
