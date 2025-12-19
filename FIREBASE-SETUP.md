# Firebase Setup Guide for Homebase iOS App

This guide walks you through setting up Firebase for your iOS app.

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: **`Homebase`** (or `homebase-ios` if your web app already uses a Firebase project)
4. Enable Google Analytics (recommended) or skip
5. Click **"Create project"**

## Step 2: Add iOS App to Firebase

1. In your Firebase project, click the **iOS icon** (⊕ Add app → iOS)
2. **Register your app:**
   - **iOS bundle ID**: `com.yourname.Homebase` 
     - ⚠️ **Important**: This must match the Bundle Identifier you'll use in Xcode
     - Use your name/organization, e.g., `com.kevzhg.Homebase`
   - **App nickname** (optional): `Homebase iOS`
   - **App Store ID**: Leave blank for now

3. Click **"Register app"**

## Step 3: Download Configuration File

1. Download the **`GoogleService-Info.plist`** file
2. **Save it** - you'll add it to your Xcode project later
3. **DO NOT commit this file to git** - it's in `.gitignore`
4. Click **"Next"** (we'll add the SDK later)

## Step 4: Enable Firestore Database

1. In Firebase Console, go to **"Build"** → **"Firestore Database"**
2. Click **"Create database"**
3. Choose **"Start in test mode"** for now
   - We'll secure it with authentication later
4. Select a location (choose closest to your users, e.g., `us-central1`)
5. Click **"Enable"**

## Step 5: Enable Authentication (Optional but Recommended)

1. Go to **"Build"** → **"Authentication"**
2. Click **"Get started"**
3. Enable **"Email/Password"** sign-in method
   - This will allow users to have their own data
4. Or choose **"Anonymous"** for now if you want to test without accounts

## Step 6: Firestore Security Rules (Initial Setup)

For development, your Firestore will be in test mode (open for 30 days). Here's what the rules look like:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 2, 1);
    }
  }
}
```

**Before deploying to production**, update to user-based rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 7: Ready for Xcode!

✅ Firebase project created  
✅ iOS app registered  
✅ `GoogleService-Info.plist` downloaded  
✅ Firestore enabled  
✅ Authentication enabled (optional)

**Next**: Create your Xcode project and add the Firebase SDK.

---

## Firestore Data Structure

Your collections will be organized as:

```
/users/{userId}/
  /trainings/{trainingId}
  /meals/{mealId}
  /weightEntries/{entryId}
  /workoutPrograms/{programId}
  
/exercises/{exerciseId}  # Shared exercise library (all users)
```

### Example Training Document

```json
{
  "id": "training_123",
  "date": "2024-12-18",
  "type": "strength",
  "durationMinutes": 45,
  "programName": "Push Day A",
  "exercises": [
    {
      "exerciseId": "bench_press",
      "name": "Bench Press",
      "sets": [
        { "setNumber": 1, "weight": 185, "reps": "8" },
        { "setNumber": 2, "weight": 185, "reps": "7" }
      ]
    }
  ],
  "notes": "Felt strong today",
  "createdAt": "2024-12-18T10:30:00Z"
}
```

## Cost Estimate (Free Tier Limits)

Firebase Spark (Free) Plan includes:
- **Firestore**: 1 GB storage, 50K reads/day, 20K writes/day
- **Authentication**: Unlimited users
- **Hosting**: 10 GB/month

For a single-user fitness app, you'll stay well within free tier limits.

## Troubleshooting

**Q: Can I use my existing web app's Firebase project?**  
A: Yes! Just add an iOS app to your existing project. Web and iOS can share the same Firestore database.

**Q: Do I need a credit card?**  
A: No, the free Spark plan requires no credit card.

**Q: What if I already have data in MongoDB?**  
A: We'll create a migration script later to export from MongoDB and import to Firestore.

