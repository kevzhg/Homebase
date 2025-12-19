//
//  ExerciseInstanceEditView.swift
//  HomebaseApp
//
//  Edit an exercise instance within a workout (local changes only)
//

import SwiftUI

struct ExerciseInstanceEditView: View {
    let exercise: Exercise
    let onSave: (Exercise) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var editedSets: String
    @State private var editedReps: String
    @State private var editedRest: String
    
    init(exercise: Exercise, onSave: @escaping (Exercise) -> Void) {
        self.exercise = exercise
        self.onSave = onSave
        
        _editedSets = State(initialValue: "\(exercise.sets)")
        _editedReps = State(initialValue: exercise.reps)
        _editedRest = State(initialValue: "\(exercise.restTime)")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Exercise") {
                    HStack {
                        Text(exercise.name)
                            .font(.headline)
                        Spacer()
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
                            .frame(width: 100)
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
                
                Section {
                    Text("Changes only apply to this workout")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        let updatedExercise = Exercise(
            id: exercise.id,
            name: exercise.name,
            sets: Int(editedSets) ?? exercise.sets,
            reps: editedReps,
            restTime: Int(editedRest) ?? exercise.restTime,
            notes: exercise.notes,
            exerciseType: exercise.exerciseType
        )
        
        onSave(updatedExercise)
        dismiss()
    }
}
