//
//  ActiveWorkoutView.swift
//  HomebaseApp
//
//  Active workout session with exercise tracking and set completion
//

import SwiftUI

// MARK: - Weight Memory

class ExerciseWeightMemory {
    static let shared = ExerciseWeightMemory()
    private let defaults = UserDefaults.standard
    private let keyPrefix = "exercise_last_weight_"
    
    func getLastWeight(for exerciseId: String) -> Double? {
        let key = keyPrefix + exerciseId
        let weight = defaults.double(forKey: key)
        return weight > 0 ? weight : nil
    }
    
    func saveWeight(_ weight: Double, for exerciseId: String) {
        let key = keyPrefix + exerciseId
        defaults.set(weight, forKey: key)
    }
}

struct ActiveWorkoutView: View {
    @ObservedObject var viewModel: LiveWorkoutViewModel
    let activeWorkout: ActiveWorkout
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header with timer
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activeWorkout.programName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(activeWorkout.paused ? "PAUSED" : "ACTIVE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(activeWorkout.paused ? .orange : .green)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(viewModel.workoutDuration)
                            .font(.title3)
                            .fontWeight(.bold)
                            .monospaced()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Exercise list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(activeWorkout.exercises.indices, id: \.self) { exerciseIndex in
                            if let program = viewModel.workoutPrograms.first(where: { $0.id == activeWorkout.programId }) {
                                ExerciseCard(
                                    exercise: program.exercises[exerciseIndex],
                                    activeExercise: activeWorkout.exercises[exerciseIndex],
                                    exerciseIndex: exerciseIndex,
                                    isActive: exerciseIndex == activeWorkout.currentExerciseIndex,
                                    isPaused: activeWorkout.paused,
                                    viewModel: viewModel
                                )
                            }
                        }
                    }
                    .padding()
                }
                
                // Control buttons
                HStack(spacing: 12) {
                    Button(activeWorkout.paused ? "Resume" : "Pause") {
                        viewModel.pauseWorkout()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("Finish Workout") {
                        Task {
                            await viewModel.finishWorkout()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showWorkoutSummary) {
            if let completedWorkout = viewModel.completedWorkout {
                WorkoutSummaryView(
                    workout: completedWorkout,
                    workoutDuration: viewModel.workoutDuration,
                    onDismiss: {
                        viewModel.dismissWorkoutSummary()
                    }
                )
            }
        }
    }
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    let exercise: Exercise
    let activeExercise: ActiveExercise
    let exerciseIndex: Int
    let isActive: Bool
    let isPaused: Bool
    @ObservedObject var viewModel: LiveWorkoutViewModel
    
    var completedSets: Int {
        activeExercise.sets.filter { $0.completed }.count
    }
    
    var allSetsCompleted: Bool {
        activeExercise.sets.allSatisfy { $0.completed }
    }
    
    var hasStarted: Bool {
        completedSets > 0
    }
    
    // Auto-expand only if active or has progress
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: { 
                if hasStarted || isActive {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(exercise.name)
                                .font(.headline)
                                .foregroundColor(hasStarted || isActive ? .primary : .secondary)
                            
                            // Show current set if active
                            if isActive && !allSetsCompleted {
                                Text("- Set \(activeExercise.currentSet + 1)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                        Text("\(exercise.sets) sets × \(exercise.reps) • \(exercise.restTime)s rest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let notes = exercise.notes, (hasStarted || isActive) {
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    
                    Spacer()
                    
                    if hasStarted || isActive {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(completedSets)/\(exercise.sets)")
                                .font(.headline)
                                .foregroundColor(allSetsCompleted ? .green : .primary)
                            if allSetsCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    if hasStarted || isActive {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .opacity(hasStarted || isActive ? 1.0 : 0.5)
            
            // Sets - only show if started or active
            if isExpanded && (hasStarted || isActive) {
                ForEach(activeExercise.sets) { set in
                    SetRow(
                        set: set,
                        exercise: exercise,
                        exerciseIndex: exerciseIndex,
                        isSetActive: isActive && set.setNumber == activeExercise.currentSet + 1,
                        isPaused: isPaused,
                        viewModel: viewModel
                    )
                }
            }
        }
        .padding()
        .background(isActive ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.blue : Color.clear, lineWidth: 2)
        )
        .cornerRadius(12)
        .onAppear {
            // Auto-expand if active
            if isActive {
                isExpanded = true
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                isExpanded = true
            }
        }
        .onChange(of: allSetsCompleted) { completed in
            // Collapse when all sets are completed
            if completed {
                isExpanded = false
            }
        }
    }
}

// MARK: - Set Row

struct SetRow: View {
    let set: ExerciseSet
    let exercise: Exercise
    let exerciseIndex: Int
    let isSetActive: Bool
    let isPaused: Bool
    @ObservedObject var viewModel: LiveWorkoutViewModel
    
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var hasInitialized = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Completed set - show summary
            if set.completed {
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    if let w = set.weight {
                        Text("\(Int(w)) lbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let r = set.actualReps {
                        Text("\(r) reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
            // Active set - show full inputs
            else if isSetActive {
                VStack(alignment: .leading, spacing: 12) {
                    // Weight, reps, and increment buttons in a clean row
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weight")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("0", text: $weight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 8)
                                .background(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .frame(width: 60)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reps")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField(exercise.reps, text: $reps)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 8)
                                .background(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .frame(width: 55)
                        }
                        
                        Spacer()
                        
                        // Quick add weight buttons
                        Button("+10") {
                            addWeight(10)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .fixedSize()
                        
                        Button("+5") {
                            addWeight(5)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .fixedSize()
                        
                        Button("+2.5") {
                            addWeight(2.5)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .fixedSize()
                    }
                    
                    // Complete button - full width
                    Button(action: completeSet) {
                        Label("Complete Set", systemImage: "checkmark")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isPaused || viewModel.isResting)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
            // Future sets - show minimized
            else {
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Locked - Complete previous sets first")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(6)
            }
        }
        .onAppear {
            if !hasInitialized && isSetActive && !set.completed {
                // Load last used weight for this exercise
                if let lastWeight = ExerciseWeightMemory.shared.getLastWeight(for: exercise.id) {
                    // Format: no decimal if whole number, .5 if it has 0.5
                    if lastWeight.truncatingRemainder(dividingBy: 1) == 0 {
                        weight = String(format: "%.0f", lastWeight)
                    } else {
                        weight = String(format: "%.1f", lastWeight)
                    }
                } else {
                    weight = ""
                }
                
                // Pre-fill reps with exercise prescription
                reps = exercise.reps
                
                hasInitialized = true
            }
        }
        .onChange(of: isSetActive) { newValue in
            if newValue && !set.completed && !hasInitialized {
                // Load last used weight for this exercise
                if let lastWeight = ExerciseWeightMemory.shared.getLastWeight(for: exercise.id) {
                    // Format: no decimal if whole number, .5 if it has 0.5
                    if lastWeight.truncatingRemainder(dividingBy: 1) == 0 {
                        weight = String(format: "%.0f", lastWeight)
                    } else {
                        weight = String(format: "%.1f", lastWeight)
                    }
                } else {
                    weight = ""
                }
                
                // Pre-fill reps with exercise prescription
                reps = exercise.reps
                
                hasInitialized = true
            }
        }
    }
    
    private func addWeight(_ amount: Double) {
        let current = Double(weight) ?? 0
        let newWeight = current + amount
        
        // Format: no decimal if whole number, .5 if it has 0.5
        if newWeight.truncatingRemainder(dividingBy: 1) == 0 {
            weight = String(format: "%.0f", newWeight)
        } else {
            weight = String(format: "%.1f", newWeight)
        }
    }
    
    private func completeSet() {
        Task {
            let w = Double(weight)
            let r = reps.isEmpty ? exercise.reps : reps
            
            // Save weight to memory if provided
            if let weightValue = w, weightValue > 0 {
                ExerciseWeightMemory.shared.saveWeight(weightValue, for: exercise.id)
            }
            
            await viewModel.completeSet(
                exerciseIndex: exerciseIndex,
                setIndex: set.setNumber - 1,
                weight: w,
                reps: r
            )
            
            // Reset for next set
            reps = exercise.reps  // Reset to prescribed reps
            // Keep weight for next set (already in the field)
        }
    }
}

// MARK: - Preview

struct ActiveWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = LiveWorkoutViewModel()
        if let workout = vm.activeWorkout {
            ActiveWorkoutView(viewModel: vm, activeWorkout: workout)
        } else {
            Text("No active workout")
        }
    }
}

