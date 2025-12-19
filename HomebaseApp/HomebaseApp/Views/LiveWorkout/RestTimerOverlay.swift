//
//  RestTimerOverlay.swift
//  HomebaseApp
//
//  Full-screen rest timer overlay with countdown
//

import SwiftUI

struct RestTimerOverlay: View {
    @ObservedObject var viewModel: LiveWorkoutViewModel
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Title
                Text(viewModel.restLabel)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Countdown
                Text(formatTime(viewModel.restTimeRemaining))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Controls
                HStack(spacing: 20) {
                    // Add time button
                    Button(action: {
                        viewModel.addRestTime(seconds: 30)
                    }) {
                        Label("+30s", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    // Skip rest button
                    Button(action: {
                        viewModel.stopRest()
                    }) {
                        Label("Skip Rest", systemImage: "forward.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .transition(.opacity)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

