//
//  WalkingTipsContent.swift
//  Walk to Grow iOS
//

import Foundation

struct WalkingTipsDocument: Codable {
    let disclaimer: String
    let tips: [WalkingTip]
}

struct WalkingTip: Codable, Equatable {
    let id: String
    let title: String
    let body: String
    let youtubeURL: String?
    let tags: [String]?
}

enum SeriousGameTipsRepository {
    private static let resourceName = "WalkingTips"

    static func loadDocument() -> WalkingTipsDocument? {
        let url =
            Bundle.main.url(forResource: resourceName, withExtension: "json", subdirectory: "Resources")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "json")
        guard let url else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(WalkingTipsDocument.self, from: data)
        } catch {
            return nil
        }
    }

    /// Mẹo theo ngày (ổn định theo lịch, không đổi mỗi lần mở app).
    static func dailyTip(from tips: [WalkingTip], on date: Date = Date()) -> WalkingTip? {
        guard !tips.isEmpty else { return nil }
        let cal = Calendar(identifier: .gregorian)
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        let seed = y * 10_000 + m * 100 + d
        let idx = abs(seed) % tips.count
        return tips[idx]
    }
}
