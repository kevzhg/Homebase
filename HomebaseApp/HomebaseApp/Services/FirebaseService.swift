//
//  FirebaseService.swift
//  HomebaseApp
//
//  Firebase service for CRUD operations on trainings, meals, and weight entries
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import Combine

@MainActor
class FirebaseService: ObservableObject {
    // Singleton instance
    static let shared = FirebaseService()
    
    // Published properties for real-time updates
    @Published var trainings: [Training] = []
    @Published var meals: [Meal] = []
    @Published var weightEntries: [WeightEntry] = []
    @Published var workoutPrograms: [WorkoutProgram] = []
    @Published var exerciseLibrary: [ExerciseLibraryItem] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOnline = true
    
    // Firestore reference
    // Option 1: Use default database (recommended)
    // private let db = Firestore.firestore()
    
    // Option 2: Use named database "homedb"
    private let db = Firestore.firestore(database: "homedb")
    
    // User ID (for now, using a default user; later integrate Firebase Auth)
    private var userId: String {
        // TODO: Replace with actual authenticated user ID
        // For now, use a default user ID for testing
        "default_user"
    }
    
    // Firestore listeners
    private var trainingsListener: ListenerRegistration?
    private var mealsListener: ListenerRegistration?
    private var weightListener: ListenerRegistration?
    private var programsListener: ListenerRegistration?
    private var exercisesListener: ListenerRegistration?
    private var connectionListener: ListenerRegistration?
    
    private init() {
        logInfo("🔥 Initializing FirebaseService", category: "firebase")
        startConnectionMonitoring()
        logSuccess("FirebaseService initialized", category: "firebase")
    }
    
    // MARK: - Start Listeners
    
    func startListening() {
        logInfo("📡 Starting Firebase listeners", category: "firebase")
        startTrainingsListener()
        startMealsListener()
        startWeightListener()
        startProgramsListener()
        startExerciseLibraryListener()
    }
    
    func stopListening() {
        trainingsListener?.remove()
        mealsListener?.remove()
        weightListener?.remove()
        programsListener?.remove()
        exercisesListener?.remove()
        connectionListener?.remove()
    }
    
    // MARK: - Connection Monitoring
    
    private func startConnectionMonitoring() {
        // Monitor network reachability by listening to any collection
        // If we get snapshot updates, we're online
        connectionListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error as NSError? {
                    // Error code 14 = UNAVAILABLE (offline)
                    self.isOnline = error.code != 14
                } else {
                    // Successfully received snapshot = online
                    self.isOnline = true
                }
            }
    }
    
    // MARK: - Training Operations
    
    private func startTrainingsListener() {
        trainingsListener = db.collection("users").document(userId)
            .collection("trainings")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error loading trainings: \(error.localizedDescription)"
                    logError("Failed to load trainings", error: error, category: "firebase")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.trainings = documents.compactMap { doc in
                    var training = try? doc.data(as: Training.self)
                    training?.id = doc.documentID
                    return training
                }
                
                logSuccess("Loaded \(self.trainings.count) trainings", category: "firebase")
            }
    }
    
    func addTraining(_ training: Training) async throws {
        var newTraining = training
        newTraining.createdAt = Date()
        newTraining.updatedAt = Date()
        
        let _ = try db.collection("users").document(userId)
            .collection("trainings")
            .addDocument(from: newTraining)
    }
    
    func updateTraining(_ training: Training) async throws {
        guard let id = training.id else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Training ID is nil"])
        }
        
        var updatedTraining = training
        updatedTraining.updatedAt = Date()
        
        try db.collection("users").document(userId)
            .collection("trainings")
            .document(id)
            .setData(from: updatedTraining, merge: true)
    }
    
    func deleteTraining(_ id: String) async throws {
        try await db.collection("users").document(userId)
            .collection("trainings")
            .document(id)
            .delete()
    }
    
    func getTrainings(forDate date: String) -> [Training] {
        trainings.filter { $0.date == date }
    }
    
    // MARK: - Meal Operations
    
    private func startMealsListener() {
        mealsListener = db.collection("users").document(userId)
            .collection("meals")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error loading meals: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.meals = documents.compactMap { doc in
                    var meal = try? doc.data(as: Meal.self)
                    meal?.id = doc.documentID
                    return meal
                }
            }
    }
    
    func addMeal(_ meal: Meal) async throws {
        var newMeal = meal
        newMeal.createdAt = Date()
        newMeal.updatedAt = Date()
        
        let _ = try db.collection("users").document(userId)
            .collection("meals")
            .addDocument(from: newMeal)
    }
    
    func updateMeal(_ meal: Meal) async throws {
        guard let id = meal.id else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Meal ID is nil"])
        }
        
        var updatedMeal = meal
        updatedMeal.updatedAt = Date()
        
        try db.collection("users").document(userId)
            .collection("meals")
            .document(id)
            .setData(from: updatedMeal, merge: true)
    }
    
    func deleteMeal(_ id: String) async throws {
        try await db.collection("users").document(userId)
            .collection("meals")
            .document(id)
            .delete()
    }
    
    func getMeals(forDate date: String) -> [Meal] {
        meals.filter { $0.date == date }
    }
    
    // MARK: - Weight Entry Operations
    
    private func startWeightListener() {
        weightListener = db.collection("users").document(userId)
            .collection("weightEntries")
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error loading weight entries: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.weightEntries = documents.compactMap { doc in
                    var entry = try? doc.data(as: WeightEntry.self)
                    entry?.id = doc.documentID
                    return entry
                }
            }
    }
    
    func addWeightEntry(_ entry: WeightEntry) async throws {
        var newEntry = entry
        newEntry.createdAt = Date()
        newEntry.updatedAt = Date()
        
        let _ = try db.collection("users").document(userId)
            .collection("weightEntries")
            .addDocument(from: newEntry)
    }
    
    func updateWeightEntry(_ entry: WeightEntry) async throws {
        guard let id = entry.id else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Weight entry ID is nil"])
        }
        
        var updatedEntry = entry
        updatedEntry.updatedAt = Date()
        
        try db.collection("users").document(userId)
            .collection("weightEntries")
            .document(id)
            .setData(from: updatedEntry, merge: true)
    }
    
    func deleteWeightEntry(_ id: String) async throws {
        try await db.collection("users").document(userId)
            .collection("weightEntries")
            .document(id)
            .delete()
    }
    
    func getWeightEntry(forDate date: String) -> WeightEntry? {
        weightEntries.first { $0.date == date }
    }
    
    // MARK: - Workout Program Operations
    
    private func startProgramsListener() {
        programsListener = db.collection("users").document(userId)
            .collection("workoutPrograms")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error loading programs: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    logInfo("No workout program documents found", category: "firebase")
                    return
                }
                
                logInfo("Loading \(documents.count) workout program documents", category: "firebase")
                
                self.workoutPrograms = documents.compactMap { doc in
                    do {
                        var program = try doc.data(as: WorkoutProgram.self)
                        program.id = doc.documentID
                        logInfo("Loaded program: \(program.displayName) (type: \(program.name.rawValue))", category: "firebase")
                        return program
                    } catch {
                        logError("Failed to decode workout program \(doc.documentID)", error: error, category: "firebase")
                        return nil
                    }
                }
                
                logInfo("Successfully loaded \(self.workoutPrograms.count) workout programs", category: "firebase")
            }
    }
    
    func addWorkoutProgram(_ program: WorkoutProgram) async throws {
        var newProgram = program
        newProgram.createdAt = Date()
        newProgram.updatedAt = Date()
        
        let _ = try db.collection("users").document(userId)
            .collection("workoutPrograms")
            .addDocument(from: newProgram)
    }
    
    func updateWorkoutProgram(_ program: WorkoutProgram) async throws {
        guard let id = program.id else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Program ID is nil"])
        }
        
        var updatedProgram = program
        updatedProgram.updatedAt = Date()
        
        try db.collection("users").document(userId)
            .collection("workoutPrograms")
            .document(id)
            .setData(from: updatedProgram, merge: true)
    }
    
    func deleteWorkoutProgram(_ id: String) async throws {
        try await db.collection("users").document(userId)
            .collection("workoutPrograms")
            .document(id)
            .delete()
    }
    
    // MARK: - Exercise Library Operations (Shared across all users)
    
    private func startExerciseLibraryListener() {
        exercisesListener = db.collection("exercises")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Error loading exercise library: \(error.localizedDescription)"
                    logError("Failed to load exercise library", error: error, category: "firebase")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    logInfo("No exercises found in library", category: "firebase")
                    return
                }
                
                self.exerciseLibrary = documents.compactMap { doc in
                    var exercise = try? doc.data(as: ExerciseLibraryItem.self)
                    exercise?.id = doc.documentID
                    return exercise
                }
                
                logSuccess("Loaded \(self.exerciseLibrary.count) exercises from library", category: "firebase")
            }
    }
    
    func addExerciseToLibrary(_ exercise: ExerciseLibraryItem) async throws {
        let _ = try await db.collection("exercises")
            .addDocument(from: exercise)
        logSuccess("Added exercise '\(exercise.name)' to library", category: "firebase")
    }
    
    func deleteExerciseFromLibrary(_ id: String) async throws {
        try await db.collection("exercises")
            .document(id)
            .delete()
        logSuccess("Deleted exercise from library", category: "firebase")
    }
    
    func updateExerciseInLibrary(_ exercise: ExerciseLibraryItem) async throws {
        guard let id = exercise.id else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Exercise ID is nil"])
        }
        
        try await db.collection("exercises")
            .document(id)
            .setData(from: exercise, merge: true)
        logSuccess("Updated exercise '\(exercise.name)' in library", category: "firebase")
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    // Get summary statistics
    func getTodayStats() -> (trainings: Int, meals: Int, calories: Int, protein: Int) {
        let today = Date.todayString()
        let todayTrainings = getTrainings(forDate: today)
        let todayMeals = getMeals(forDate: today)
        
        let totalCalories = todayMeals.compactMap { $0.calories }.reduce(0, +)
        let totalProtein = todayMeals.compactMap { $0.protein }.reduce(0, +)
        
        return (todayTrainings.count, todayMeals.count, totalCalories, totalProtein)
    }
    
    func getWeeklyStats() -> (trainings: Int, meals: Int, totalMinutes: Int) {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let weekAgoString = weekAgo.toDateString()
        
        let weekTrainings = trainings.filter { $0.date >= weekAgoString }
        let weekMeals = meals.filter { $0.date >= weekAgoString }
        let totalMinutes = weekTrainings.reduce(0) { $0 + $1.durationMinutes }
        
        return (weekTrainings.count, weekMeals.count, totalMinutes)
    }
}

