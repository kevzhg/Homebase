//
//  WorkoutBuilderView.swift
//  HomebaseApp
//
//  Create and edit workout programs
//

import SwiftUI

struct WorkoutBuilderView: View {
    @ObservedObject var viewModel: LiveWorkoutViewModel
    @ObservedObject var firebaseService = FirebaseService.shared
    @State private var newExerciseName = ""
    @State private var newExerciseSets = "4"
    @State private var newExerciseReps = "8"
    @State private var newExerciseRest = "60"
    @State private var isAddExerciseExpanded = false
    @State private var showExerciseLibrary = false
    @State private var saveToLibrary = true
    @State private var selectedPrimaryType: ProgramType = .push
    @State private var selectedSecondaryType: ExerciseType? = nil
    @State private var selectedMuscles: Set<String> = []
    
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
                    
                    // Category picker - Only Push/Pull/Legs/Hybrid for workout programs
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WORKOUT TYPE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Picker("Category", selection: $viewModel.builderCategory) {
                            Text(ProgramType.push.displayName).tag(ProgramType.push)
                            Text(ProgramType.pull.displayName).tag(ProgramType.pull)
                            Text(ProgramType.legs.displayName).tag(ProgramType.legs)
                            Text(ProgramType.hybrid.displayName).tag(ProgramType.hybrid)
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
                                    onEdit: { updatedExercise in
                                        viewModel.builderExercises[index] = updatedExercise
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
                    
                    // Exercise Library Browse Button
                    Button(action: { showExerciseLibrary = true }) {
                        HStack {
                            Image(systemName: "books.vertical")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Browse Exercise Library")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("\(firebaseService.exerciseLibrary.count) exercises available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                    
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
                                Text("CREATE NEW EXERCISE")
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
                            VStack(spacing: 10) {
                                // Exercise name
                                TextField("Exercise name", text: $newExerciseName)
                                    .textFieldStyle(.roundedBorder)
                                
                                // Row 1: Primary, Secondary, Muscles
                                HStack(spacing: 8) {
                                    // Primary Type
                                    Menu {
                                        ForEach(ProgramType.allCases, id: \.self) { type in
                                            Button(action: { selectedPrimaryType = type }) {
                                                HStack {
                                                    Text(type.displayName)
                                                    if selectedPrimaryType == type {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Primary")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            HStack {
                                                Text(selectedPrimaryType.displayName)
                                                    .font(.caption)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                Image(systemName: "chevron.down")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(6)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    // Secondary Type
                                    Menu {
                                        Button(action: { 
                                            selectedSecondaryType = nil
                                            newExerciseSets = "4"
                                            newExerciseReps = "8"
                                        }) {
                                            HStack {
                                                Text("None")
                                                if selectedSecondaryType == nil {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                        ForEach(ExerciseType.allCases, id: \.self) { type in
                                            Button(action: { 
                                                selectedSecondaryType = type
                                                newExerciseSets = "\(type.defaultSets)"
                                                newExerciseReps = type.defaultReps
                                            }) {
                                                HStack {
                                                    Text(type.displayName)
                                                    if selectedSecondaryType == type {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Secondary")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            HStack {
                                                Text(selectedSecondaryType?.displayName ?? "None")
                                                    .font(.caption)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                Image(systemName: "chevron.down")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(6)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    // Muscle Groups
                                    Menu {
                                        ForEach(["Chest", "Shoulders", "Back", "Quads", "Hamstrings", "Calves", "Triceps", "Biceps", "Forearms", "Abs"], id: \.self) { muscle in
                                            Button(action: {
                                                if selectedMuscles.contains(muscle) {
                                                    selectedMuscles.remove(muscle)
                                                } else {
                                                    selectedMuscles.insert(muscle)
                                                }
                                            }) {
                                                HStack {
                                                    Text(muscle)
                                                    if selectedMuscles.contains(muscle) {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Muscles")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            HStack {
                                                Text(selectedMuscles.isEmpty ? "None" : "\(selectedMuscles.count) selected")
                                                    .font(.caption)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                Image(systemName: "chevron.down")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(6)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                
                                // Row 2: Sets, Reps, Rest
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Sets")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        TextField("4", text: $newExerciseSets)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(height: 32)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Reps")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        TextField("8", text: $newExerciseReps)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(height: 32)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Rest (s)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        TextField("60", text: $newExerciseRest)
                                            .keyboardType(.numberPad)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(height: 32)
                                    }
                                }
                                
                                // Save toggle and Add button
                                HStack(spacing: 8) {
                                    Toggle("Save to Library", isOn: $saveToLibrary)
                                        .font(.caption)
                                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                                    
                                    Button(action: addExercise) {
                                        Label("Add", systemImage: "plus.circle.fill")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(newExerciseName.isEmpty)
                                }
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
            .sheet(isPresented: $showExerciseLibrary) {
                ExerciseLibraryView(isPresented: $showExerciseLibrary) { libraryExercise in
                    addExerciseFromLibrary(libraryExercise)
                }
            }
    }
    
    private var totalSets: Int {
        viewModel.builderExercises.reduce(0) { $0 + $1.sets }
    }
    
    private func addExercise() {
        // Capture values before resetting form
        let exerciseName = newExerciseName
        let exerciseSets = Int(newExerciseSets) ?? 4
        let exerciseReps = newExerciseReps
        let exerciseRest = Int(newExerciseRest) ?? 90
        let primaryType = selectedPrimaryType
        let secondaryType = selectedSecondaryType
        let muscles = Array(selectedMuscles)
        
        logInfo("🏋️ Adding exercise - Name: '\(exerciseName)', Primary: \(primaryType.rawValue), Muscles: \(muscles.joined(separator: ", "))", category: "liveWorkout")
        
        let exercise = Exercise(
            id: UUID().uuidString,
            name: exerciseName,
            sets: exerciseSets,
            reps: exerciseReps,
            restTime: exerciseRest,
            notes: nil,
            exerciseType: secondaryType
        )
        viewModel.builderExercises.append(exercise)
        
        // Save to exercise library if toggle is on
        if saveToLibrary {
            logInfo("💾 Saving to library - Name: '\(exerciseName)', Primary: \(primaryType.rawValue)", category: "liveWorkout")
            Task {
                let libraryItem = ExerciseLibraryItem(
                    id: nil,
                    name: exerciseName,
                    sets: exerciseSets,
                    reps: exerciseReps,
                    restTime: exerciseRest,
                    notes: nil,
                    exerciseType: secondaryType,
                    category: primaryType,
                    muscles: muscles.isEmpty ? nil : muscles,
                    equipment: nil
                )
                
                logInfo("📦 Library item created - Name: '\(libraryItem.name)', Primary: \(libraryItem.category.rawValue)", category: "liveWorkout")
                
                do {
                    try await firebaseService.addExerciseToLibrary(libraryItem)
                    logSuccess("✅ Exercise '\(exerciseName)' saved to library", category: "liveWorkout")
                } catch {
                    logError("❌ Failed to save exercise to library", error: error, category: "liveWorkout")
                }
            }
        } else {
            logInfo("⏭️ Skipping save to library (toggle is off)", category: "liveWorkout")
        }
        
        resetForm()
    }
    
    private func addExerciseFromLibrary(_ libraryExercise: ExerciseLibraryItem) {
        let exercise = Exercise(
            id: UUID().uuidString,
            name: libraryExercise.name,
            sets: libraryExercise.sets,
            reps: libraryExercise.reps,
            restTime: libraryExercise.restTime,
            notes: libraryExercise.notes,
            exerciseType: libraryExercise.exerciseType
        )
        viewModel.builderExercises.append(exercise)
    }
    
    private func resetForm() {
        newExerciseName = ""
        newExerciseSets = "4"
        newExerciseReps = "8"
        newExerciseRest = "60"
        selectedPrimaryType = .push
        selectedSecondaryType = nil
        selectedMuscles.removeAll()
    }
}

// MARK: - Exercise Builder Row

struct ExerciseBuilderRow: View {
    let exercise: Exercise
    let index: Int
    let onDelete: () -> Void
    let onEdit: (Exercise) -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    
    @State private var showEditSheet = false
    
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
            
            // Edit button
            Button(action: { showEditSheet = true }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.borderless)
            
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
        .sheet(isPresented: $showEditSheet) {
            ExerciseInstanceEditView(exercise: exercise, onSave: onEdit)
        }
    }
}

// MARK: - Preview

struct WorkoutBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutBuilderView(viewModel: LiveWorkoutViewModel())
    }
}
