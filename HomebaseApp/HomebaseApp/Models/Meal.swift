//
//  Meal.swift
//  HomebaseApp
//
//  Data models for meal tracking
//

import Foundation
import FirebaseFirestore

// MARK: - Enums

enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var emoji: String {
        switch self {
        case .breakfast: return "🌅"
        case .lunch: return "☀️"
        case .dinner: return "🌙"
        case .snack: return "🍎"
        }
    }
}

// MARK: - Meal Model

struct Meal: Codable, Identifiable {
    var id: String?
    var date: String // YYYY-MM-DD format
    var type: MealType
    var name: String
    var calories: Int?
    var protein: Int?
    var description: String?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, date, type, name, calories, protein, description, createdAt, updatedAt
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
    
    // Display string for macros
    var macrosDisplay: String {
        var parts: [String] = []
        if let cal = calories {
            parts.append("\(cal) cal")
        }
        if let prot = protein {
            parts.append("\(prot)g protein")
        }
        return parts.isEmpty ? "No macros logged" : parts.joined(separator: " • ")
    }
}

// MARK: - Meal Summary Helpers

extension Array where Element == Meal {
    // Get meals for a specific date
    func forDate(_ dateString: String) -> [Meal] {
        filter { $0.date == dateString }
    }
    
    // Get total calories for a date
    func totalCalories(for dateString: String) -> Int {
        forDate(dateString)
            .compactMap { $0.calories }
            .reduce(0, +)
    }
    
    // Get total protein for a date
    func totalProtein(for dateString: String) -> Int {
        forDate(dateString)
            .compactMap { $0.protein }
            .reduce(0, +)
    }
    
    // Group meals by date
    func groupedByDate() -> [String: [Meal]] {
        Dictionary(grouping: self) { $0.date }
    }
    
    // Get meals for the last N days
    func lastDays(_ days: Int) -> [Meal] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let cutoffString = cutoffDate.toDateString()
        
        return filter { $0.date >= cutoffString }
            .sorted { $0.date > $1.date }
    }
}

