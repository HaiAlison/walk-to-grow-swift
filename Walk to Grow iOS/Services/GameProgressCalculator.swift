//
//  GameProgressCalculator.swift
//  Walk to Grow iOS
//

import Foundation
import CoreGraphics

enum GameProgressCalculator {
    static let dailyStepTarget = 8000
    private static let stepsPerCoin = 100
    private static let stepsPerEnergy = 150

    static func progress(for steps: Int) -> CGFloat {
        guard dailyStepTarget > 0 else { return 0 }
        let rawProgress = CGFloat(steps) / CGFloat(dailyStepTarget)
        return min(max(rawProgress, 0), 1)
    }

    static func coin(from steps: Int) -> Int {
        guard stepsPerCoin > 0 else { return 0 }
        return max(steps, 0) / stepsPerCoin
    }

    static func energy(from steps: Int) -> Int {
        guard stepsPerEnergy > 0 else { return 0 }
        return max(steps, 0) / stepsPerEnergy
    }
}
