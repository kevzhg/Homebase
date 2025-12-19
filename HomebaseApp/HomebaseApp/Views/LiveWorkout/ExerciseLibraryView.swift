//
//  ExerciseLibraryView.swift
//  HomebaseApp
//
//  Browse and select exercises from the shared library
//

import SwiftUI

struct ExerciseLibraryView: View {
    @ObservedObject var firebaseService = FirebaseService.shared
    @Binding var isPresented: Bool
    let onSelectExercise: (ExerciseLibraryItem) -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory: ProgramType?
    @State private var exerciseToDelete: ExerciseLibraryItem?
    @State private var showDeleteConfirmation = false
    
    var filteredExercises: [ExerciseLibraryItem] {
        let exercises = firebaseService.exerciseLibrary
        
        var filtered = exercises
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.muscles?.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) ?? false
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search exercises...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryFilterButton(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )
                        
                        ForEach(ProgramType.allCases, id: \.self) { category in
                            CategoryFilterButton(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGray6))
                
                Divider()
                
                // Exercise list
                if filteredExercises.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No exercises found")
                            .font(.headline)
                        Text(searchText.isEmpty ? "No exercises in library yet" : "Try a different search")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 60)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredExercises) { exercise in
                                ExerciseLibraryCard(
                                    exercise: exercise,
                                    onSelect: {
                                        onSelectExercise(exercise)
                                        isPresented = false
                                    },
                                    onDelete: {
                                        exerciseToDelete = exercise
                                        showDeleteConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .alert("Delete Exercise", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let exercise = exerciseToDelete {
                        deleteExercise(exercise)
                    }
                }
            } message: {
                if let exercise = exerciseToDelete {
                    Text("Are you sure you want to delete '\(exercise.name)' from the library?")
                }
            }
        }
    }
    
    private func deleteExercise(_ exercise: ExerciseLibraryItem) {
        guard let id = exercise.id else { return }
        Task {
            do {
                try await firebaseService.deleteExerciseFromLibrary(id)
                logSuccess("Deleted '\(exercise.name)' from library", category: "liveWorkout")
            } catch {
                logError("Failed to delete exercise", error: error, category: "liveWorkout")
            }
        }
    }
}

// MARK: - Category Filter Button

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Exercise Library Card

struct ExerciseLibraryCard: View {
    let exercise: ExerciseLibraryItem
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Main content - tappable to select
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                Label(exercise.category.displayName, systemImage: "tag")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let type = exercise.exerciseType {
                                    Label(type.displayName, systemImage: "star")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    // Exercise details
                    HStack(spacing: 16) {
                        Label("\(exercise.sets) sets", systemImage: "repeat")
                        Label(exercise.reps, systemImage: "number")
                        Label("\(exercise.restTime)s", systemImage: "timer")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // Muscles
                    if let muscles = exercise.muscles, !muscles.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(muscles.prefix(3), id: \.self) { muscle in
                                Text(muscle)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                            if muscles.count > 3 {
                                Text("+\(muscles.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Notes
                    if let notes = exercise.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct ExerciseLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseLibraryView(
            isPresented: .constant(true),
            onSelectExercise: { _ in }
        )
    }
}
