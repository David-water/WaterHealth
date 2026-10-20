import Foundation
#if os(iOS)
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    @Published var isLoading = false
    @Published var status = "尚未同步"
    private let health = HKHealthStore()
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func connect(to store: HealthStore) async {
        guard isAvailable else { status = "当前设备不支持 Apple 健康。"; return }
        isLoading = true
        defer { isLoading = false }
        do {
            let heart = HKQuantityType(.restingHeartRate)
            let oxygen = HKQuantityType(.oxygenSaturation)
            let steps = HKQuantityType(.stepCount)
            let systolic = HKQuantityType(.bloodPressureSystolic)
            let diastolic = HKQuantityType(.bloodPressureDiastolic)
            try await health.requestAuthorization(toShare: [], read: [heart, oxygen, steps, systolic, diastolic])
            var result: [ImportedReading] = []
            for (type, id, unit, scale) in [
                (heart, "heartRate", HKUnit.count().unitDivided(by: .minute()), 1.0),
                (oxygen, "oxygen", HKUnit.percent(), 100.0),
                (systolic, "systolic", HKUnit.millimeterOfMercury(), 1.0),
                (diastolic, "diastolic", HKUnit.millimeterOfMercury(), 1.0)
            ] {
                let samples = try await samples(type: type)
                result += samples.map { ImportedReading(metricID: id, reading: Reading(date: $0.endDate, value: $0.quantity.doubleValue(for: unit) * scale, source: "Apple 健康")) }
            }
            // Statistics query aggregates step samples across sources using HealthKit's merging rules.
            let start = Calendar.current.startOfDay(for: .now)
            let end = Date.now
            if let count = try await dailySteps(type: steps, start: start, end: end) {
                result.append(ImportedReading(metricID: "steps", reading: Reading(date: start, value: count, source: "Apple 健康 · 今日汇总")))
            }
            // Replace today's aggregate instead of accumulating duplicate totals on every sync.
            let success = store.commit { next in
                for item in result {
                    guard let i = next.metrics.firstIndex(where: { $0.id == item.metricID }) else { continue }
                    if item.metricID == "steps" { next.metrics[i].readings.removeAll { $0.source == item.reading.source && $0.date == item.reading.date } }
                    if !next.metrics[i].readings.contains(where: { $0.source == item.reading.source && $0.date == item.reading.date && $0.value == item.reading.value }) {
                        next.metrics[i].readings.append(item.reading)
                        next.metrics[i].readings.sort { $0.date < $1.date }
                    }
                }
            }
            status = success ? (result.isEmpty ? "未读取到记录。可能尚无数据，或未授予读取权限。" : "已同步 \(result.count) 条可读取的记录") : "同步结果未能保存。"
        } catch { status = "同步失败：\(error.localizedDescription)" }
    }
    private func samples(type: HKQuantityType) async throws -> [HKQuantitySample] {
        let from = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: from, end: .now)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1000, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { _, samples, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: samples as? [HKQuantitySample] ?? []) }
            }
            health.execute(query)
        }
    }
    private func dailySteps(type: HKQuantityType, start: Date, end: Date) async throws -> Double? {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: end), options: .cumulativeSum) { _, stats, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: .count())) }
            }
            health.execute(query)
        }
    }
}
#endif
