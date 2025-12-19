//
//  DashboardView.swift
//  HomebaseApp
//
//  Main dashboard showing today's summary and recent activity
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var firebaseService = FirebaseService.shared
    @State private var expandedTrainingId: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Summary Cards
                    todaySummarySection
                    
                    // Weekly Progress
                    weeklyProgressSection
                    
                    // Recent Training Sessions
                    recentTrainingsSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                // Pull to refresh (listeners already handle updates)
            }
        }
    }
    
    // MARK: - Today's Summary
    
    private var todaySummarySection: some View {
        VStack(spacing: 16) {
            Text("Today's Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Training Card
                SummaryCard(
                    title: "Training",
                    icon: "💪"
                ) {
                    todayTrainingContent
                }
                
                // Meals Card
                SummaryCard(
                    title: "Meals",
                    icon: "🍽️"
                ) {
                    todayMealsContent
                }
                
                // Weight Card
                SummaryCard(
                    title: "Weight",
                    icon: "⚖️"
                ) {
                    currentWeightContent
                }
                
                // Progress Card
                SummaryCard(
                    title: "This Week",
                    icon: "📈"
                ) {
                    weeklyProgressContent
                }
            }
        }
    }
    
    private var todayTrainingContent: some View {
        let today = Date.todayString()
        let todayTrainings = firebaseService.getTrainings(forDate: today)
        
        return Group {
            if todayTrainings.isEmpty {
                Text("No training logged")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(todayTrainings.count) session(s)")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    let totalMinutes = todayTrainings.reduce(0) { $0 + $1.durationMinutes }
                    Text("\(totalMinutes) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var todayMealsContent: some View {
        let today = Date.todayString()
        let todayMeals = firebaseService.getMeals(forDate: today)
        
        return Group {
            if todayMeals.isEmpty {
                Text("No meals logged")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(todayMeals.count) meal(s)")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    let totalCalories = todayMeals.compactMap { $0.calories }.reduce(0, +)
                    let totalProtein = todayMeals.compactMap { $0.protein }.reduce(0, +)
                    
                    if totalCalories > 0 {
                        Text("\(totalCalories) cal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if totalProtein > 0 {
                        Text("\(totalProtein)g protein")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var currentWeightContent: some View {
        Group {
            if let latest = firebaseService.weightEntries.currentWeight {
                VStack(alignment: .leading, spacing: 4) {
                    Text(latest.displayWeight)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if let change = firebaseService.weightEntries.weightChange {
                        let changeStr = change >= 0 ? "+\(String(format: "%.1f", change))" : String(format: "%.1f", change)
                        Text("\(changeStr) \(latest.unit.rawValue)")
                            .font(.caption)
                            .foregroundColor(change < 0 ? .green : change > 0 ? .red : .secondary)
                    }
                }
            } else {
                Text("No weight logged")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var weeklyProgressContent: some View {
        let stats = firebaseService.getWeeklyStats()
        
        return VStack(alignment: .leading, spacing: 4) {
            Text("\(stats.trainings) workouts")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(stats.totalMinutes) min")
                .font(.title3)
                .fontWeight(.bold)
            Text("\(stats.meals) meals")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Weekly Progress Section
    
    private var weeklyProgressSection: some View {
        VStack(spacing: 12) {
            Text("Weekly Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let stats = firebaseService.getWeeklyStats()
            
            HStack(spacing: 20) {
                StatRow(label: "Workouts", value: "\(stats.trainings)")
                Divider()
                StatRow(label: "Minutes", value: "\(stats.totalMinutes)")
                Divider()
                StatRow(label: "Meals", value: "\(stats.meals)")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Recent Trainings Section
    
    private var recentTrainingsSection: some View {
        VStack(spacing: 12) {
            Text("Recent Training Sessions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if firebaseService.trainings.isEmpty {
                Text("No training sessions logged yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(firebaseService.trainings.prefix(5))) { training in
                    RecentTrainingRow(
                        training: training,
                        isExpanded: expandedTrainingId == training.id,
                        onToggle: {
                            withAnimation {
                                if expandedTrainingId == training.id {
                                    expandedTrainingId = nil
                                } else {
                                    expandedTrainingId = training.id
                                }
                            }
                        },
                        onDelete: {
                            Task {
                                if let id = training.id {
                                    try? await firebaseService.deleteTraining(id)
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SummaryCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecentTrainingRow: View {
    let training: Training
    let isExpanded: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(training.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(training.programName ?? training.exercises.first?.name ?? "Training")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(training.durationMinutes) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if training.notes?.contains("Live") == true {
                            Text("Live")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    if let programName = training.programName {
                        Text("Program: \(programName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let notes = training.notes {
                        Text(notes)
                            .font(.caption)
                            .italic()
                            .foregroundColor(.secondary)
                    }
                    
                    // Exercises
                    ForEach(training.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(exercise.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                if let elapsed = exercise.elapsedMs {
                                    Text("\(elapsed / 1000)s")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Sets
                            ForEach(exercise.sets) { set in
                                HStack {
                                    Text("Set \(set.setNumber)")
                                        .font(.caption)
                                    
                                    if let weight = set.weight {
                                        Text("\(Int(weight)) lbs")
                                            .font(.caption)
                                    }
                                    
                                    if let reps = set.reps {
                                        Text("\(reps) reps")
                                            .font(.caption)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.leading, 8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Delete button
                    Button(action: onDelete) {
                        Text("Delete")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}

