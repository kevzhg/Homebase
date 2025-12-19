# Live Workout Feature - Implementation Guide

## ✅ What's Been Created

I've built the core foundation for the Live Workout feature:

### 1. ViewModel (`LiveWorkoutViewModel.swift`) ✅
**Location**: `ViewModels/LiveWorkoutViewModel.swift`

**Features:**
- ✅ Workout program management
- ✅ Active workout state tracking
- ✅ Workout timer (counts up during session)
- ✅ Rest timer (counts down between sets)
- ✅ Set completion tracking
- ✅ State persistence (resume workouts after app restart)
- ✅ Integration with FirebaseService

### 2. Main View (`LiveWorkoutView.swift`) ✅
**Location**: `Views/LiveWorkout/LiveWorkoutView.swift`

**Features:**
- ✅ Tab navigation (Start Training / Build Training)
- ✅ Switches between program list and active workout
- ✅ Header with description
- ✅ Rest timer overlay integration

### 3. Rest Timer (`RestTimerOverlay.swift`) ✅
**Location**: `Views/LiveWorkout/RestTimerOverlay.swift`

**Features:**
- ✅ Full-screen countdown overlay
- ✅ Add 30s button
- ✅ Skip rest button
- ✅ Large, readable timer display

## 🚧 Still Need to Create

You need to create these 3 additional views:

### 1. WorkoutProgramsView (REQUIRED)
**File**: `Views/LiveWorkout/WorkoutProgramsView.swift`

**Purpose**: List of saved workout programs (Push/Pull/Legs)

**Minimal Implementation:**
```swift
import SwiftUI

struct WorkoutProgramsView: View {
    @ObservedObject var viewModel: LiveWorkoutViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.workoutPrograms.isEmpty {
                    Text("No programs yet. Build your first workout!")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.workoutPrograms) { program in
                        ProgramCard(program: program, viewModel: viewModel)
                    }
                }
            }
            .padding()
        }
    }
}

struct ProgramCard: View {
    let program: WorkoutProgram
    @ObservedObject var viewModel: LiveWorkoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(program.displayName)
                    .font(.headline)
                Spacer()
                Text("\(program.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Actions
            HStack {
                Button("Start") {
                    viewModel.startWorkout(programId: program.id ?? "")
                }
                .buttonStyle(.borderedProminent)
                
                Button("Edit") {
                    viewModel.enterEditMode(program: program)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Delete") {
                    Task {
                        if let id = program.id {
                            await viewModel.deleteProgram(id)
                        }
                    }
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

### 2. WorkoutBuilderView (REQUIRED)
**File**: `Views/LiveWorkout/WorkoutBuilderView.swift`

**Purpose**: Create/edit workout programs

**Minimal Implementation:**
```swift
import SwiftUI

struct WorkoutBuilderView: View {
    @ObservedObject var viewModel: LiveWorkoutViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Name input
                TextField("Workout Name", text: $viewModel.builderName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                // Category picker
                Picker("Category", selection: $viewModel.builderCategory) {
                    ForEach(ProgramType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Exercises list
                if viewModel.builderExercises.isEmpty {
                    Text("No exercises added yet")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.builderExercises.indices, id: \.self) { index in
                        ExerciseRow(exercise: viewModel.builderExercises[index])
                    }
                }
                
                // Save button
                Button("Save Workout") {
                    Task {
                        await viewModel.saveProgram()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(.subheadline)
                Text("\(exercise.sets) × \(exercise.reps) • \(exercise.restTime)s rest")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
```

### 3. ActiveWorkoutView (REQUIRED)
**File**: `Views/LiveWorkout/ActiveWorkoutView.swift`

**Purpose**: Active workout session with exercise list and set tracking

**Minimal Implementation:**
```swift
import SwiftUI

struct ActiveWorkoutView: View {
    @ObservedObject var viewModel: LiveWorkoutViewModel
    let activeWorkout: ActiveWorkout
    
    var body: some View {
        VStack {
            // Header with timer
            HStack {
                Text(activeWorkout.programName)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(viewModel.workoutDuration)
                    .font(.title3)
                    .monospaced()
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Exercises list
            ScrollView {
                ForEach(activeWorkout.exercises.indices, id: \.self) { exIndex in
                    ExerciseCard(
                        viewModel: viewModel,
                        exerciseIndex: exIndex,
                        activeWorkout: activeWorkout
                    )
                }
            }
            
            // Controls
            HStack(spacing: 16) {
                Button(activeWorkout.paused ? "Resume" : "Pause") {
                    viewModel.pauseWorkout()
                }
                .buttonStyle(.bordered)
                
                Button("Finish") {
                    Task {
                        await viewModel.finishWorkout()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
        }
    }
}

struct ExerciseCard: View {
    @ObservedObject var viewModel: LiveWorkoutViewModel
    let exerciseIndex: Int
    let activeWorkout: ActiveWorkout
    
    var body: some View {
        let activeExercise = activeWorkout.exercises[exerciseIndex]
        let isActive = exerciseIndex == activeWorkout.currentExerciseIndex
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise \(exerciseIndex + 1)")
                .font(.headline)
            
            ForEach(activeExercise.sets) { set in
                SetRow(
                    set: set,
                    exerciseIndex: exerciseIndex,
                    isActive: isActive && set.setNumber == activeExercise.currentSet + 1,
                    viewModel: viewModel
                )
            }
        }
        .padding()
        .background(isActive ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct SetRow: View {
    let set: ExerciseSet
    let exerciseIndex: Int
    let isActive: Bool
    @ObservedObject var viewModel: LiveWorkoutViewModel
    @State private var weight: String = ""
    @State private var reps: String = ""
    
    var body: some View {
        HStack {
            Text("Set \(set.setNumber)")
                .font(.subheadline)
            
            if set.completed {
                Spacer()
                Text("✓ Done")
                    .foregroundColor(.green)
                if let w = set.weight {
                    Text("\(Int(w)) lbs")
                        .font(.caption)
                }
            } else if isActive {
                TextField("Weight", text: $weight)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                
                TextField("Reps", text: $reps)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                
                Button("Complete") {
                    Task {
                        let w = Double(weight)
                        await viewModel.completeSet(
                            exerciseIndex: exerciseIndex,
                            setIndex: set.setNumber - 1,
                            weight: w,
                            reps: reps
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Spacer()
                Text("Locked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

## 🚀 Integration Steps

### 1. Add Files to Xcode

1. Open Xcode
2. Right-click appropriate folders:
   - `ViewModels` → Add `LiveWorkoutViewModel.swift`
   - `Views/LiveWorkout` → Add all LiveWorkout views
3. ✅ Ensure "Add to targets: HomebaseApp" is checked

### 2. Update Navigation

Add Live Workout to your main navigation:

**Option A: Add to TabView** (if you have tabs)
```swift
TabView {
    DashboardView()
        .tabItem {
            Label("Dashboard", systemImage: "house")
        }
    
    LiveWorkoutView()
        .tabItem {
            Label("Live Workout", systemImage: "figure.run")
        }
}
```

**Option B: Add to Navigation Menu**
```swift
NavigationLink(destination: LiveWorkoutView()) {
    Label("Live Workout", systemImage: "figure.run")
}
```

### 3. Test the Feature

1. Build and run (`Cmd + R`)
2. Navigate to Live Workout
3. **First time**: You'll see empty state (no programs)
4. **Create a program**:
   - Go to "Build Training" tab
   - Add exercises (manually for now)
   - Save
5. **Start a workout**:
   - Go to "Start Training" tab
   - Tap "Start" on a program
   - Complete sets
   - See rest timer between sets
   - Finish workout to save

## 🎨 UI Improvements (Optional)

Once basic functionality works, enhance the UI:

1. **Exercise Library**: Add ability to browse/search exercises
2. **Program Details**: Show exercise list before starting
3. **Set History**: Show previous weights used
4. **Charts**: Visualize workout duration and volume
5. **Templates**: Add default Push/Pull/Legs programs

## 📝 Default Programs

To add default programs, create them in Firebase Console or add this helper:

```swift
func createDefaultPrograms() async {
    let pushProgram = WorkoutProgram(
        name: .push,
        displayName: "Push Day A",
        exercises: [
            Exercise(id: "bench", name: "Bench Press", sets: 4, reps: "5", restTime: 150),
            Exercise(id: "incline", name: "Incline Press", sets: 3, reps: "8-10", restTime: 90),
            Exercise(id: "ohp", name: "Overhead Press", sets: 3, reps: "8-10", restTime: 90)
        ],
        createdAt: Date()
    )
    
    try? await firebaseService.addWorkoutProgram(pushProgram)
}
```

## 🐛 Troubleshooting

**"No such type 'WorkoutProgramsView'"**
- Create the missing view file (see templates above)

**Timer not updating**
- Make sure ViewModel is @StateObject in main view
- Check that viewModel properties are @Published

**Rest timer not showing**
- Verify RestTimerOverlay is in ZStack
- Check viewModel.isResting is true

## 📊 Feature Status

- ✅ ViewModel (complete)
- ✅ Main view structure (complete)
- ✅ Rest timer (complete)
- ⏳ Programs list (template provided)
- ⏳ Workout builder (template provided)
- ⏳ Active workout (template provided)

**Estimated completion time**: 2-3 hours to implement the 3 remaining views using the templates above.

## 🎯 Next Steps

1. Create the 3 view files using templates above
2. Add to Xcode project
3. Test basic flow
4. Refine UI and add features

Good luck! This is the most complex feature but also the most powerful! 💪

