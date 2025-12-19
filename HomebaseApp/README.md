# Homebase iOS App

Native iOS fitness tracking app built with SwiftUI and Firebase.

## 🎯 Features

- **Dashboard**: Today's summary and weekly progress
- **Live Workout**: Real-time workout tracking with rest timers
- **Training Tracker**: Log and view workout sessions
- **Meal Tracking**: Track meals with calories and protein
- **Weight Calendar**: Visual calendar with weight entries and statistics

## 🛠 Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Backend**: Firebase (Firestore + Auth)
- **Minimum iOS**: 16.0
- **Architecture**: MVVM with Combine

## 📁 Project Structure

```
HomebaseApp/
├── Models/              # Data models (Training, Meal, WeightEntry)
├── Views/               # SwiftUI views
│   ├── Dashboard/       # Dashboard view
│   ├── LiveWorkout/     # Live workout builder & runner
│   ├── Workouts/        # Training history
│   ├── Meals/           # Meal tracking
│   └── Weight/          # Weight calendar
├── ViewModels/          # View models for state management
├── Services/            # Firebase service layer
└── Utils/               # Helper functions and extensions
```

## 🚀 Getting Started

### Prerequisites

- macOS 13.0+ with Xcode 15+
- Apple ID (free account works for testing)
- Firebase project (see [FIREBASE-SETUP.md](../FIREBASE-SETUP.md))

### Setup Instructions

1. **Follow Firebase setup**: Complete steps in `../FIREBASE-SETUP.md`

2. **Create Xcode project**: Follow `../IOS-SETUP-INSTRUCTIONS.md`

3. **Add Swift files to Xcode**:
   - Open `HomebaseApp.xcodeproj` in Xcode
   - Right-click folders and select "Add Files to HomebaseApp..."
   - Add all `.swift` files from `Models/`, `Services/`, and `Views/`

4. **Add Firebase SDK**:
   - In Xcode: File → Add Package Dependencies
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Select: FirebaseAuth, FirebaseFirestore, FirebaseFirestoreSwift

5. **Add GoogleService-Info.plist**:
   - Drag your downloaded `GoogleService-Info.plist` into Xcode
   - Ensure "Copy items if needed" is checked

6. **Initialize Firebase** in `HomebaseAppApp.swift`:
   ```swift
   import SwiftUI
   import FirebaseCore

   @main
   struct HomebaseAppApp: App {
       init() {
           FirebaseApp.configure()
       }
       
       var body: some Scene {
           WindowGroup {
               DashboardView()
                   .onAppear {
                       FirebaseService.shared.startListening()
                   }
           }
       }
   }
   ```

7. **Build and run**: Select a simulator and press `Cmd + R`

## 📊 Data Models

### Training
Workout sessions with exercises, sets, reps, and duration.

### Meal
Meal entries with name, type, calories, and protein.

### WeightEntry
Daily weight logs with notes and trend calculations.

### WorkoutProgram
Saved workout templates for live training sessions.

## 🔥 Firebase Structure

```
/users/{userId}/
  /trainings/{trainingId}
  /meals/{mealId}
  /weightEntries/{entryId}
  /workoutPrograms/{programId}

/exercises/{exerciseId}  # Shared exercise library
```

## 🔐 Authentication

Currently using a default user ID for testing. To add authentication:

1. Enable Firebase Authentication in console
2. Update `FirebaseService.userId` to use `Auth.auth().currentUser?.uid`
3. Add login/signup views

## 📱 Screens Status

- ✅ Dashboard - Complete
- 🚧 Live Workout - In progress
- 🚧 Workouts List - Planned
- 🚧 Meal Tracking - Planned
- 🚧 Weight Calendar - Planned

## 🎨 Design System

- **Colors**: System colors with dark mode support
- **Typography**: SF Pro (system font)
- **Spacing**: 8pt grid system
- **Corner Radius**: 12pt for cards

## 🧪 Testing

Run tests with `Cmd + U` in Xcode.

## 📝 TODO

- [ ] Implement Live Workout view
- [ ] Add workout builder
- [ ] Create meal tracking views
- [ ] Build weight calendar
- [ ] Add Firebase Authentication
- [ ] Implement data migration script
- [ ] Add unit tests
- [ ] Add UI tests

## 🤝 Contributing

This is a personal project, but suggestions are welcome!

## 📄 License

MIT License - see parent project README

