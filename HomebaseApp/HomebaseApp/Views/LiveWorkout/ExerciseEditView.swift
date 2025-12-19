//
//  ExerciseEditView.swift
//  HomebaseApp
//
//  Edit an existing exercise in the library
//

import SwiftUI

struct ExerciseEditView: View {
    @ObservedObject var firebaseService = FirebaseService.shared
    let exercise: ExerciseLibraryItem
    @Binding var exerciseToEdit: ExerciseLibraryItem?
    
    @State private var editedName: String
    @State private var editedSets: String
    @State private var editedReps: String
    @State private var editedRest: String
    @State private var editedPrimaryType: ProgramType
    @State private var editedSecondaryType: ExerciseType?
    @State private var editedMuscles: Set<String>
    
    init(exercise: ExerciseLibraryItem, exerciseToEdit: Binding<ExerciseLibraryItem?>) {
        self.exercise = exercise
        self._exerciseToEdit = exerciseToEdit
        
        _editedName = State(initialValue: exercise.name)
        _editedSets = State(initialValue: "\(exercise.sets)")
        _editedReps = State(initialValue: exercise.reps)
        _editedRest = State(initialValue: "\(exercise.restTime)")
        _editedPrimaryType = State(initialValue: exercise.category)
        _editedSecondaryType = State(initialValue: exercise.exerciseType)
        _editedMuscles = State(initialValue: Set(exercise.muscles ?? []))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Exercise Details") {
                    TextField("Exercise name", text: $editedName)
                }
                
                Section("Primary Type") {
                    Menu {
                        ForEach(ProgramType.allCases, id: \.self) { type in
                            Button(action: {
                                editedPrimaryType = type
                            }) {
                                HStack {
                                    Text(type.displayName)
                                    if editedPrimaryType == type {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(editedPrimaryType.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Secondary Type") {
                    Menu {
                        Button(action: {
                            editedSecondaryType = nil
                        }) {
                            HStack {
                                Text("None")
                                if editedSecondaryType == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        ForEach(ExerciseType.allCases, id: \.self) { type in
                            Button(action: {
                                editedSecondaryType = type
                            }) {
                                HStack {
                                    Text(type.displayName)
                                    if editedSecondaryType == type {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(editedSecondaryType?.displayName ?? "None")
                                .foregroundColor(editedSecondaryType == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Muscle Groups") {
                    Menu {
                        ForEach(["Chest", "Shoulders", "Back", "Quads", "Hamstrings", "Calves", "Triceps", "Biceps", "Forearms", "Abs"], id: \.self) { muscle in
                            Button(action: {
                                if editedMuscles.contains(muscle) {
                                    editedMuscles.remove(muscle)
                                } else {
                                    editedMuscles.insert(muscle)
                                }
                            }) {
                                HStack {
                                    Text(muscle)
                                    if editedMuscles.contains(muscle) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(editedMuscles.isEmpty ? "None selected" : editedMuscles.sorted().joined(separator: ", "))
                                .foregroundColor(editedMuscles.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Sets, Reps, Rest") {
                    HStack {
                        Text("Sets")
                        Spacer()
                        TextField("4", text: $editedSets)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Reps")
                        Spacer()
                        TextField("8", text: $editedReps)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text("Rest (seconds)")
                        Spacer()
                        TextField("60", text: $editedRest)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        exerciseToEdit = nil
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(editedName.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let id = exercise.id else { return }
        
        let updatedExercise = ExerciseLibraryItem(
            id: id,
            name: editedName,
            sets: Int(editedSets) ?? 4,
            reps: editedReps,
            restTime: Int(editedRest) ?? 60,
            notes: exercise.notes,
            exerciseType: editedSecondaryType,
            category: editedPrimaryType,
            muscles: editedMuscles.isEmpty ? nil : Array(editedMuscles),
            equipment: exercise.equipment
        )
        
        Task {
            do {
                try await firebaseService.updateExerciseInLibrary(updatedExercise)
                logSuccess("Updated exercise '\(editedName)' in library", category: "liveWorkout")
                exerciseToEdit = nil
            } catch {
                logError("Failed to update exercise", error: error, category: "liveWorkout")
            }
        }
    }
}
