//
//  WeightEntry.swift
//  HomebaseApp
//
//  Data models for weight tracking
//

import Foundation
import FirebaseFirestore

// MARK: - Enums

enum WeightUnit: String, Codable, CaseIterable {
    case lbs
    case kg
    
    var displayName: String {
        rawValue
    }
}

// MARK: - WeightEntry Model

struct WeightEntry: Codable, Identifiable {
    var id: String?
    var date: String // YYYY-MM-DD format
    var weight: Double
    var unit: WeightUnit
    var notes: String?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, date, weight, unit, notes, createdAt, updatedAt
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
    
    // Display string for weight
    var displayWeight: String {
        String(format: "%.1f %@", weight, unit.rawValue)
    }
}

// MARK: - Weight Statistics Helpers

extension Array where Element == WeightEntry {
    // Get entry for a specific date
    func forDate(_ dateString: String) -> WeightEntry? {
        first { $0.date == dateString }
    }
    
    // Get entries sorted by date (oldest first)
    func sortedByDate() -> [WeightEntry] {
        sorted { $0.date < $1.date }
    }
    
    // Get starting weight (first entry)
    var startingWeight: WeightEntry? {
        sortedByDate().first
    }
    
    // Get current weight (latest entry)
    var currentWeight: WeightEntry? {
        sortedByDate().last
    }
    
    // Calculate weight change from start to current
    var weightChange: Double? {
        guard let start = startingWeight?.weight,
              let current = currentWeight?.weight else {
            return nil
        }
        return current - start
    }
    
    // Get entries for the last N days
    func lastDays(_ days: Int) -> [WeightEntry] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let cutoffString = cutoffDate.toDateString()
        
        return filter { $0.date >= cutoffString }
            .sortedByDate()
    }
    
    // Get entries for a specific month
    func forMonth(year: Int, month: Int) -> [WeightEntry] {
        let monthString = String(format: "%04d-%02d", year, month)
        return filter { $0.date.hasPrefix(monthString) }
            .sortedByDate()
    }
    
    // Calculate average weight for a period
    func averageWeight() -> Double? {
        guard !isEmpty else { return nil }
        let total = reduce(0.0) { $0 + $1.weight }
        return total / Double(count)
    }
    
    // Get weight trend (positive = gaining, negative = losing)
    func trend(days: Int = 7) -> Double? {
        let recent = lastDays(days)
        guard recent.count >= 2,
              let first = recent.first?.weight,
              let last = recent.last?.weight else {
            return nil
        }
        return last - first
    }
}

// MARK: - Calendar Helpers

struct WeightCalendarDay {
    let date: String
    let dayNumber: Int
    let entry: WeightEntry?
    let isToday: Bool
    let isCurrentMonth: Bool
}

extension Array where Element == WeightEntry {
    // Generate calendar data for a specific month
    func calendarData(for year: Int, month: Int) -> [WeightCalendarDay] {
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        guard let firstDayOfMonth = calendar.date(from: dateComponents) else {
            return []
        }
        
        // Get first weekday and number of days in month
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1 // 0 = Sunday
        let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!
        let numDays = range.count
        
        // Get today's date string
        let todayString = Date.todayString()
        
        // Create map of date -> entry
        let entriesMap = Dictionary(uniqueKeysWithValues: map { ($0.date, $0) })
        
        var days: [WeightCalendarDay] = []
        
        // Add empty days before first of month
        for _ in 0..<firstWeekday {
            days.append(WeightCalendarDay(
                date: "",
                dayNumber: 0,
                entry: nil,
                isToday: false,
                isCurrentMonth: false
            ))
        }
        
        // Add days of the month
        for day in 1...numDays {
            let dateString = String(format: "%04d-%02d-%02d", year, month, day)
            days.append(WeightCalendarDay(
                date: dateString,
                dayNumber: day,
                entry: entriesMap[dateString],
                isToday: dateString == todayString,
                isCurrentMonth: true
            ))
        }
        
        return days
    }
}

