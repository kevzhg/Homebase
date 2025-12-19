//
//  Training.swift
//  HomebaseApp
//
//  Data models for training/workout tracking
//

import Foundation
import FirebaseFirestore

// MARK: - Enums

enum TrainingType: String, Codable, CaseIterable {
    case strength
    case cardio
    case hiit
    case yoga
    case stretching
    case sports
    case other
    
    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .hiit: return "HIIT"
        case .yoga: return "Yoga"
        case .stretching: return "Stretching"
        case .sports: return "Sports"
        case .other: return "Other"
        }
    }
}

enum ProgramType: String, Codable, CaseIterable {
    case push
    case pull
    case legs
    
    var displayName: String {
        rawValue.capitalized
    }
}

enum ExerciseType: String, Codable, CaseIterable {
    case power
    case hypertrophy
    case compound
    case flexibility
    case cardio
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Training Models

struct TrainingSetEntry: Codable, Identifiable {
    var id: String { "\(setNumber)" }
    var setNumber: Int
    var weight: Double?
    var reps: String? // Can be "8" or "8-12"
    var completed: Bool
    var completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case setNumber, weight, reps, completed, completedAt
    }
}

struct TrainingExerciseEntry: Codable, Identifiable {
    var id: String { exerciseId }
    var exerciseId: String
    var name: String
    var notes: String?
    var elapsedMs: Int?
    var sets: [TrainingSetEntry]
    
    enum CodingKeys: String, CodingKey {
        case exerciseId, name, notes, elapsedMs, sets
    }
}

struct Training: Codable, Identifiable {
    var id: String?
    var date: String // YYYY-MM-DD format
    var type: TrainingType
    var durationMinutes: Int
    var programName: String?
    var exercises: [TrainingExerciseEntry]
    var notes: String?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, date, type, durationMinutes, programName, exercises, notes, createdAt, updatedAt
    }
    
    // Helper to get Date object from date string
    var dateObject: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
    
    // Helper to format date for display
    var formattedDate: String {
        guard let dateObj = dateObject else { return date }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateObj)
    }
}

// MARK: - Workout Program Models (for Live Workout)

struct Exercise: Codable, Identifiable {
    var id: String
    var name: String
    var sets: Int
    var reps: String // e.g., "8" or "8-12"
    var restTime: Int // seconds
    var notes: String?
    var exerciseType: ExerciseType?
    
    enum CodingKeys: String, CodingKey {
        case id, name, sets, reps, restTime, notes, exerciseType
    }
}

struct ExerciseLibraryItem: Codable, Identifiable {
    var id: String
    var name: String
    var sets: Int
    var reps: String
    var restTime: Int
    var notes: String?
    var exerciseType: ExerciseType?
    var category: ProgramType
    var muscles: [String]?
    var equipment: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, sets, reps, restTime, notes, exerciseType, category, muscles, equipment
    }
}

struct WorkoutProgram: Codable, Identifiable {
    var id: String?
    var name: ProgramType
    var displayName: String
    var exercises: [Exercise]
    var createdAt: Date
    var updatedAt: Date?
    var source: String? // "local" or "api"
    
    enum CodingKeys: String, CodingKey {
        case id, name, displayName, exercises, createdAt, updatedAt, source
    }
}

// MARK: - Active Workout Models (for Live Workout Session)

struct ExerciseSet: Codable, Identifiable {
    var id: String { "\(setNumber)" }
    var setNumber: Int
    var completed: Bool
    var completedAt: Date?
    var weight: Double?
    var actualReps: Int?
    var partial: Bool?
    
    enum CodingKeys: String, CodingKey {
        case setNumber, completed, completedAt, weight, actualReps, partial
    }
}

struct ActiveExercise: Codable, Identifiable {
    var id: String { exerciseId }
    var exerciseId: String
    var sets: [ExerciseSet]
    var currentSet: Int
    var elapsedMs: Int?
    
    enum CodingKeys: String, CodingKey {
        case exerciseId, sets, currentSet, elapsedMs
    }
}

struct ActiveWorkout: Codable {
    var programId: String
    var programName: String
    var startTime: Date
    var exercises: [ActiveExercise]
    var currentExerciseIndex: Int
    var isResting: Bool
    var restStartTime: Date?
    var restDuration: Int? // milliseconds
    var restLabel: String?
    var paused: Bool
    var pauseStartedAt: Date?
    var totalPausedMs: Int?
    
    enum CodingKeys: String, CodingKey {
        case programId, programName, startTime, exercises, currentExerciseIndex
        case isResting, restStartTime, restDuration, restLabel
        case paused, pauseStartedAt, totalPausedMs
    }
}

// MARK: - Helper Extensions

extension Training {
    // Create a new training from an active workout
    static func from(activeWorkout: ActiveWorkout, date: String, durationMinutes: Int) -> Training {
        let exercises = activeWorkout.exercises.map { activeEx in
            // Find the exercise name from the program (would need to pass program)
            TrainingExerciseEntry(
                exerciseId: activeEx.exerciseId,
                name: activeEx.exerciseId, // TODO: Get actual name from program
                notes: nil,
                elapsedMs: activeEx.elapsedMs,
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
        }
        
        return Training(
            date: date,
            type: .strength,
            durationMinutes: durationMinutes,
            programName: activeWorkout.programName,
            exercises: exercises,
            notes: "Live workout session",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Date Helpers

extension String {
    // Convert YYYY-MM-DD string to Date
    func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: self)
    }
}

extension Date {
    // Convert Date to YYYY-MM-DD string
    func toDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    // Get today's date string
    static func todayString() -> String {
        Date().toDateString()
    }
}

