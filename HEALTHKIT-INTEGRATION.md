# Apple Fitness / HealthKit Integration Guide

## Overview
This guide explains how to integrate your Homebase workout app with Apple's Fitness app to track Traditional Strength Training sessions.

## Integration Steps

### 1. ✅ Add HealthKit Capability
- Open Xcode
- Select your project → **HomebaseApp** target → **Signing & Capabilities** tab
- Click **+ Capability**
- Search for and add **HealthKit**

### 2. ✅ Update Info.plist (Privacy Descriptions)

**Modern Xcode Method (Recommended):**

1. In Xcode, select the **HomebaseApp** project (blue icon at top of navigator)
2. Select the **HomebaseApp** target (under "TARGETS")
3. Click the **Info** tab
4. **Right-click anywhere in the white space** under "Custom iOS Target Properties"
5. Select **"Add Row"** from the context menu
6. Type `Privacy - Health Share Usage Description` and press Enter
7. In the **Value** column, enter: `We use HealthKit to track your workout sessions in the Fitness app`
8. **Right-click again** and select **"Add Row"**
9. Type `Privacy - Health Update Usage Description` and press Enter
10. In the **Value** column, enter: `We write workout data to the Fitness app to track your training progress`

**Alternative: Create Info.plist File:**

If you prefer a physical file (or the above doesn't work):

1. Right-click **HomebaseApp** folder (containing `ContentView.swift`)
2. Select **New File...**
3. Choose **Property List** → **Next**
4. Name it `Info.plist` → **Create**
5. Right-click in the file and select **"Add Row"**
6. Add both keys with their values as XML:

```xml
<key>NSHealthShareUsageDescription</key>
<string>We use HealthKit to track your workout sessions in the Fitness app</string>
<key>NSHealthUpdateUsageDescription</key>
<string>We write workout data to the Fitness app to track your training progress</string>
```

### 3. ✅ Files Created/Modified

#### Created:
- **HealthKitService.swift** - Service to manage HealthKit workout sessions
  - `requestAuthorization()` - Request user permission
  - `startWorkoutSession()` - Begin tracking in Fitness app
  - `pauseWorkoutSession()` - Pause tracking
  - `resumeWorkoutSession()` - Resume tracking
  - `endWorkoutSession()` - Complete and save workout

#### Modified:
- **LiveWorkoutViewModel.swift** - Integrated HealthKit calls
  - Requests authorization on init
  - Starts Fitness tracking when workout starts
  - Pauses/resumes Fitness tracking with app
  - Ends Fitness session when workout finishes

### 4. How It Works

#### When User Starts a Workout:
1. User taps "Start" on a workout program
2. App creates `ActiveWorkout` state
3. **HealthKit session starts** → Shows in Fitness app as "Traditional Strength Training"
4. Timer begins counting

#### During the Workout:
- User taps **Pause** → Both app timer and Fitness tracking pause
- User taps **Resume** → Both resume

#### When User Finishes:
1. User completes workout
2. App saves to Firebase
3. **HealthKit session ends** → Workout appears in Fitness app with:
   - Duration
   - Calories burned (estimated by Apple Watch/iPhone)
   - Heart rate data (if available)
   - Activity rings progress

### 5. Testing

#### First Launch:
- When you first start a workout, iOS will prompt for HealthKit permission
- **Allow** access to enable Fitness tracking

#### Check Fitness App:
- Open **Fitness** app on iPhone
- Go to **Summary** tab
- Scroll to **Workouts**
- You should see "Traditional Strength Training" entries for each workout

#### With Apple Watch:
- If wearing Apple Watch, it will automatically track:
  - Heart rate
  - Calories burned
  - Activity rings (Move, Exercise, Stand)

### 6. What Gets Tracked

**Automatically by HealthKit:**
- ✅ Workout duration (start to end time)
- ✅ Workout type (Traditional Strength Training)
- ✅ Calories burned (estimated)
- ✅ Heart rate (if Apple Watch connected)
- ✅ Activity rings progress

**Currently NOT tracked (could be added):**
- Individual exercise details (bench press, squats, etc.)
- Sets and reps per exercise
- Weight lifted per set

### 7. Future Enhancements (Optional)

You could extend the integration to include:

```swift
// Add workout statistics
HKStatisticsQuery for calories burned
HKHeartRateQuery for heart rate zones

// Save individual exercises as metadata
workout.metadata = [
    "exercises": exerciseNames.joined(separator: ","),
    "totalSets": totalSets,
    "totalVolume": totalWeight
]
```

### 8. Privacy & Security

- HealthKit data **never leaves the device** (not synced to iCloud by default)
- User has full control over what data apps can access
- User can revoke permission anytime in Settings → Privacy & Security → Health

### 9. Build & Run

1. Make sure you've added the **HealthKit capability**
2. Added the **privacy descriptions to Info.plist**
3. Build and run on a **physical device** (Simulator has limited HealthKit support)
4. Start a workout
5. Grant permission when prompted
6. Complete the workout
7. Check the Fitness app!

## Troubleshooting

**Permission Denied:**
- Go to Settings → Privacy & Security → Health → HomebaseApp
- Enable all permissions

**Session Not Starting:**
- Check Xcode console for error messages
- Ensure you're testing on a physical device (not simulator)
- Verify HealthKit capability is properly configured

**Workout Not Appearing in Fitness:**
- Ensure workout was finished (not just stopped)
- Check that `endWorkoutSession()` was called
- Allow a few seconds for Fitness app to refresh

## Summary

Your app now fully integrates with Apple Fitness! When users start a workout in your app:
1. It appears in real-time in the Fitness app
2. Counts toward Activity rings
3. Tracks heart rate and calories (with Apple Watch)
4. Builds a complete workout history in Apple Health

This provides users with a native Apple ecosystem experience while using your custom workout builder and tracking features.
