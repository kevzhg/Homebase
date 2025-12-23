//
//  LiveWorkoutViewModel.swift
//  HomebaseApp
//
//  Manages live workout state, timers, and program management
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import AVFAudio

@MainActor
class LiveWorkoutViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published var workoutPrograms: [WorkoutProgram] = []
    @Published var activeWorkout: ActiveWorkout?
    @Published var isWorkoutActive: Bool = false
    
    // Timers
    @Published var workoutDuration: String = "00:00"
    @Published var isResting: Bool = false
    @Published var restTimeRemaining: Int = 0
    @Published var restLabel: String = "Rest Time"
    
    // Builder state
    @Published var builderExercises: [Exercise] = []
    @Published var builderCategory: ProgramType = .push
    @Published var builderName: String = "Push Session"
    @Published var editingProgram: WorkoutProgram?
    
    // UI state
    @Published var selectedTab: WorkoutTab = .start
    @Published var expandedCategories: Set<ProgramType> = []
    @Published var showWorkoutSummary: Bool = false
    @Published var completedWorkout: ActiveWorkout?
    
    // MARK: - Private Properties
    
    private let firebaseService = FirebaseService.shared
    private let healthKitService = HealthKitService.shared
    private var workoutTimer: Timer?
    private var restTimer: Timer?
    private var workoutStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    private var saveWorkTask: Task<Void, Never>?
    
    // Constants
    private let initialRestSeconds = 300 // 5 min warmup
    private let defaultRestSeconds = 60
    
    // MARK: - Initialization
    
    init() {
        loadPrograms()
        loadActiveWorkout()
        
        // Listen for workout programs changes
        firebaseService.$workoutPrograms
            .receive(on: DispatchQueue.main)
            .sink { [weak self] programs in
                self?.workoutPrograms = programs
            }
            .store(in: &cancellables)
        
        // Request HealthKit authorization
        Task {
            try? await healthKitService.requestAuthorization()
        }
    }
    
    // MARK: - Program Management
    
    func loadPrograms() {
        logInfo("Loading workout programs", category: "live-workout")
        // Programs are loaded via FirebaseService listener
        if workoutPrograms.isEmpty {
            createDefaultPrograms()
        }
    }
    
    func createDefaultPrograms() {
        logInfo("Creating default workout programs", category: "live-workout")
        // Default programs will be created in Firebase
        // For now, they're loaded from Firestore if they exist
    }
    
    func saveProgram() async {
        guard !builderExercises.isEmpty else {
            logWarning("No exercises to save", category: "live-workout")
            return
        }
        
        let program = WorkoutProgram(
            id: editingProgram?.id,
            name: builderCategory,
            displayName: builderName.isEmpty ? "\(builderCategory.displayName) Session" : builderName,
            exercises: builderExercises,
            createdAt: editingProgram?.createdAt ?? Date(),
            updatedAt: Date(),
            source: "ios"
        )
        
        do {
            if let editingProgram = editingProgram {
                try await firebaseService.updateWorkoutProgram(program)
                logSuccess("Updated program: \(program.displayName)", category: "live-workout")
            } else {
                try await firebaseService.addWorkoutProgram(program)
                logSuccess("Created program: \(program.displayName)", category: "live-workout")
            }
            resetBuilder()
        } catch {
            logError("Failed to save program", error: error, category: "live-workout")
        }
    }
    
    func deleteProgram(_ programId: String) async {
        do {
            try await firebaseService.deleteWorkoutProgram(programId)
            logSuccess("Deleted program", category: "live-workout")
            
            // If active workout uses this program, stop it
            if activeWorkout?.programId == programId {
                stopWorkout()
            }
        } catch {
            logError("Failed to delete program", error: error, category: "live-workout")
        }
    }
    
    func enterEditMode(program: WorkoutProgram) {
        editingProgram = program
        builderCategory = program.name
        builderName = program.displayName
        builderExercises = program.exercises
        selectedTab = .build
        logInfo("Editing program: \(program.displayName)", category: "live-workout")
    }
    
    func resetBuilder() {
        editingProgram = nil
        builderExercises = []
        builderCategory = .push
        builderName = "Push Session"
        logInfo("Reset builder", category: "live-workout")
    }
    
    // MARK: - Workout Session
    
    func startWorkout(programId: String) {
        guard let program = workoutPrograms.first(where: { $0.id == programId }) else {
            logError("Program not found: \(programId)", category: "live-workout")
            return
        }
        
        logInfo("Starting workout: \(program.displayName)", category: "live-workout")
        
        let workout = ActiveWorkout(
            programId: programId,
            programName: program.displayName,
            startTime: Date(),
            exercises: program.exercises.map { exercise in
                ActiveExercise(
                    exerciseId: exercise.id,
                    sets: (0..<exercise.sets).map { i in
                        ExerciseSet(
                            setNumber: i + 1,
                            completed: false
                        )
                    },
                    currentSet: 0
                )
            },
            currentExerciseIndex: 0,
            isResting: false,
            paused: false,
            totalPausedMs: 0
        )
        
        activeWorkout = workout
        isWorkoutActive = true
        workoutStartTime = Date()
        saveActiveWorkoutState()
        
        // Start HealthKit workout session
        Task {
            try? await healthKitService.startWorkoutSession(workoutType: program.name)
            logSuccess("Started Fitness app workout tracking", category: "live-workout")
        }
        
        startWorkoutTimer()
        startRest(seconds: initialRestSeconds, label: "Warm Up")
    }
    
    func stopWorkout() {
        stopWorkoutTimer()
        stopRest()
        activeWorkout = nil
        isWorkoutActive = false
        workoutStartTime = nil
        clearActiveWorkoutState()
        logInfo("Stopped workout", category: "live-workout")
    }
    
    func pauseWorkout() {
        guard var workout = activeWorkout else { return }
        
        if workout.paused {
            // Resume
            if let pauseStart = workout.pauseStartedAt {
                let pausedMs = Int(Date().timeIntervalSince(pauseStart) * 1000)
                workout.totalPausedMs = (workout.totalPausedMs ?? 0) + pausedMs
            }
            workout.paused = false
            workout.pauseStartedAt = nil
            startWorkoutTimer()
            
            // Resume HealthKit session
            healthKitService.resumeWorkoutSession()
            logInfo("Resumed workout and Fitness tracking", category: "live-workout")
        } else {
            // Pause
            workout.paused = true
            workout.pauseStartedAt = Date()
            stopWorkoutTimer()
            stopRest()
            
            // Pause HealthKit session
            healthKitService.pauseWorkoutSession()
            logInfo("Paused workout and Fitness tracking", category: "live-workout")
        }
        
        activeWorkout = workout
        saveActiveWorkoutState()
    }
    
    func completeSet(exerciseIndex: Int, setIndex: Int, weight: Double?, reps: String?) async {
        guard var workout = activeWorkout else { return }
        guard let program = workoutPrograms.first(where: { $0.id == workout.programId }) else { return }
        
        // Mark set complete
        workout.exercises[exerciseIndex].sets[setIndex].completed = true
        workout.exercises[exerciseIndex].sets[setIndex].completedAt = Date()
        workout.exercises[exerciseIndex].sets[setIndex].weight = weight
        workout.exercises[exerciseIndex].sets[setIndex].actualReps = Int(reps ?? "0")
        
        // Move to next set or exercise
        let exercise = workout.exercises[exerciseIndex]
        if let nextSet = exercise.sets.firstIndex(where: { !$0.completed }) {
            workout.exercises[exerciseIndex].currentSet = nextSet
        } else {
            // Move to next exercise
            if let nextExercise = workout.exercises.indices.first(where: { $0 > exerciseIndex && workout.exercises[$0].sets.contains(where: { !$0.completed }) }) {
                workout.currentExerciseIndex = nextExercise
            }
        }
        
        activeWorkout = workout
        saveActiveWorkoutState()
        
        // Start rest timer
        let restTime = program.exercises[exerciseIndex].restTime
        startRest(seconds: restTime, label: "Rest Time")
        
        logSuccess("Completed set \(setIndex + 1) of exercise \(exerciseIndex + 1)", category: "live-workout")
    }
    
    func finishWorkout() async {
        guard let workout = activeWorkout else { return }
        guard let program = workoutPrograms.first(where: { $0.id == workout.programId }) else { return }
        
        let duration = workoutDurationMinutes()
        let completedSets = workout.exercises.flatMap { $0.sets }.filter { $0.completed }.count
        let totalSets = workout.exercises.flatMap { $0.sets }.count
        
        logInfo("Finishing workout: \(duration) min, \(completedSets)/\(totalSets) sets", category: "live-workout")
        
        // Convert to Training
        let training = Training(
            date: Date.todayString(),
            type: .strength,
            durationMinutes: duration,
            programName: workout.programName,
            exercises: workout.exercises.enumerated().map { (index, activeEx) in
                let progEx = program.exercises[index]
                return TrainingExerciseEntry(
                    exerciseId: activeEx.exerciseId,
                    name: progEx.name,
                    notes: progEx.notes,
                    elapsedMs: nil,
                    sets: activeEx.sets.map { set in
                        TrainingSetEntry(
                            setNumber: set.setNumber,
                            weight: set.weight,
                            reps: set.actualReps.map { String($0) },
                            completed: set.completed,
                            completedAt: set.completedAt
                        )
                    }
                )
            },
            notes: "Live workout - \(completedSets)/\(totalSets) sets completed",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await firebaseService.addTraining(training)
            logSuccess("Saved workout to trainings", category: "live-workout")
            
            // End HealthKit workout session
            do {
                try await healthKitService.endWorkoutSession()
                logSuccess("Ended Fitness app workout tracking", category: "live-workout")
            } catch {
                logError("Failed to end Fitness tracking", error: error, category: "live-workout")
            }
            
            // Stop timers and show summary
            stopWorkoutTimer()
            stopRest()
            completedWorkout = workout
            showWorkoutSummary = true
        } catch {
            logError("Failed to save workout", error: error, category: "live-workout")
        }
    }
    
    func dismissWorkoutSummary() {
        showWorkoutSummary = false
        completedWorkout = nil
        activeWorkout = nil
        isWorkoutActive = false
        workoutStartTime = nil
        clearActiveWorkoutState()
    }
    
    // MARK: - Timer Management
    
    private func startWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateWorkoutDuration()
        }
        updateWorkoutDuration()
    }
    
    private func stopWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }
    
    private func updateWorkoutDuration() {
        guard let startTime = workoutStartTime,
              let workout = activeWorkout else { return }
        
        // Don't update if paused
        if workout.paused { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let pausedSeconds = Double(workout.totalPausedMs ?? 0) / 1000.0
        let activeElapsed = elapsed - pausedSeconds
        
        let minutes = Int(activeElapsed) / 60
        let seconds = Int(activeElapsed) % 60
        workoutDuration = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func workoutDurationMinutes() -> Int {
        guard let startTime = workoutStartTime,
              let workout = activeWorkout else { return 0 }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let pausedSeconds = Double(workout.totalPausedMs ?? 0) / 1000.0
        let activeElapsed = elapsed - pausedSeconds
        
        return Int(activeElapsed) / 60
    }
    
    func startRest(seconds: Int, label: String) {
        isResting = true
        restTimeRemaining = seconds
        restLabel = label
        
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.restTimeRemaining > 0 {
                self.restTimeRemaining -= 1
                // Play warning beeps at 5 seconds
                if self.restTimeRemaining == 5 {
                    self.playRestWarningBeeps()
                }
            } else {
                self.playRestCompleteBeeps()
                self.stopRest()
            }
        }
        
        logInfo("Rest started: \(seconds)s - \(label)", category: "live-workout")
    }
    
    private func playRestWarningBeeps() {
        // Configure audio session to play even on silent
        configureAudioSession()
        
        // Play beep beep at 5 seconds remaining
        let beepPattern: [TimeInterval] = [0, 0.25]
        
        for delay in beepPattern {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                AudioServicesPlaySystemSound(1057) // System beep sound
            }
        }
    }
    
    private func playRestCompleteBeeps() {
        // Configure audio session to play even on silent
        configureAudioSession()
        
        // Play beep beep beep - pause - beep beep beep pattern
        let beepPattern: [TimeInterval] = [0, 0.25, 0.5, 0.9, 1.15, 1.4]
        
        for (index, delay) in beepPattern.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                AudioServicesPlaySystemSound(1057) // System beep sound
            }
        }
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            logError("Failed to configure audio session", error: error, category: "live-workout")
        }
    }
    
    func stopRest() {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
        restTimeRemaining = 0
        logInfo("Rest stopped", category: "live-workout")
    }
    
    func addRestTime(seconds: Int) {
        restTimeRemaining += seconds
        logInfo("Added \(seconds)s to rest", category: "live-workout")
    }
    
    // MARK: - State Persistence
    
    private func saveActiveWorkoutState() {
        guard let workout = activeWorkout else { return }
        
        // Cancel previous save task to debounce
        saveWorkTask?.cancel()
        
        // Save on background thread to avoid blocking UI
        saveWorkTask = Task.detached(priority: .background) {
            guard let encoded = try? JSONEncoder().encode(workout) else { return }
            UserDefaults.standard.set(encoded, forKey: "activeWorkout")
        }
    }
    
    private func loadActiveWorkout() {
        guard let data = UserDefaults.standard.data(forKey: "activeWorkout"),
              let workout = try? JSONDecoder().decode(ActiveWorkout.self, from: data) else {
            return
        }
        
        activeWorkout = workout
        isWorkoutActive = true
        workoutStartTime = workout.startTime
        startWorkoutTimer()
        
        logInfo("Resumed active workout", category: "live-workout")
    }
    
    private func clearActiveWorkoutState() {
        UserDefaults.standard.removeObject(forKey: "activeWorkout")
    }
}

// MARK: - Supporting Types

enum WorkoutTab {
    case start
    case build
}

