//
//  DefaultPrograms.swift
//  HomebaseApp
//
//  Default Push/Pull/Legs workout programs
//

import Foundation

struct DefaultPrograms {
    static func createAll() async {
        let firebase = FirebaseService.shared
        
        // Check if programs already exist
        guard firebase.workoutPrograms.isEmpty else {
            logInfo("Default programs already exist, skipping creation", category: "defaults")
            return
        }
        
        logInfo("Creating default workout programs", category: "defaults")
        
        for program in allPrograms {
            do {
                try await firebase.addWorkoutProgram(program)
                logSuccess("Created: \(program.displayName)", category: "defaults")
            } catch {
                logError("Failed to create program", error: error, category: "defaults")
            }
        }
    }
    
    static var allPrograms: [WorkoutProgram] {
        [pushProgram, pullProgram, legsProgram]
    }
    
    // MARK: - Push Program
    
    static var pushProgram: WorkoutProgram {
        WorkoutProgram(
            name: .push,
            displayName: "Push: Power + Shoulder Care",
            exercises: [
                Exercise(
                    id: "push-warmup-external-rotations",
                    name: "Dumbbell External Rotations",
                    sets: 2,
                    reps: "15 each arm",
                    restTime: 45,
                    notes: "Rotator cuff rehab; control, not strength.",
                    exerciseType: .flexibility
                ),
                Exercise(
                    id: "push-a-bench-press",
                    name: "Bench Press",
                    sets: 4,
                    reps: "5",
                    restTime: 150,
                    notes: "Power/Strength; heavy focus.",
                    exerciseType: .power
                ),
                Exercise(
                    id: "push-b-incline-dumbbell-press",
                    name: "Incline Dumbbell Press",
                    sets: 3,
                    reps: "8-10",
                    restTime: 90,
                    notes: "Hypertrophy; shoulder-friendly ROM.",
                    exerciseType: .hypertrophy
                ),
                Exercise(
                    id: "push-c-stand-ohp",
                    name: "Dumbbell Overhead Press (Standing)",
                    sets: 3,
                    reps: "8-10",
                    restTime: 90,
                    notes: "Shoulders; controlled tempo.",
                    exerciseType: .compound
                ),
                Exercise(
                    id: "push-d1-reverse-fly",
                    name: "Incline Dumbbell Reverse Fly",
                    sets: 3,
                    reps: "12-15",
                    restTime: 60,
                    notes: "Rear delt/cuff health; squeeze shoulder blades.",
                    exerciseType: .hypertrophy
                ),
                Exercise(
                    id: "push-d2-weighted-dips",
                    name: "Weighted Dips",
                    sets: 3,
                    reps: "8-12",
                    restTime: 90,
                    notes: "Compound triceps/chest; control depth to avoid shoulder pain.",
                    exerciseType: .compound
                )
            ],
            createdAt: Date(),
            source: "default"
        )
    }
    
    // MARK: - Pull Program
    
    static var pullProgram: WorkoutProgram {
        WorkoutProgram(
            name: .pull,
            displayName: "Pull: Strength + Grip",
            exercises: [
                Exercise(
                    id: "pull-warmup-scapular-pullups",
                    name: "Scapular Pull-ups (or Hangs)",
                    sets: 2,
                    reps: "10",
                    restTime: 45,
                    notes: "Shoulder blade control; depress shoulders fully.",
                    exerciseType: .flexibility
                ),
                Exercise(
                    id: "pull-a-deadlift",
                    name: "Deadlift (Conventional or Sumo)",
                    sets: 4,
                    reps: "3-5",
                    restTime: 180,
                    notes: "Power/full-body strength; prioritize form.",
                    exerciseType: .power
                ),
                Exercise(
                    id: "pull-b-weighted-pullups",
                    name: "Weighted Pull-ups (or Band-Assisted)",
                    sets: 4,
                    reps: "5-8",
                    restTime: 120,
                    notes: "Strength/back width; progress weight or assistance.",
                    exerciseType: .power
                ),
                Exercise(
                    id: "pull-c-single-arm-rows",
                    name: "Single-Arm Dumbbell Rows",
                    sets: 3,
                    reps: "10-12 each arm",
                    restTime: 90,
                    notes: "Unilateral back; stability.",
                    exerciseType: .compound
                ),
                Exercise(
                    id: "pull-d1-bicep-curl",
                    name: "Dumbbell Bicep Curl",
                    sets: 3,
                    reps: "10-12",
                    restTime: 60,
                    notes: "Biceps focus.",
                    exerciseType: .hypertrophy
                ),
                Exercise(
                    id: "pull-d2-farmers-carries",
                    name: "Dumbbell Farmer's Carries",
                    sets: 3,
                    reps: "40-60 sec",
                    restTime: 75,
                    notes: "Grip/core/traps; walk for time or distance.",
                    exerciseType: .compound
                )
            ],
            createdAt: Date(),
            source: "default"
        )
    }
    
    // MARK: - Legs Program
    
    static var legsProgram: WorkoutProgram {
        WorkoutProgram(
            name: .legs,
            displayName: "Legs: Mobility + Strength",
            exercises: [
                Exercise(
                    id: "legs-warmup-straight-leg-raise",
                    name: "Active Straight Leg Raise & 90/90 Hip Rotations",
                    sets: 1,
                    reps: "5 mins",
                    restTime: 30,
                    notes: "Leg mobility; gentle ROM increase.",
                    exerciseType: .flexibility
                ),
                Exercise(
                    id: "legs-a-goblet-squat",
                    name: "Goblet Squat (or Box Squat)",
                    sets: 4,
                    reps: "8-12",
                    restTime: 120,
                    notes: "Mobility-friendly; box limits depth safely.",
                    exerciseType: .compound
                ),
                Exercise(
                    id: "legs-b-reverse-lunge",
                    name: "Reverse Lunges (or Split Squats)",
                    sets: 3,
                    reps: "10-12 each leg",
                    restTime: 90,
                    notes: "Unilateral/stability; knee/hip friendly.",
                    exerciseType: .compound
                ),
                Exercise(
                    id: "legs-c1-dumbbell-rdl",
                    name: "Dumbbell RDL (Romanian Deadlift)",
                    sets: 3,
                    reps: "10-12",
                    restTime: 90,
                    notes: "Hamstrings/hips; slow, controlled hinge.",
                    exerciseType: .hypertrophy
                ),
                Exercise(
                    id: "legs-c2-low-box-jumps",
                    name: "Low Box Jumps/Step-ups",
                    sets: 3,
                    reps: "8-10",
                    restTime: 75,
                    notes: "Plyometric/quads; soft landings or quick step-ups.",
                    exerciseType: .power
                ),
                Exercise(
                    id: "legs-d-calves-core",
                    name: "Calves/Core Circuit",
                    sets: 3,
                    reps: "Calf raises + plank 30-60s",
                    restTime: 45,
                    notes: "Standing calf raises (with DBs) plus plank (30-60 sec).",
                    exerciseType: .compound
                )
            ],
            createdAt: Date(),
            source: "default"
        )
    }
}

