# iOS App Setup Instructions

This guide walks you through creating the Xcode project for Homebase iOS.

## Prerequisites

- macOS with Xcode 15+ installed
- Apple ID (free - no paid developer account needed for local testing)
- Completed [FIREBASE-SETUP.md](FIREBASE-SETUP.md) and have `GoogleService-Info.plist` ready

## Step 1: Create Xcode Project

1. **Open Xcode**
2. Click **"Create New Project"** (or File → New → Project)
3. Choose **iOS** → **App** template
4. Click **Next**

## Step 2: Configure Project Settings

Fill in the project details:

- **Product Name**: `HomebaseApp`
- **Team**: Select your Apple ID (or "None" for now)
- **Organization Identifier**: `com.yourname` (e.g., `com.kevzhg`)
  - ⚠️ **Must match** the Bundle ID you used in Firebase setup
- **Bundle Identifier**: Will auto-generate as `com.yourname.HomebaseApp`
- **Interface**: **SwiftUI** ✅
- **Language**: **Swift** ✅
- **Storage**: **None** (we're using Firebase)
- **Include Tests**: ✅ (optional but recommended)

Click **Next**

## Step 3: Save Project Location

**Important**: Save the project in your Homebase repo:

1. Navigate to: `/Users/kz/Documents/Projects/Homebase/`
2. The project will create a folder called `HomebaseApp/`
3. **Uncheck** "Create Git repository" (we already have one)
4. Click **Create**

Your structure will now look like:
```
Homebase/
├── src/              # Existing web app
├── HomebaseApp/      # New iOS project ← Created by Xcode
│   ├── HomebaseApp.xcodeproj
│   └── HomebaseApp/
│       ├── HomebaseAppApp.swift
│       ├── ContentView.swift
│       └── Assets.xcassets
├── package.json
└── ...
```

## Step 4: Add Firebase SDK

1. In Xcode, select your project in the navigator (top-level "HomebaseApp")
2. Select the **HomebaseApp** target
3. Go to **"Package Dependencies"** tab
4. Click the **"+"** button
5. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
6. Click **"Add Package"**
7. Select these products:
   - ✅ **FirebaseAuth**
   - ✅ **FirebaseFirestore**
   - ✅ **FirebaseFirestoreSwift**
8. Click **"Add Package"**

Wait for Swift Package Manager to download dependencies (~1-2 minutes).

## Step 5: Add GoogleService-Info.plist

1. Locate your downloaded `GoogleService-Info.plist` file
2. **Drag and drop** it into Xcode's project navigator
3. In the dialog:
   - ✅ **"Copy items if needed"**
   - ✅ **"Add to targets: HomebaseApp"**
4. Click **Finish**

**Verify**: The file should appear in your project navigator under HomebaseApp.

## Step 6: Initialize Firebase in App

1. Open `HomebaseAppApp.swift`
2. Add Firebase import at the top:
   ```swift
   import SwiftUI
   import FirebaseCore
   ```
3. Add Firebase initialization in the app initializer:
   ```swift
   @main
   struct HomebaseAppApp: App {
       init() {
           FirebaseApp.configure()
       }
       
       var body: some Scene {
           WindowGroup {
               ContentView()
           }
       }
   }
   ```

## Step 7: Create Project Structure

In Xcode, create these folders (File → New → Group):

```
HomebaseApp/
├── Models/          # Data models (Training, Meal, etc.)
├── Views/           # SwiftUI views
│   ├── Dashboard/
│   ├── LiveWorkout/
│   ├── Workouts/
│   ├── Meals/
│   └── Weight/
├── ViewModels/      # View logic and state management
├── Services/        # FirebaseService, etc.
└── Utils/           # Helper functions, extensions
```

**To create a group**: Right-click HomebaseApp folder → New Group

## Step 8: Test the Setup

1. Select a simulator (e.g., iPhone 15 Pro)
2. Click **Run** (▶️) or press `Cmd + R`
3. App should launch showing "Hello, world!"

If it builds successfully, you're ready to start coding! ✅

## Step 9: Create Initial Files

I'll create the following Swift files for you:
- `Models/Training.swift` - Data models
- `Models/Meal.swift`
- `Models/WeightEntry.swift`
- `Services/FirebaseService.swift` - Firebase integration
- `Views/Dashboard/DashboardView.swift` - Main dashboard

After creating these files in your repo, you'll need to **add them to Xcode**:
1. Right-click the appropriate folder in Xcode
2. Choose "Add Files to HomebaseApp..."
3. Select the file(s) you want to add
4. Ensure "Add to targets: HomebaseApp" is checked

## Troubleshooting

**"No such module 'FirebaseCore'"**
- Clean build folder: Product → Clean Build Folder
- Restart Xcode

**"GoogleService-Info.plist not found"**
- Verify the file is in your project navigator
- Check it's added to the HomebaseApp target

**Build errors about minimum deployment target**
- Select project → HomebaseApp target → General
- Set "Minimum Deployments" to iOS 16.0 or higher

## Next Steps

Once your Xcode project is set up, I'll create the Swift files with:
- Data models matching your TypeScript types
- Firebase service for CRUD operations
- Initial dashboard view

**Let me know when you've completed the Xcode setup!** 🚀

