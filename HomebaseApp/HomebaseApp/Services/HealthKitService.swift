//
//  HealthKitService.swift
//  HomebaseApp
//
//  HealthKit integration for workout tracking in Fitness app
//

import Foundation
import HealthKit

class HealthKitService {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    var isAuthorized = false
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        self.isAuthorized = true
    }
    
    // MARK: - Workout Session
    
    func startWorkoutSession(workoutType: ProgramType) async throws {
        // Determine HKWorkoutActivityType based on workout category
        let activityType: HKWorkoutActivityType = .traditionalStrengthTraining
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = .indoor
        
        // Create workout session
        let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        let builder = session.associatedWorkoutBuilder()
        
        // Set data source
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )
        
        self.workoutSession = session
        self.workoutBuilder = builder
        
        // Start the session
        session.startActivity(with: Date())
        try await builder.beginCollection(at: Date())
    }
    
    func pauseWorkoutSession() {
        workoutSession?.pause()
    }
    
    func resumeWorkoutSession() {
        workoutSession?.resume()
    }
    
    func endWorkoutSession() async throws {
        guard let session = workoutSession,
              let builder = workoutBuilder else {
            return
        }
        
        // End the session
        session.end()
        
        // Finish collecting data
        try await builder.endCollection(at: Date())
        
        // Save the workout
        try await builder.finishWorkout()
        
        // Clean up
        self.workoutSession = nil
        self.workoutBuilder = nil
    }
    
    // MARK: - Standalone Workout Save
    
    /// Save a completed workout without live tracking
    func saveCompletedWorkout(
        workoutType: ProgramType,
        startDate: Date,
        endDate: Date,
        totalEnergyBurned: Double? = nil
    ) async throws {
        let activityType: HKWorkoutActivityType = .traditionalStrengthTraining
        
        var samples: [HKSample] = []
        
        // Add energy burned if available
        if let calories = totalEnergyBurned {
            let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let energySample = HKQuantitySample(
                type: energyType,
                quantity: energyQuantity,
                start: startDate,
                end: endDate
            )
            samples.append(energySample)
        }
        
        // Create the workout
        let workout = HKWorkout(
            activityType: activityType,
            start: startDate,
            end: endDate,
            duration: endDate.timeIntervalSince(startDate),
            totalEnergyBurned: totalEnergyBurned.map { HKQuantity(unit: .kilocalorie(), doubleValue: $0) },
            totalDistance: nil,
            metadata: [
                HKMetadataKeyIndoorWorkout: true
            ]
        )
        
        try await healthStore.save(workout)
        
        // Add samples if any
        if !samples.isEmpty {
            try await healthStore.addSamples(samples, to: workout)
        }
    }
}

enum HealthKitError: Error {
    case notAvailable
    case notAuthorized
    case sessionNotStarted
}
