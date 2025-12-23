//
//  WorkoutSummaryView.swift
//  HomebaseApp
//
//  Workout completion summary with confetti celebration
//

import SwiftUI

struct WorkoutSummaryView: View {
    let workout: ActiveWorkout
    let workoutDuration: String
    let onDismiss: () -> Void
    
    @State private var showConfetti = false
    
    var completedExercises: Int {
        workout.exercises.filter { exercise in
            exercise.sets.contains(where: { $0.completed })
        }.count
    }
    
    var totalExercises: Int {
        workout.exercises.count
    }
    
    var completedSets: Int {
        workout.exercises.flatMap { $0.sets }.filter { $0.completed }.count
    }
    
    var totalSets: Int {
        workout.exercises.flatMap { $0.sets }.count
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                        .padding(.top, 40)
                    
                    Text("Workout Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(workout.programName)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Stats
                VStack(spacing: 24) {
                    SummaryStatRow(
                        icon: "clock.fill",
                        label: "Duration",
                        value: workoutDuration,
                        color: .blue
                    )
                    
                    SummaryStatRow(
                        icon: "figure.strengthtraining.traditional",
                        label: "Exercises",
                        value: "\(completedExercises) of \(totalExercises)",
                        color: .purple
                    )
                    
                    SummaryStatRow(
                        icon: "checkmark.square.fill",
                        label: "Sets Completed",
                        value: "\(completedSets) of \(totalSets)",
                        color: .green
                    )
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                
                // Done button
                Button(action: onDismiss) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding()
            }
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            showConfetti = true
        }
    }
}

// MARK: - Summary Stat Row

struct SummaryStatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<100, id: \.self) { index in
                    ConfettiPieceView(
                        index: index,
                        screenWidth: geometry.size.width,
                        screenHeight: geometry.size.height
                    )
                }
            }
        }
    }
}

struct ConfettiPieceView: View {
    let index: Int
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    
    @State private var yOffset: CGFloat = 0
    @State private var rotationOffset: Double = 0
    @State private var opacity: Double = 1
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    private var color: Color {
        colors[index % colors.count]
    }
    
    private var xPosition: CGFloat {
        CGFloat.random(in: 0...screenWidth)
    }
    
    private var initialY: CGFloat {
        CGFloat.random(in: -100...(-50))
    }
    
    private var rotation: Double {
        Double.random(in: 0...360)
    }
    
    private var scale: CGFloat {
        CGFloat.random(in: 0.5...1.5)
    }
    
    private var duration: Double {
        Double.random(in: 2...4)
    }
    
    private var delay: Double {
        Double.random(in: 0...0.5)
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation + rotationOffset))
            .position(x: xPosition, y: initialY + yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: duration).delay(delay)) {
                    yOffset = screenHeight + 100
                    rotationOffset = Double.random(in: 360...720)
                }
                
                withAnimation(.linear(duration: duration * 0.5).delay(delay + duration * 0.5)) {
                    opacity = 0
                }
            }
    }
}
