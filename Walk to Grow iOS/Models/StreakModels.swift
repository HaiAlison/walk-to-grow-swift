//
//  StreakModels.swift
//  Walk to Grow iOS
//

import Foundation

struct RoutineStreakState: Codable {
    var selectedWeekdays: Set<Int>
    var currentStreak: Int
    var longestStreak: Int
    var lastQualifiedDate: Date?
    var completedRoutineDates: Set<Date>

    static func `default`() -> RoutineStreakState {
        // Default routine: Monday -> Friday.
        RoutineStreakState(
            selectedWeekdays: [2, 3, 4, 5, 6],
            currentStreak: 0,
            longestStreak: 0,
            lastQualifiedDate: nil,
            completedRoutineDates: []
        )
    }
}

struct DailyCheckinState: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastCheckinDate: Date?

    static func `default`() -> DailyCheckinState {
        DailyCheckinState(
            currentStreak: 0,
            longestStreak: 0,
            lastCheckinDate: nil
        )
    }
}

struct DailyCheckinReward {
    let coins: Int
}
