//
//  HealthKitStepService.swift
//  Walk to Grow iOS
//

import Foundation
import HealthKit

final class HealthKitStepService {
    static let shared = HealthKitStepService()

    private let healthStore = HKHealthStore()
    private let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)

    private init() {}

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        guard isHealthDataAvailable, let stepType else {
            completion(false)
            return
        }
        healthStore.requestAuthorization(toShare: nil, read: [stepType]) { success, _ in
            completion(success)
        }
    }

    func fetchTodayStepCount(completion: @escaping (Int) -> Void) {
        guard isHealthDataAvailable, let stepType else {
            completion(0)
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            let unit = HKUnit.count()
            let steps = Int(result?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            completion(max(steps, 0))
        }

        healthStore.execute(query)
    }
}
