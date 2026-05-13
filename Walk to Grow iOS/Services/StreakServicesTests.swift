//
//  StreakServicesTests.swift
//  Walk to Grow iOS
//

#if canImport(XCTest)
import Foundation
import XCTest

final class RoutineStreakServiceTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    }

    func testRoutineDayHitGoalIncreasesStreak() {
        var service = RoutineStreakService(stepGoal: 8000, calendar: calendar)
        var state = RoutineStreakState(
            selectedWeekdays: [2, 4],
            currentStreak: 0,
            longestStreak: 0,
            lastQualifiedDate: nil,
            completedRoutineDates: []
        )

        let monday = makeDate(2026, 5, 4)
        let result = service.recordProgressIfNeeded(steps: 8000, on: monday, state: &state)

        if case .increased = result {
            XCTAssertEqual(state.currentStreak, 1)
        } else {
            XCTFail("Expected increased result")
        }
    }

    func testMissingASelectedRoutineDayResetsStreak() {
        var service = RoutineStreakService(stepGoal: 8000, calendar: calendar)
        var state = RoutineStreakState(
            selectedWeekdays: [2, 4],
            currentStreak: 1,
            longestStreak: 1,
            lastQualifiedDate: makeDate(2026, 5, 4),  // Monday
            completedRoutineDates: [makeDate(2026, 5, 4)]
        )

        let friday = makeDate(2026, 5, 8)  // Missed Wednesday routine day.
        service.evaluateForCurrentDate(friday, state: &state)

        XCTAssertEqual(state.currentStreak, 0)
        XCTAssertNil(state.lastQualifiedDate)
    }

    func testNonRoutineDayDoesNotAffectStreak() {
        var service = RoutineStreakService(stepGoal: 8000, calendar: calendar)
        var state = RoutineStreakState(
            selectedWeekdays: [2, 4],
            currentStreak: 2,
            longestStreak: 2,
            lastQualifiedDate: makeDate(2026, 5, 6),
            completedRoutineDates: [makeDate(2026, 5, 4), makeDate(2026, 5, 6)]
        )

        let thursday = makeDate(2026, 5, 7)
        _ = service.recordProgressIfNeeded(steps: 9000, on: thursday, state: &state)

        XCTAssertEqual(state.currentStreak, 2)
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day
        )
        return components.date ?? Date()
    }
}

final class DailyCheckinServiceTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    }

    func testClaimOnTwoConsecutiveDaysIncreasesStreak() {
        var service = DailyCheckinService(calendar: calendar)
        var state = DailyCheckinState.default()

        let day1 = makeDate(2026, 5, 1)
        let day2 = makeDate(2026, 5, 2)
        _ = service.claim(on: day1, state: &state)
        _ = service.claim(on: day2, state: &state)

        XCTAssertEqual(state.currentStreak, 2)
    }

    func testMissingOneDayResetsStreakBeforeClaim() {
        var service = DailyCheckinService(calendar: calendar)
        var state = DailyCheckinState(currentStreak: 3, longestStreak: 3, lastCheckinDate: makeDate(2026, 5, 1))

        service.evaluateForCurrentDate(makeDate(2026, 5, 3), state: &state)
        XCTAssertEqual(state.currentStreak, 0)
    }

    func testSecondClaimInSameDayIsRejected() {
        var service = DailyCheckinService(calendar: calendar)
        var state = DailyCheckinState.default()
        let day = makeDate(2026, 5, 1)

        _ = service.claim(on: day, state: &state)
        let second = service.claim(on: day, state: &state)

        if case .alreadyClaimedToday = second {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected alreadyClaimedToday")
        }
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day
        )
        return components.date ?? Date()
    }
}
#endif
