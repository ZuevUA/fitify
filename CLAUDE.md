# Fitify - AI Health & Fitness Companion

## Project Overview
Fitify is a health & fitness iOS app that analyzes Apple Watch data using AI to provide personalized health insights, recovery recommendations, and early warning signs for potential health issues.

## Tech Stack
- **Language:** Swift 5.9
- **UI Framework:** SwiftUI (iOS 17+)
- **Target Device:** iPhone (iOS 17 Pro and later)
- **Architecture:** MVVM with @Observable ViewModels

### Core Frameworks
- **HealthKit** - Read AND write health metrics from Apple Watch
- **SwiftData** - Local cache for AI insights
- **URLSession** - Claude API calls via proxy server
- **StoreKit 2** - Subscription management

## Project Structure
```
Fitify/
├── Features/
│   ├── Dashboard/      # Main dashboard with recovery score
│   ├── Sleep/          # Sleep analysis and trends
│   ├── Activity/       # Activity metrics and goals
│   ├── Workout/        # Workout journal with AI recommendations
│   │   ├── Onboarding/ # 13-screen workout onboarding flow
│   │   ├── Models/     # UserProfile, WorkoutProgram, Exercise, etc.
│   │   ├── Views/      # WorkoutHomeView, ActiveWorkoutView, etc.
│   │   └── ViewModels/ # WorkoutOnboardingViewModel
│   └── Insights/       # AI-generated health insights
├── Services/
│   ├── HealthKitService.swift   # HealthKit data access
│   ├── LLMService.swift         # Claude API integration
│   └── StorageService.swift     # SwiftData persistence
├── Models/
│   ├── HealthSnapshot.swift     # Point-in-time health data
│   ├── AIInsight.swift          # SwiftData @Model for insights
│   └── HealthMetrics.swift      # Health metric types
└── Utils/
    ├── HealthCalculations.swift # Recovery score, stress calc
    └── Extensions.swift         # Swift/SwiftUI extensions

backend/                    # Node.js backend for Claude API
├── package.json           # Dependencies
├── server.js              # Express server with API endpoints
└── .env                   # Environment variables (API key)
```

## Development Rules

### Privacy & Security (CRITICAL)
- **NEVER log medical/health data** - No print(), os_log(), or analytics for health metrics
- **NEVER send health data to own servers** - Only processed through Claude API proxy
- **All health data stays on device** - SwiftData cache is local only
- **No third-party analytics SDKs** that could capture health data

### Architecture Guidelines
- Use `@Observable` macro for ViewModels (iOS 17+)
- One ViewModel per Feature module
- Services are singletons accessed via dependency injection
- Views should be thin - logic lives in ViewModels

### HealthKit Best Practices
- Always check authorization status before queries
- Handle denied permissions gracefully with user guidance
- Use background delivery for overnight data sync
- Batch queries to minimize battery impact

### Code Style
- Swift strict concurrency mode enabled
- Use async/await for all asynchronous operations
- Prefer value types (structs) over reference types
- Use SwiftUI's native dark mode support

### Testing
- Unit tests for ViewModels and Services
- UI tests for critical user flows
- Mock HealthKit data for simulator testing

## HealthKit Metrics
Reading AND writing the following:
- Heart Rate (HKQuantityTypeIdentifier.heartRate)
- HRV SDNN (HKQuantityTypeIdentifier.heartRateVariabilitySDNN)
- Body Temperature (HKQuantityTypeIdentifier.bodyTemperature)
- Blood Oxygen (HKQuantityTypeIdentifier.oxygenSaturation)
- Step Count (HKQuantityTypeIdentifier.stepCount)
- Active Energy (HKQuantityTypeIdentifier.activeEnergyBurned)
- Sleep Analysis (HKCategoryTypeIdentifier.sleepAnalysis)
- Resting Heart Rate (HKQuantityTypeIdentifier.restingHeartRate)

## Build Commands
```bash
# Build
xcodebuild -scheme Fitify -configuration Debug build

# Test
xcodebuild -scheme Fitify -configuration Debug test

# Run on simulator
xcrun simctl boot "iPhone 15 Pro"
xcodebuild -scheme Fitify -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

## Environment Variables
- `FITIFY_API_URL` - Backend server URL (default: http://localhost:3000)
- Configure in scheme environment variables, NOT in code

## Backend Setup

The backend provides Claude API integration for AI-powered health insights.

### Requirements
- Node.js 18+
- Anthropic API key (https://console.anthropic.com/)

### Setup & Run
```bash
cd backend

# Install dependencies
npm install

# Configure API key
# Edit .env and set ANTHROPIC_API_KEY=your_api_key_here

# Start server
npm start      # Production
npm run dev    # Development (with auto-reload)
```

### API Endpoints

**POST /api/analyze**
Generate AI health insight from health data.
```json
{
  "healthData": {
    "restingHeartRate": 58,
    "hrv": 45,
    "sleepHours": 7.5,
    "steps": 8500,
    "activeCalories": 420,
    "stressLevel": 35,
    "recoveryScore": 78
  }
}
```

**POST /api/virus-check**
Assess illness risk based on health metrics.
```json
{
  "healthData": {
    "restingHeartRate": 65,
    "hrv": 32,
    "bodyTemperature": 37.2,
    "oxygenSaturation": 96,
    "sleepQuality": 58
  }
}
```

**GET /health**
Health check endpoint.

**POST /api/generate-program**
Generate AI workout program based on Jeff Nippard methodology.
```json
{
  "userProfile": {
    "goal": "buildMuscle|loseFat|strength|recomp",
    "experience": "beginner|intermediate|advanced",
    "gender": "male|female|other",
    "age": 25,
    "weightKg": 70,
    "trainingDaysPerWeek": 4,
    "sessionDurationMinutes": 60,
    "priorityMuscles": ["chest", "biceps"],
    "calculatedWeeklyVolume": 14,
    "sleepHours": "under5|fiveToSeven|over7"
  }
}
```

**POST /api/workout-recommendation**
Get AI recommendations after completing a workout.
```json
{
  "workoutLog": {
    "workoutDayName": "Push A",
    "durationMinutes": 55,
    "totalVolume": 4500,
    "completedSets": [
      {"exerciseName": "Bench Press", "weightKg": 80, "reps": 8, "rir": 2}
    ]
  },
  "previousWorkout": { ... },
  "userProfile": { ... }
}
```

## Workout Feature

### Jeff Nippard Methodology
The workout feature implements evidence-based training principles:
- **Progressive Overload**: Weekly weight/rep increases
- **Optimal Volume**: 10-20 sets/muscle/week based on experience
- **Frequency**: Each muscle trained 2x/week
- **Rep Ranges**: Strength (1-5), Hypertrophy (6-12), Endurance (12-20)
- **RIR (Reps In Reserve)**: Train 1-3 reps from failure
- **Deload**: Every 4-6 weeks

### SwiftData Models
- `UserProfile` - Training preferences and stats
- `WorkoutProgram` - Generated program with days/exercises
- `WorkoutDay` - Single training day
- `Exercise` - Individual exercise with sets/reps/RIR
- `WorkoutLog` - Completed workout record
- `CompletedSet` - Individual set record
- `WorkoutRecommendation` - AI advice for progression
