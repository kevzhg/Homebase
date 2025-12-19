//
//  WorkoutProgramsView.swift
//  HomebaseApp
//
//  List of saved workout programs with start/edit/delete actions
//

import SwiftUI

struct WorkoutProgramsView: View {
    @ObservedObject var viewModel: LiveWorkoutViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SAVED PROGRAMS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("Start, Clone, Edit")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        // Debug: Show program count
                        Text("\(viewModel.workoutPrograms.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Programs list
                if viewModel.workoutPrograms.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.run.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No programs yet")
                            .font(.headline)
                        Text("Build your first workout program using the Build tab!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 60)
                } else {
                    // Show all programs (grouped by category)
                    ForEach(ProgramType.allCases, id: \.self) { category in
                        let programs = viewModel.workoutPrograms.filter { $0.name == category }
                        if !programs.isEmpty {
                            ProgramCategorySection(
                                category: category,
                                programs: programs,
                                viewModel: viewModel
                            )
                        }
                    }
                    
                    // Show uncategorized programs (if any) - fallback for debugging
                    let uncategorized = viewModel.workoutPrograms.filter { program in
                        !ProgramType.allCases.contains(program.name)
                    }
                    if !uncategorized.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Other")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(uncategorized) { program in
                                ProgramCard(program: program, viewModel: viewModel)
                            }
                        }
                    }
                    
                    // Debug: If we have programs but none matched categories, show them all
                    if viewModel.workoutPrograms.count > 0 && 
                       viewModel.workoutPrograms.allSatisfy({ !ProgramType.allCases.contains($0.name) }) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("All Programs")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.workoutPrograms) { program in
                                ProgramCard(program: program, viewModel: viewModel)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
            .padding(.bottom, 100) // Extra padding for tab bar
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Category Section

struct ProgramCategorySection: View {
    let category: ProgramType
    let programs: [WorkoutProgram]
    @ObservedObject var viewModel: LiveWorkoutViewModel
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(category.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("(\(programs.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
            
            // Programs
            if isExpanded {
                ForEach(programs) { program in
                    ProgramCard(program: program, viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - Program Card

struct ProgramCard: View {
    let program: WorkoutProgram
    @ObservedObject var viewModel: LiveWorkoutViewModel
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.displayName)
                        .font(.headline)
                    Text("\(program.name.displayName) • \(program.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // Exercise preview (first 2)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(program.exercises.prefix(2))) { exercise in
                    HStack {
                        Text("•")
                        Text(exercise.name)
                            .font(.caption)
                        Spacer()
                        Text("\(exercise.sets)×\(exercise.reps)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                if program.exercises.count > 2 {
                    Text("+ \(program.exercises.count - 2) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
            
            Divider()
            
            // Actions
            HStack(spacing: 12) {
                // Start button (prominent)
                Button(action: {
                    if let id = program.id {
                        viewModel.startWorkout(programId: id)
                    }
                }) {
                    Label("Start", systemImage: "play.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                // Edit button
                Button(action: {
                    viewModel.enterEditMode(program: program)
                }) {
                    Image(systemName: "pencil")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                // Delete button
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .confirmationDialog("Delete \(program.displayName)?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    if let id = program.id {
                        await viewModel.deleteProgram(id)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Preview

struct WorkoutProgramsView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutProgramsView(viewModel: LiveWorkoutViewModel())
    }
}

