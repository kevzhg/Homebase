//
//  LiveWorkoutView.swift
//  HomebaseApp
//
//  Main live workout view with tabs for Start Training and Build Training
//

import SwiftUI

struct LiveWorkoutView: View {
    @StateObject private var viewModel = LiveWorkoutViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isWorkoutActive, let activeWorkout = viewModel.activeWorkout {
                    // Active workout screen
                    ActiveWorkoutView(viewModel: viewModel, activeWorkout: activeWorkout)
                } else {
                    // Program selection or builder
                    VStack(spacing: 0) {
                        // Header
                        LiveWorkoutHeader()
                        
                        // Tabs
                        TabSelector(selectedTab: $viewModel.selectedTab)
                        
                        // Content - using conditional view instead of paged TabView
                        // to avoid gesture conflicts with ScrollView
                        Group {
                            if viewModel.selectedTab == .start {
                                WorkoutProgramsView(viewModel: viewModel)
                            } else {
                                WorkoutBuilderView(viewModel: viewModel)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                
                // Rest timer overlay
                if viewModel.isResting {
                    RestTimerOverlay(viewModel: viewModel)
                }
            }
            .navigationTitle("Live Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Header

struct LiveWorkoutHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LIVE TRAINING")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text("Build & Run Sessions")
                .font(.title2)
                .fontWeight(.bold)
            Text("Push, Pull, Legs templates. Save, clone, and start live workouts.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Tab Selector

struct TabSelector: View {
    @Binding var selectedTab: WorkoutTab
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "Start Training", isSelected: selectedTab == .start) {
                selectedTab = .start
            }
            
            TabButton(title: "Build Training", isSelected: selectedTab == .build) {
                selectedTab = .build
            }
        }
        .background(Color(.systemGray6))
        .padding(.horizontal)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.blue : Color.clear)
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview

struct LiveWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        LiveWorkoutView()
    }
}

