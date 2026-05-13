//
//  StreakPersistence.swift
//  Walk to Grow iOS
//

import Foundation

struct StreakPersistenceSnapshot: Codable {
    var routine: RoutineStreakState
    var checkin: DailyCheckinState
}

protocol StreakPersistenceRepository {
    func load() -> StreakPersistenceSnapshot?
    func save(_ snapshot: StreakPersistenceSnapshot)
}

final class UserDefaultsStreakRepository: StreakPersistenceRepository {
    private enum Keys {
        static let streakSnapshot = "streak_progress_snapshot"
    }

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func load() -> StreakPersistenceSnapshot? {
        guard let data = userDefaults.data(forKey: Keys.streakSnapshot) else {
            return nil
        }
        return try? decoder.decode(StreakPersistenceSnapshot.self, from: data)
    }

    func save(_ snapshot: StreakPersistenceSnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }
        userDefaults.set(data, forKey: Keys.streakSnapshot)
    }
}
