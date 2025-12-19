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
                        // Tabs
                        TabSelector(selectedTab: $viewModel.selectedTab)
                            .padding(.top, 12)
                        
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
            .toolbarBackground(Color(red: 0.85, green: 0.80, blue: 0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
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
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.clear)
                .cornerRadius(6)
        }
    }
}

// MARK: - Preview

struct LiveWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        LiveWorkoutView()
    }
}

