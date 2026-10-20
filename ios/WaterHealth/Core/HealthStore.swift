import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

@MainActor
final class HealthStore: ObservableObject {
    @Published private(set) var state: AppState
    @Published var errorMessage: String?
    @Published var notice: String?
    let directory: URL
    private let fileURL: URL
    private var requiresRecovery = false

    init(directory: URL? = nil, preview: Bool = false) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("WaterHealth", isDirectory: true)
        fileURL = self.directory.appendingPathComponent("health-records.json")
        if preview { state = DemoData.state(); return }
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                let decoded = try JSONDecoder().decode(AppState.self, from: data)
                guard decoded.schemaVersion == 1 else { throw ImportFailure.invalid("数据版本较新，请更新应用后打开。") }
                state = decoded
            } else { state = AppState() }
        } catch {
            state = AppState()
            state.onboardingComplete = true
            requiresRecovery = true
            errorMessage = "本地档案未能读取，原始文件已保留。请先在数据管理中导出原始档案，再替换档案。\(error.localizedDescription)"
        }
    }

    @discardableResult
    func commit(_ change: (inout AppState) throws -> Void) -> Bool {
        guard !requiresRecovery else {
            errorMessage = "原始档案尚未恢复，已阻止覆盖。请先导出原始档案，再使用档案模式替换。"
            return false
        }
        var next = state
        do {
            try change(&next)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(next)
            #if os(iOS)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
            #else
            try data.write(to: fileURL, options: .atomic)
            #endif
            state = next
            return true
        } catch {
            errorMessage = "操作未保存：\(error.localizedDescription)"
            return false
        }
    }

    func finishOnboarding(profile: Profile, demo: Bool) {
        commit { next in
            next = demo ? DemoData.state() : AppState()
            if !demo { next.profile = profile }
            next.onboardingComplete = true
        }
    }
    func updateProfile(_ profile: Profile) { commit { $0.profile = profile } }
    func metric(_ id: String) -> Metric? { state.metrics.first { $0.id == id } }
    func addReading(metricID: String, value: Double, date: Date, source: String = "手动记录") {
        guard value.isFinite, value >= 0, value <= 1_000_000 else { errorMessage = "请输入有效的非负数值。"; return }
        commit { next in
            guard let i = next.metrics.firstIndex(where: { $0.id == metricID }) else { return }
            next.metrics[i].readings.append(Reading(date: date, value: value, source: source))
            next.metrics[i].readings.sort { $0.date < $1.date }
        }
    }
    func mergeReadings(_ readings: [ImportedReading]) -> Bool {
        commit { next in
            for item in readings {
                guard let i = next.metrics.firstIndex(where: { $0.id == item.metricID }) else { continue }
                if !next.metrics[i].readings.contains(where: { $0.date == item.reading.date && $0.source == item.reading.source && $0.value == item.reading.value }) {
                    next.metrics[i].readings.append(item.reading)
                    next.metrics[i].readings.sort { $0.date < $1.date }
                }
            }
        }
    }
    func addGoal(_ goal: HealthGoal) {
        if commit({ $0.goals.append(goal) }) { refreshReminders() }
    }
    func updateGoal(_ goal: HealthGoal) {
        if commit({ next in if let i = next.goals.firstIndex(where: { $0.id == goal.id }) { next.goals[i] = goal } }) { refreshReminders() }
    }
    func removeGoal(_ id: UUID) {
        if commit({ $0.goals.removeAll { $0.id == id } }) { refreshReminders() }
    }
    func logGoal(_ id: UUID, amount: Int) {
        if commit({ next in
            guard let i = next.goals.firstIndex(where: { $0.id == id }) else { return }
            let previous = next.goals[i].current
            let updated = min(next.goals[i].target, max(0, previous + amount))
            guard previous != updated else { return }
            next.goals[i].current = updated
            next.goals[i].logs.append(GoalLog(amount: updated - previous))
        }) { refreshReminders() }
    }
    func send(_ text: String) {
        let clean = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2000))
        guard !clean.isEmpty else { return }
        let answer = HealthAssistant.reply(to: clean, state: state)
        commit { next in
            next.chat.append(ChatMessage(isUser: true, text: clean))
            next.chat.append(ChatMessage(isUser: false, text: answer))
        }
    }
    func clearChat() { commit { $0.chat = [] } }
    func toggleIngredient(_ name: String) {
        commit { next in
            if next.ingredients.contains(name) { next.ingredients.removeAll { $0 == name } }
            else { next.ingredients.append(name) }
        }
    }
    var cartCount: Int { state.cart.reduce(0) { $0 + $1.quantity } }
    var cartTotal: Int {
        state.cart.reduce(0) { total, line in total + (DemoData.products.first { $0.id == line.productID }?.priceCents ?? 0) * line.quantity }
    }
    func changeCart(_ productID: String, delta: Int) {
        guard DemoData.products.contains(where: { $0.id == productID }) else { return }
        commit { next in
            if let i = next.cart.firstIndex(where: { $0.productID == productID }) {
                next.cart[i].quantity = min(99, max(0, next.cart[i].quantity + delta))
                if next.cart[i].quantity == 0 { next.cart.remove(at: i) }
            } else if delta > 0 { next.cart.append(CartLine(productID: productID, quantity: min(99, delta))) }
        }
    }
    @discardableResult
    func checkout() -> Bool {
        guard !state.cart.isEmpty else { return false }
        let order = Order(items: state.cart, totalCents: cartTotal)
        return commit { next in next.orders.insert(order, at: 0); next.cart = [] }
    }
    func importFile(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            let ext = url.pathExtension.lowercased()
            guard ["pdf", "csv"].contains(ext) else { throw ImportFailure.invalid("支持 PDF 和 CSV 文件。") }
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size > 0, size <= 25_000_000 else { throw ImportFailure.invalid("文件不能为空，且不得超过 25 MB。") }
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let imported = ext == "csv" ? try CSVImporter.parse(data) : []
            if ext == "pdf", !data.prefix(5).elementsEqual(Data("%PDF-".utf8)) { throw ImportFailure.invalid("这不是有效的 PDF 文件。") }
            let id = UUID()
            let filename = "\(id.uuidString).\(ext)"
            let attachments = directory.appendingPathComponent("attachments", isDirectory: true)
            try FileManager.default.createDirectory(at: attachments, withIntermediateDirectories: true)
            let destination = attachments.appendingPathComponent(filename)
            #if os(iOS)
            try data.write(to: destination, options: [.atomic, .completeFileProtection])
            #else
            try data.write(to: destination, options: .atomic)
            #endif
            let saved = commit { next in
                next.documents.append(HealthDocument(id: id, name: url.lastPathComponent, kind: ext.uppercased(), addedAt: .now, size: data.count, storedFilename: filename))
                for item in imported {
                    if let i = next.metrics.firstIndex(where: { $0.id == item.metricID }), !next.metrics[i].readings.contains(where: { $0.date == item.reading.date && $0.value == item.reading.value && $0.source == item.reading.source }) {
                        next.metrics[i].readings.append(item.reading)
                        next.metrics[i].readings.sort { $0.date < $1.date }
                    }
                }
            }
            if saved { notice = ext == "csv" ? "已处理 \(imported.count) 条指标记录，重复记录已跳过。" : "PDF 已保存在本机，可随时打开查看。" }
            else { try? FileManager.default.removeItem(at: destination) }
        } catch { errorMessage = error.localizedDescription }
    }
    func documentURL(_ document: HealthDocument) -> URL? {
        document.storedFilename.map { directory.appendingPathComponent("attachments").appendingPathComponent($0) }
    }
    func removeDocument(_ document: HealthDocument) {
        if commit({ $0.documents.removeAll { $0.id == document.id } }), let url = documentURL(document) { try? FileManager.default.removeItem(at: url) }
    }
    func reset(demo: Bool) {
        if requiresRecovery {
            do {
                let backup = directory.appendingPathComponent("recovery-\(UUID().uuidString).json")
                try FileManager.default.copyItem(at: fileURL, to: backup)
                requiresRecovery = false
            } catch { errorMessage = "备份原始档案失败，未替换：\(error.localizedDescription)"; return }
        }
        let old = state.documents
        if commit({ next in next = demo ? DemoData.state() : AppState(); next.onboardingComplete = true }) {
            for document in old { if let url = documentURL(document) { try? FileManager.default.removeItem(at: url) } }
            #if os(iOS)
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            #endif
        }
    }
    func exportData() throws -> Data {
        if requiresRecovery { return try Data(contentsOf: fileURL) }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(state)
    }
    func setNotifications(_ enabled: Bool) async {
        #if os(iOS)
        do {
            if enabled {
                let allowed = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                guard allowed else { notice = "提醒权限未开启，可在系统设置中允许通知。"; return }
            }
            if commit({ $0.notificationsEnabled = enabled }) { refreshReminders() }
        } catch { errorMessage = error.localizedDescription }
        #else
        notice = "通知仅在 iOS 版本提供。"
        #endif
    }
    func refreshReminders() {
        #if os(iOS)
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard state.notificationsEnabled else { return }
        for goal in state.goals.prefix(50) where !goal.complete {
            let content = UNMutableNotificationContent()
            content.title = "WaterHealth · 给自己一点时间"
            content.body = "你的日常计划有一个小行动等待记录。"
            content.sound = .default
            var components = DateComponents(); components.hour = goal.reminderHour; components.minute = 0
            let request = UNNotificationRequest(identifier: goal.id.uuidString, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true))
            center.add(request) { error in
                if let error { Task { @MainActor in self.errorMessage = "提醒设置失败：\(error.localizedDescription)" } }
            }
        }
        #endif
    }
}

struct ExportFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
