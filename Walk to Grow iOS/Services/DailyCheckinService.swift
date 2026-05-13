//
//  DailyCheckinService.swift
//  Walk to Grow iOS
//

import Foundation

enum DailyCheckinClaimResult {
    case claimed(DailyCheckinReward)
    case alreadyClaimedToday
}

struct DailyCheckinService {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    mutating func evaluateForCurrentDate(_ date: Date, state: inout DailyCheckinState) {
        guard let lastDate = state.lastCheckinDate else { return }
        let dayGap = dayDistance(from: lastDate, to: date)
        if dayGap > 1 {
            state.currentStreak = 0
        }
    }

    mutating func claim(on date: Date, state: inout DailyCheckinState) -> DailyCheckinClaimResult {
        evaluateForCurrentDate(date, state: &state)

        if let lastDate = state.lastCheckinDate, calendar.isDate(lastDate, inSameDayAs: date) {
            return .alreadyClaimedToday
        }

        let dayGap = state.lastCheckinDate.map { dayDistance(from: $0, to: date) } ?? 0
        if dayGap == 1 || state.lastCheckinDate == nil {
            state.currentStreak += 1
        } else {
            state.currentStreak = 1
        }

        state.lastCheckinDate = calendar.startOfDay(for: date)
        state.longestStreak = max(state.longestStreak, state.currentStreak)

        let reward = DailyCheckinReward(coins: rewardCoins(for: state.currentStreak))
        return .claimed(reward)
    }

    private func dayDistance(from start: Date, to end: Date) -> Int {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    }

    private func rewardCoins(for streak: Int) -> Int {
        min(30 + (streak - 1) * 5, 100)
    }
}
