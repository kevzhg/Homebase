# Homebase iOS App - Project Context

## 🎯 Project Goal

Convert the existing Homebase fitness tracking web application (TypeScript/Express/MongoDB) into a native iOS app using Swift + SwiftUI, with backend migration to Firebase (Firestore + FirebaseAuth).

## 📋 Current Status

### ✅ Completed Features

1. **Project Setup**
   - ✅ Xcode project created in `HomebaseApp/` subdirectory
   - ✅ Git repository structure established (iOS app in subdirectory, web app remains at root)
   - ✅ Firebase iOS SDK integrated via Swift Package Manager
   - ✅ Firebase project configured with custom database named "homedb"
   - ✅ GoogleService-Info.plist added to project

2. **Data Models (Swift)**
   - ✅ `Training.swift` - Workout session tracking model
   - ✅ `Meal.swift` - Meal tracking model
   - ✅ `WeightEntry.swift` - Weight tracking model
   - ✅ `WorkoutProgram.swift` - Workout program templates
   - ✅ `Exercise.swift` - Exercise definitions
   - ✅ All models use `Codable` for Firestore serialization
   - ✅ Manual document ID handling (no `@DocumentID` wrapper)

3. **Firebase Integration**
   - ✅ `FirebaseService.swift` - Centralized Firebase operations
   - ✅ Real-time listeners for all data types (trainings, meals, weight entries, workout programs, exercise library)
   - ✅ CRUD operations for all data types
   - ✅ Firestore security rules configured for `default_user` (development)
   - ✅ Offline persistence enabled with `PersistentCacheSettings()`
   - ✅ Custom database connection: `Firestore.firestore(database: "homedb")`

4. **UI Components**
   - ✅ `DashboardView.swift` - Main dashboard with today's summary and weekly stats
   - ✅ `LiveWorkoutView.swift` - Main container for live workout feature
   - ✅ `WorkoutProgramsView.swift` - List of saved workout programs
   - ✅ `WorkoutBuilderView.swift` - Create/edit workout programs
   - ✅ `ActiveWorkoutView.swift` - Active workout session tracking
   - ✅ `RestTimerOverlay.swift` - Rest timer countdown overlay
   - ✅ Tab-based navigation (Dashboard + Live Workout)

5. **Live Workout Feature**
   - ✅ `LiveWorkoutViewModel.swift` - Complete state management for live workouts
   - ✅ Program selection, editing, cloning, deletion
   - ✅ Workout builder with exercise library
   - ✅ Active workout session with set tracking
   - ✅ Rest timer functionality
   - ✅ Default programs (Push/Pull/Legs) defined in `DefaultPrograms.swift`

6. **Utilities**
   - ✅ `Logger.swift` - Structured logging with OSLog and timestamps
   - ✅ Logging categories: app, ui, data, network, firebase, liveWorkout

### 🚧 Current Issues / In Progress

1. **Build Errors (Resolved but needs verification)**
   - Fixed brace structure in `WorkoutBuilderView.swift`
   - Need to verify clean build succeeds

2. **Scrolling Issues**
   - Fixed `WorkoutBuilderView` scrolling by removing `GeometryReader`
   - Fixed `WorkoutProgramsView` scrolling with proper padding
   - May need further testing

3. **Workout Programs Not Displaying**
   - Fixed Firestore decoding (removed optional chaining on non-optional)
   - Added debug logging to track program loading
   - Programs save successfully but may not display in "Start Training" tab
   - Need to verify filtering logic in `WorkoutProgramsView`

### 📝 Known Issues / Technical Debt

1. **Authentication**
   - Currently using hardcoded `default_user` for all operations
   - Need to implement Firebase Authentication
   - Security rules need update for production (user-based access)

2. **Data Migration**
   - MongoDB data not yet migrated to Firestore
   - Need migration script if web app data should be preserved

3. **UI/UX Polish**
   - Keyboard dismissal could be improved
   - Some views may need better empty states
   - Dark mode support (should work automatically with SwiftUI)

## 🏗️ Architecture

### Project Structure
```
Homebase/
├── HomebaseApp/                    # iOS app
│   └── HomebaseApp/
│       ├── HomebaseAppApp.swift    # App entry point
│       ├── Models/                 # Data models
│       ├── Views/                  # SwiftUI views
│       │   ├── Dashboard/
│       │   └── LiveWorkout/
│       ├── ViewModels/             # MVVM view models
│       ├── Services/               # Firebase service
│       └── Utils/                  # Utilities (Logger, etc.)
├── src/                            # Web app (TypeScript)
└── [other web app files]
```

### Design Patterns
- **MVVM (Model-View-ViewModel)** - Separation of concerns
- **ObservableObject** - Reactive state management with `@Published`
- **Combine** - Reactive programming for data streams
- **Singleton Pattern** - `FirebaseService.shared`

### Data Flow
1. User interacts with SwiftUI View
2. View calls ViewModel methods
3. ViewModel calls FirebaseService
4. FirebaseService updates Firestore
5. Real-time listeners update ViewModel's `@Published` properties
6. SwiftUI automatically updates View

## 🔧 Technical Details

### Firebase Configuration
- **Project**: Homebase (or homebase-ios)
- **Database**: Named database "homedb" (not default)
- **Collections Structure**:
  ```
  users/
    default_user/
      trainings/{trainingId}
      meals/{mealId}
      weightEntries/{entryId}
      workoutPrograms/{programId}
  exercises/{exerciseId}  # Shared library
  ```

### Firestore Security Rules (Development)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/default_user/{document=**} {
      allow read, write: if true;
    }
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /exercises/{exerciseId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Key Dependencies
- Firebase iOS SDK (via Swift Package Manager)
- FirebaseAuth
- FirebaseFirestore
- SwiftUI (iOS 15+)

## 📚 Reference Files

### Web App Source (for reference)
- `src/liveWorkout.ts` - Original live workout logic
- `src/types.ts` - TypeScript type definitions
- `src/storage.ts` - Data persistence logic

### Documentation Files
- `FIREBASE-SETUP.md` - Firebase setup instructions
- `IOS-SETUP-INSTRUCTIONS.md` - Xcode project setup
- `LIVE-WORKOUT-GUIDE.md` - Live workout feature guide
- `LIVE-WORKOUT-SUMMARY.md` - Live workout implementation summary
- `FIRESTORE-RULES-FIX.md` - Firestore security rules guide

## 🎯 Next Steps / TODO

### Immediate (High Priority)
1. ✅ Fix build errors in `WorkoutBuilderView.swift` (DONE - needs verification)
2. ✅ Fix scrolling issues (DONE - needs testing)
3. ⏳ Verify workout programs display correctly in "Start Training" tab
4. ⏳ Test complete workout flow: create program → start workout → complete sets → save training

### Short Term
1. Implement Firebase Authentication
   - Replace `default_user` with authenticated user ID
   - Update security rules for production
   - Add login/signup UI

2. Complete core features
   - Meal tracking UI
   - Weight tracking UI
   - Training history view

3. Data migration (if needed)
   - Export from MongoDB
   - Import to Firestore
   - Verify data integrity

### Long Term
1. App Store preparation
   - App icons and launch screens
   - Privacy policy
   - App Store listing
   - TestFlight beta testing

2. Feature parity with web app
   - All web app features ported
   - iOS-specific enhancements

## 🤖 AI Agent Context Prompt

**When continuing work on this project, read this file first to understand:**

1. **Project Goal**: Converting TypeScript web app to native iOS Swift/SwiftUI app with Firebase backend
2. **Current State**: Core infrastructure complete, Live Workout feature implemented, some UI/scrolling issues being resolved
3. **Architecture**: MVVM pattern, FirebaseService singleton, real-time listeners
4. **Key Files**: 
   - `FirebaseService.swift` - All Firebase operations
   - `LiveWorkoutViewModel.swift` - Live workout state management
   - `WorkoutBuilderView.swift` - Workout creation UI
   - `WorkoutProgramsView.swift` - Program listing UI
5. **Known Issues**: Check "Current Issues" section above
6. **Database**: Uses named database "homedb", not default
7. **User ID**: Currently hardcoded as "default_user" (needs authentication)

**When making changes:**
- Follow existing MVVM pattern
- Use `FirebaseService.shared` for all Firestore operations
- Add logging using `logInfo()`, `logError()`, etc. from `Logger.swift`
- Test scrolling on both "Start Training" and "Build Training" tabs
- Verify Firestore security rules allow operations
- Check that programs are properly decoded (no optional chaining on non-optional values)

**Common Gotchas:**
- Firestore document IDs must be manually assigned after decoding
- Use `PersistentCacheSettings()` not `isPersistenceEnabled` (deprecated)
- ScrollView needs proper padding for tab bar (120pt bottom padding)
- Remove `GeometryReader` if it conflicts with ScrollView gestures
- Programs filter by `ProgramType` enum - ensure `name` field matches enum cases

---

**Last Updated**: 2024-12-19
**Current Focus**: Fixing build errors and verifying scrolling functionality

