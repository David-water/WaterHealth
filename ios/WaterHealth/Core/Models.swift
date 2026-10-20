import Foundation

enum BodySystem: String, CaseIterable, Identifiable, Codable {
    case cardiovascular, nervous, respiratory, digestive, metabolic, musculoskeletal, immune, renal
    var id: String { rawValue }
    var title: String {
        switch self {
        case .cardiovascular: "心血管系统"
        case .nervous: "神经系统"
        case .respiratory: "呼吸系统"
        case .digestive: "消化系统"
        case .metabolic: "代谢系统"
        case .musculoskeletal: "肌肉与骨骼"
        case .immune: "免疫系统"
        case .renal: "泌尿系统"
        }
    }
    var symbol: String {
        switch self {
        case .cardiovascular: "heart.text.square"
        case .nervous: "brain.head.profile"
        case .respiratory: "lungs"
        case .digestive: "fork.knife"
        case .metabolic: "flame"
        case .musculoskeletal: "figure.strengthtraining.traditional"
        case .immune: "shield.lefthalf.filled"
        case .renal: "drop"
        }
    }
    var subtitle: String {
        switch self {
        case .cardiovascular: "每一次心跳，都值得被看见"
        case .nervous: "感受专注、平衡与恢复"
        case .respiratory: "留意呼吸，感受身体的节奏"
        case .digestive: "从日常饮食，了解身体状态"
        case .metabolic: "连接能量、营养与生活方式"
        case .musculoskeletal: "让每一天的行动更有力量"
        case .immune: "记录变化，关注身体的防护"
        case .renal: "关注水分平衡与日常记录"
        }
    }
}

struct Profile: Codable, Equatable {
    var name = ""
    var age = 42
    var sex = "未设置"
    var weight = 72.0
    var height = 175.0
    var biologicalAge: Int? = nil
    var bmi: Double { weight / pow(height / 100, 2) }
}

struct Reading: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var value: Double
    var source: String
}

struct Metric: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var unit: String
    var system: BodySystem
    var symbol: String
    var readings: [Reading]
    var latest: Reading? { readings.max { $0.date < $1.date } }
    var displayValue: String { latest.map { Self.format($0.value) } ?? "—" }
    static func format(_ value: Double) -> String {
        value.rounded() == value ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }
}

struct HealthGoal: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var subtitle: String
    var symbol: String
    var target: Int
    var unit: String
    var current: Int
    var reminderHour: Int
    var createdAt: Date = .now
    var logs: [GoalLog] = []
    var progress: Double { min(1, max(0, Double(current) / Double(max(1, target)))) }
    var complete: Bool { current >= target }
    var todayAmount: Int { logs.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.amount } }
}

struct GoalLog: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date = .now
    var amount: Int
}

struct HealthDocument: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var kind: String
    var addedAt: Date
    var size: Int
    var storedFilename: String?
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    var isUser: Bool
    var text: String
    var date: Date = .now
}

struct Product: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let subtitle: String
    let category: String
    let priceCents: Int
    let colorHex: UInt32
    let symbol: String
    var priceText: String { String(format: "¥%.2f", Double(priceCents) / 100) }
}

struct CartLine: Identifiable, Codable, Equatable {
    var productID: String
    var quantity: Int
    var id: String { productID }
}

struct Order: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date = .now
    var items: [CartLine]
    var totalCents: Int
}

struct AppState: Codable {
    var schemaVersion = 1
    var profile = Profile()
    var onboardingComplete = false
    var isDemo = false
    var metrics: [Metric] = DemoData.emptyMetrics
    var goals: [HealthGoal] = []
    var documents: [HealthDocument] = []
    var chat: [ChatMessage] = []
    var cart: [CartLine] = []
    var orders: [Order] = []
    var ingredients: [String] = []
    var notificationsEnabled = false
}

enum DemoData {
    static let products: [Product] = [
        .init(id: "daily", name: "每日营养组合", subtitle: "为日常生活，留一份细心", category: "营养补充", priceCents: 19900, colorHex: 0x1979E8, symbol: "leaf"),
        .init(id: "omega", name: "Omega-3", subtitle: "营养成分档案 · 60 粒装示意", category: "营养补充", priceCents: 15900, colorHex: 0x2BAF9B, symbol: "drop"),
        .init(id: "vitamin", name: "复合维生素", subtitle: "维生素与矿物质 · 30 粒装示意", category: "营养补充", priceCents: 9900, colorHex: 0xCF91B9, symbol: "sun.max"),
        .init(id: "kit", name: "健康检测套装", subtitle: "检测项目与流程介绍", category: "检测套装", priceCents: 39900, colorHex: 0x7568C6, symbol: "cross.vial"),
        .init(id: "magnesium", name: "镁元素档案", subtitle: "了解成分，记录专业建议", category: "营养补充", priceCents: 8900, colorHex: 0xE5AB70, symbol: "sparkles"),
        .init(id: "bottle", name: "随行饮水杯", subtitle: "轻盈随行 · 500 mL", category: "生活方式", priceCents: 7900, colorHex: 0x76B5D0, symbol: "waterbottle")
    ]
    static let emptyMetrics: [Metric] = [
        Metric(id: "heartRate", name: "静息心率", unit: "次/分", system: .cardiovascular, symbol: "heart", readings: []),
        Metric(id: "systolic", name: "收缩压", unit: "mmHg", system: .cardiovascular, symbol: "waveform.path.ecg", readings: []),
        Metric(id: "diastolic", name: "舒张压", unit: "mmHg", system: .cardiovascular, symbol: "drop", readings: []),
        Metric(id: "hba1c", name: "糖化血红蛋白", unit: "%", system: .metabolic, symbol: "cross.vial", readings: []),
        Metric(id: "ldl", name: "低密度脂蛋白", unit: "mmol/L", system: .cardiovascular, symbol: "drop.fill", readings: []),
        Metric(id: "oxygen", name: "血氧饱和度", unit: "%", system: .respiratory, symbol: "lungs", readings: []),
        Metric(id: "steps", name: "每日步数", unit: "步", system: .musculoskeletal, symbol: "figure.walk", readings: []),
        Metric(id: "sleep", name: "睡眠时长", unit: "小时", system: .nervous, symbol: "moon.zzz", readings: [])
    ]
    static func state(now: Date = .now) -> AppState {
        var state = AppState()
        state.isDemo = true
        state.onboardingComplete = true
        state.profile = Profile(name: "林沐", age: 42, sex: "男", weight: 72, height: 175, biologicalAge: 46)
        let values: [[Double]] = [[71,68,70,67,66,65,68], [126,124,128,121,125,123,122], [82,80,83,78,80,79,78], [5.6,5.5,5.6,5.4,5.4,5.3,5.2], [3.2,3.1,3.0,3.2,2.9,2.8,2.8], [97,98,97,98,99,98,98], [4850,6200,5100,7400,6800,8120,6420], [6.5,7.2,6.8,7.0,7.5,7.2,7.4]]
        for index in state.metrics.indices {
            state.metrics[index].readings = values[index].enumerated().map { offset, value in
                Reading(date: Calendar.current.date(byAdding: .day, value: offset - 6, to: now)!, value: value, source: "虚构演示数据")
            }
        }
        state.goals = [
            HealthGoal(title: "规律饮水", subtitle: "按自己的节奏，记录每一杯", symbol: "drop", target: 8, unit: "杯", current: 5, reminderHour: 10),
            HealthGoal(title: "今天，走一走", subtitle: "把轻松的活动放进生活", symbol: "figure.walk", target: 30, unit: "分钟", current: 20, reminderHour: 18),
            HealthGoal(title: "给睡眠留时间", subtitle: "睡前放下屏幕，记录休息", symbol: "moon", target: 1, unit: "次", current: 1, reminderHour: 22),
            HealthGoal(title: "记录血压", subtitle: "记录设备读数，保留变化", symbol: "heart", target: 1, unit: "次", current: 0, reminderHour: 9)
        ]
        state.ingredients = ["复合维生素", "Omega-3"]
        return state
    }
}
