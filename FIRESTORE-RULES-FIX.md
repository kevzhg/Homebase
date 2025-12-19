# Fix Firestore Permission Error

## Problem
You're getting this error when saving workouts:
```
Permission denied: Missing or insufficient permissions.
Write at users/default_user/workoutPrograms/... failed
```

## Solution: Update Firestore Security Rules

### Step 1: Open Firestore Rules in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **Homebase** project
3. Click **"Build"** → **"Firestore Database"**
4. Click the **"Rules"** tab at the top

### Step 2: Update Rules for Development

**For development/testing** (allows `default_user` to read/write):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow default_user to read/write their own data
    match /users/default_user/{document=**} {
      allow read, write: if true;
    }
    
    // Allow authenticated users to read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Shared exercise library - allow all for development
    match /exercises/{exerciseId} {
      allow read, write: if true; // Allow all during development
      // For production: allow write: if request.auth != null;
    }
  }
}
```

### Step 3: Publish Rules

1. Click **"Publish"** button at the top
2. Wait a few seconds for rules to deploy
3. Try saving a workout again in your app

## Alternative: Temporary Test Mode (NOT RECOMMENDED FOR PRODUCTION)

If you just want to test quickly, you can temporarily use test mode:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **WARNING**: This allows anyone to read/write your entire database. Only use for testing, and change it back immediately!

## For Production (After Adding Authentication)

Once you implement user authentication, use these secure rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Shared exercise library
    match /exercises/{exerciseId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## Verify It Works

After updating rules:
1. Save a workout in your app
2. Check Firebase Console → Firestore Database → Data
3. You should see: `users/default_user/workoutPrograms/{programId}`

## Next Steps

- ✅ Rules updated → You can now save workouts
- 🔄 Later: Implement Firebase Authentication to replace `default_user`
- 🔄 Later: Update rules to use authenticated user IDs

