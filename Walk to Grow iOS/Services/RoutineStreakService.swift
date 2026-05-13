//
//  RoutineStreakService.swift
//  Walk to Grow iOS
//

import Foundation

enum RoutineStreakUpdateResult {
    case increased
    case alreadyCountedToday
    case notInSelectedRoutine
}

struct RoutineStreakService {
    let stepGoal: Int
    private let calendar: Calendar

    init(stepGoal: Int, calendar: Calendar = .current) {
        self.stepGoal = stepGoal
        self.calendar = calendar
    }

    mutating func evaluateForCurrentDate(_ date: Date, state: inout RoutineStreakState) {
        guard let expectedDate = expectedNextRoutineDate(from: state) else { return }
        let startOfToday = calendar.startOfDay(for: date)
        if expectedDate < startOfToday {
            state.currentStreak = 0
            state.completedRoutineDates = []
            state.lastQualifiedDate = nil
        }
    }

    mutating func recordProgressIfNeeded(
        steps: Int,
        on date: Date,
        state: inout RoutineStreakState
    ) -> RoutineStreakUpdateResult {
        evaluateForCurrentDate(date, state: &state)

        let dayStart = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: dayStart)

        guard state.selectedWeekdays.contains(weekday) else {
            return .notInSelectedRoutine
        }
        guard steps >= stepGoal else {
            return .notInSelectedRoutine
        }
        guard !state.completedRoutineDates.contains(dayStart) else {
            return .alreadyCountedToday
        }

        if let expected = expectedNextRoutineDate(from: state), expected < dayStart {
            state.currentStreak = 0
            state.completedRoutineDates = []
            state.lastQualifiedDate = nil
        }

        if let expected = expectedNextRoutineDate(from: state), calendar.isDate(expected, inSameDayAs: dayStart) {
            state.currentStreak += 1
        } else if state.currentStreak == 0 {
            state.currentStreak = 1
        } else {
            state.currentStreak += 1
        }

        state.completedRoutineDates.insert(dayStart)
        state.lastQualifiedDate = dayStart
        state.longestStreak = max(state.longestStreak, state.currentStreak)
        return .increased
    }

    private func expectedNextRoutineDate(from state: RoutineStreakState) -> Date? {
        guard let lastQualifiedDate = state.lastQualifiedDate else {
            return nil
        }

        var candidate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lastQualifiedDate))
        while let date = candidate {
            let weekday = calendar.component(.weekday, from: date)
            if state.selectedWeekdays.contains(weekday) {
                return date
            }
            candidate = calendar.date(byAdding: .day, value: 1, to: date)
        }
        return nil
    }
}
