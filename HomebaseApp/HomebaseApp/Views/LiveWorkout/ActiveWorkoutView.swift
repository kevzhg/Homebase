//
//  ActiveWorkoutView.swift
//  HomebaseApp
//
//  Active workout session with exercise tracking and set completion
//

import SwiftUI

struct ActiveWorkoutView: View {
    @ObservedObject var viewModel: LiveWorkoutViewModel
    let activeWorkout: ActiveWorkout
    
    var body: some View {
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
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    let exercise: Exercise
    let activeExercise: ActiveExercise
    let exerciseIndex: Int
    let isActive: Bool
    let isPaused: Bool
    @ObservedObject var viewModel: LiveWorkoutViewModel
    @State private var isExpanded: Bool = true
    
    var completedSets: Int {
        activeExercise.sets.filter { $0.completed }.count
    }
    
    var allSetsCompleted: Bool {
        activeExercise.sets.allSatisfy { $0.completed }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("\(exercise.sets) sets × \(exercise.reps) • \(exercise.restTime)s rest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let notes = exercise.notes {
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(completedSets)/\(exercise.sets)")
                            .font(.headline)
                            .foregroundColor(allSetsCompleted ? .green : .primary)
                        if allSetsCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            // Sets
            if isExpanded {
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Set header
            HStack {
                Text("Set \(set.setNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if set.completed {
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
            }
            
            // Set inputs (only if active and not completed)
            if isSetActive && !set.completed {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // Weight input
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weight (lbs)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("0", text: $weight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Quick add buttons
                        HStack(spacing: 4) {
                            Button("+10") {
                                addWeight(10)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("+5") {
                                addWeight(5)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("+2.5") {
                                addWeight(2.5)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    
                    // Reps input
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reps")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField(exercise.reps, text: $reps)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Complete button
                        Button(action: completeSet) {
                            Label("Complete Set", systemImage: "checkmark")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isPaused || viewModel.isResting)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            } else if !set.completed {
                // Locked state
                Text("Locked - Complete previous sets first")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(isSetActive ? Color.blue.opacity(0.05) : Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func addWeight(_ amount: Double) {
        let current = Double(weight) ?? 0
        weight = String(format: "%.1f", current + amount)
    }
    
    private func completeSet() {
        Task {
            let w = Double(weight)
            let r = reps.isEmpty ? exercise.reps : reps
            await viewModel.completeSet(
                exerciseIndex: exerciseIndex,
                setIndex: set.setNumber - 1,
                weight: w,
                reps: r
            )
            
            // Reset for next set
            reps = ""
            // Keep weight for next set
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

