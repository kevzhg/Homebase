//
//  WorkoutBuilderView.swift
//  HomebaseApp
//
//  Create and edit workout programs
//

import SwiftUI

struct WorkoutBuilderView: View {
    @ObservedObject var viewModel: LiveWorkoutViewModel
    @State private var newExerciseName = ""
    @State private var newExerciseSets = "4"
    @State private var newExerciseReps = "8"
    @State private var newExerciseRest = "90"
    @State private var isAddExerciseExpanded = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                    // Header with Save Button
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if let editing = viewModel.editingProgram {
                                    Text("Editing: \(editing.displayName)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .fontWeight(.semibold)
                                }
                                Text("BUILD TRAINING")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Text("Create Custom Workout")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            // Save button at top
                            Button(action: {
                                Task {
                                    await viewModel.saveProgram()
                                    resetForm()
                                }
                            }) {
                                Text(viewModel.editingProgram != nil ? "Update" : "Save")
                                    .fontWeight(.semibold)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.builderExercises.isEmpty || viewModel.builderName.isEmpty)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Workout name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SESSION NAME")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        TextField("e.g., Heavy Push", text: $viewModel.builderName)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                    
                    // Category picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CATEGORY")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Picker("Category", selection: $viewModel.builderCategory) {
                            ForEach(ProgramType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)
                    
                    // Exercises list (moved above Add Exercise)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("EXERCISES")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(viewModel.builderExercises.count) exercises • \(totalSets) sets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        if viewModel.builderExercises.isEmpty {
                            Text("No exercises added yet")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(Array(viewModel.builderExercises.enumerated()), id: \.offset) { index, exercise in
                                ExerciseBuilderRow(
                                    exercise: exercise,
                                    index: index,
                                    onDelete: {
                                        viewModel.builderExercises.remove(at: index)
                                    },
                                    onMoveUp: index > 0 ? {
                                        let item = viewModel.builderExercises.remove(at: index)
                                        viewModel.builderExercises.insert(item, at: index - 1)
                                    } : nil,
                                    onMoveDown: index < viewModel.builderExercises.count - 1 ? {
                                        let item = viewModel.builderExercises.remove(at: index)
                                        viewModel.builderExercises.insert(item, at: index + 1)
                                    } : nil
                                )
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Collapsible Add Exercise section
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isAddExerciseExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text("ADD EXERCISE")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: isAddExerciseExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if isAddExerciseExpanded {
                            VStack(spacing: 12) {
                                TextField("Exercise name", text: $newExerciseName)
                                    .textFieldStyle(.roundedBorder)
                                
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading) {
                                        Text("Sets")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        TextField("4", text: $newExerciseSets)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("Reps")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        TextField("8", text: $newExerciseReps)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("Rest (s)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        TextField("90", text: $newExerciseRest)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                
                                Button(action: addExercise) {
                                    Label("Add Exercise", systemImage: "plus.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(newExerciseName.isEmpty)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Bottom action buttons
                    HStack(spacing: 12) {
                        Button("Reset") {
                            viewModel.resetBuilder()
                            resetForm()
                        }
                        .buttonStyle(.bordered)
                        
                        Button(viewModel.editingProgram != nil ? "Update Workout" : "Save Workout") {
                            Task {
                                await viewModel.saveProgram()
                                resetForm()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.builderExercises.isEmpty || viewModel.builderName.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 120) // Extra padding for tab bar
                }
                .padding(.top)
            }
            .scrollDismissesKeyboard(.interactively)
    }
    
    private var totalSets: Int {
        viewModel.builderExercises.reduce(0) { $0 + $1.sets }
    }
    
    private func addExercise() {
        let exercise = Exercise(
            id: UUID().uuidString,
            name: newExerciseName,
            sets: Int(newExerciseSets) ?? 4,
            reps: newExerciseReps,
            restTime: Int(newExerciseRest) ?? 90
        )
        viewModel.builderExercises.append(exercise)
        resetForm()
    }
    
    private func resetForm() {
        newExerciseName = ""
        newExerciseSets = "4"
        newExerciseReps = "8"
        newExerciseRest = "90"
    }
}

// MARK: - Exercise Builder Row

struct ExerciseBuilderRow: View {
    let exercise: Exercise
    let index: Int
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Reorder controls
            VStack(spacing: 4) {
                if let onMoveUp = onMoveUp {
                    Button(action: onMoveUp) {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                if let onMoveDown = onMoveDown {
                    Button(action: onMoveDown) {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .frame(width: 30)
            
            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 12) {
                    Label("\(exercise.sets) sets", systemImage: "repeat")
                    Label(exercise.reps, systemImage: "number")
                    Label("\(exercise.restTime)s", systemImage: "timer")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Preview

struct WorkoutBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutBuilderView(viewModel: LiveWorkoutViewModel())
    }
}
