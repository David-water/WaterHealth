import Foundation

enum ImportFailure: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case let .invalid(message) = self { return message }; return nil }
}

struct ImportedReading {
    let metricID: String
    let reading: Reading
}

enum CSVImporter {
    /// Strict schema prevents silently assigning a number to the wrong metric or unit.
    static func parse(_ data: Data, now: Date = .now) throws -> [ImportedReading] {
        guard data.count <= 2_000_000, var text = String(data: data, encoding: .utf8) else {
            throw ImportFailure.invalid("CSV 需为 UTF-8 编码，大小不超过 2 MB。")
        }
        text = text.replacingOccurrences(of: "\u{FEFF}", with: "")
        let rows = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard rows.count > 1, rows.count <= 10_001 else { throw ImportFailure.invalid("请提供 1–10000 条指标记录。") }
        guard rows[0].trimmingCharacters(in: .whitespaces) == "metric,value,unit,date" else { throw ImportFailure.invalid("表头必须为 metric,value,unit,date。请使用应用提供的模板。") }
        let formatter = ISO8601DateFormatter()
        let dateOnly = DateFormatter()
        dateOnly.dateFormat = "yyyy-MM-dd"
        dateOnly.locale = Locale(identifier: "en_US_POSIX")
        dateOnly.timeZone = TimeZone(secondsFromGMT: 0)
        dateOnly.isLenient = false
        return try rows.dropFirst().enumerated().map { index, row in
            let cols = row.split(separator: ",", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
            guard cols.count == 4, let metric = DemoData.emptyMetrics.first(where: { $0.id == cols[0] }), let value = Double(cols[1]), value.isFinite, value >= 0, value <= 1_000_000, cols[2] == metric.unit else {
                throw ImportFailure.invalid("第 \(index + 2) 行格式、指标名称、数值或单位不正确。未导入任何记录。")
            }
            guard let date = formatter.date(from: cols[3]) ?? dateOnly.date(from: cols[3]), date <= now.addingTimeInterval(86400) else {
                throw ImportFailure.invalid("第 \(index + 2) 行日期无效或超出当前日期。")
            }
            return ImportedReading(metricID: metric.id, reading: Reading(date: date, value: value, source: "CSV 手动导入"))
        }
    }
    static let template = "metric,value,unit,date\nheartRate,68,次/分,2026-10-01\nsystolic,122,mmHg,2026-10-01\ndiastolic,78,mmHg,2026-10-01\n"
}

enum HealthAssistant {
    static func reply(to input: String, state: AppState) -> String {
        let q = input.lowercased()
        if ["胸痛", "呼吸困难", "昏厥", "自杀", "急救"].contains(where: q.contains) {
            return "这些描述可能需要及时的专业帮助。若症状严重、突然发生或正在加重，请立即联系当地急救服务或前往急诊。WaterHealth 不能判断紧急程度，也不能代替医生。"
        }
        if ["药", "剂量", "治疗", "诊断", "风险"].contains(where: q.contains) {
            return "我可以整理你记录的数据，但不能诊断疾病、计算医学风险或决定药物剂量。请把报告及正在使用的药物清单交给医生或药师评估。你可以在「报告」查看趋势，在「我的 → 数据管理」导出记录。"
        }
        if q.contains("目标") || q.contains("计划") {
            let done = state.goals.filter(\.complete).count
            return "你的计划中有 \(state.goals.count) 个目标，已完成 \(done) 个。\(state.goals.first(where: { !$0.complete }).map { "下一个小行动可以是「\($0.title)」，目前 \($0.current)/\($0.target) \($0.unit)。" } ?? "可以到「目标」制定一个适合自己的小计划。")所有目标由你自行设定，可随时调整。"
        }
        if q.contains("睡") {
            let value = state.metrics.first { $0.id == "sleep" }?.displayValue ?? "—"
            return "最近一次睡眠记录为 \(value) 小时。单次记录不能代表长期状态，建议在「报告 → 设备数据」对照多日趋势和自己的感受。请核对该条记录的数据来源。"
        }
        let readings = state.metrics.filter { $0.latest != nil }.prefix(4)
        guard !readings.isEmpty else { return "你的档案还没有健康指标。可以在「我的 → 数据管理」导入 CSV，在报告中手动记录，或连接 Apple 健康。PDF 会作为原始附件保存，不会自动诊断或提取数据。" }
        let summary = readings.map { "• \($0.name)：\($0.displayValue) \($0.unit)" }.joined(separator: "\n")
        return "这是你最近记录的数据：\n\(summary)\n\n\(state.isDemo ? "演示档案中包含虚构示例，请核对数据来源。" : "请注意每项数据的来源和日期。")你可以打开具体指标查看趋势；是否存在异常，需要结合检验机构参考范围和医生意见判断。"
    }
}
