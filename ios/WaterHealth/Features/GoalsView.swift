import SwiftUI
import Charts

struct GoalsView: View {
    @EnvironmentObject var store: HealthStore
    @State private var editing: HealthGoal?
    @State private var adding = false
    @State private var history = false
    var completed: Int { store.state.goals.filter(\.complete).count }
    var progress: Double { store.state.goals.isEmpty ? 0 : store.state.goals.map(\.progress).reduce(0, +) / Double(store.state.goals.count) }
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack { SectionHeading(title: "小步行动，长久改变", subtitle: "你的计划，由你掌握", dark: true); Spacer(); CircleAction(symbol: "plus", label: "添加目标", dark: true) { adding = true }.accessibilityIdentifier("addGoal") }
                    if geo.size.width > 800 {
                        HStack(alignment: .top, spacing: 20) { overview.frame(maxWidth: 340); VStack(spacing: 20) { goals; timeline } }
                    } else { overview; goals; timeline }
                }.padding(20).padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $adding) { GoalEditorView(goal: nil).environmentObject(store) }
        .sheet(item: $editing) { GoalEditorView(goal: $0).environmentObject(store) }
        .sheet(isPresented: $history) { GoalHistoryView().environmentObject(store) }
    }
    var overview: some View {
        GlassCard(dark: true, padding: 20) {
            VStack(alignment: .leading, spacing: 19) {
                HStack { Text("本轮计划进度").font(.system(size: 17, weight: .medium)); Spacer(); Image(systemName: "arrow.up.right").foregroundStyle(.white.opacity(0.4)) }
                HStack(spacing: 15) { Tag(text: "\(completed) 个已完成", color: Color(hex: 0x92CDF5)); Tag(text: "\(store.state.goals.count - completed) 个进行中", color: .white.opacity(0.5)) }
                AgeDial(value: progress, label: "整体完成度", number: "\(Int(progress * 100))%").frame(height: 195)
                HStack { Text("\(completed)").font(.system(size: 30, weight: .light)); Text("/ \(store.state.goals.count) 个目标").font(.system(size: 12)).foregroundStyle(.white.opacity(0.5)); Spacer(); Image(systemName: "scope").font(.system(size: 32, weight: .ultraLight)).foregroundStyle(WH.blue) }
                PrimaryButton(title: "回顾行动记录", symbol: "clock.arrow.circlepath") { history = true }
                Text("完成度按各目标当前进度的平均值计算。目标由你设定，可随时调整。").font(.system(size: 10)).foregroundStyle(.white.opacity(0.4)).lineSpacing(4)
            }.foregroundStyle(.white)
        }
    }
    var goals: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack { Text("我的健康目标").font(.system(size: 18, weight: .medium)).foregroundStyle(.white); Spacer(); Text("\(store.state.goals.count) 项").font(.system(size: 11)).foregroundStyle(.white.opacity(0.4)) }
            if store.state.goals.isEmpty {
                Button { adding = true } label: { EmptyCard(symbol: "scope", title: "给自己一个小目标", text: "从饮水、散步或睡眠习惯开始，设置你想记录的行动。") }.buttonStyle(.plain)
            }
            ForEach(store.state.goals) { goal in
                GlassCard(padding: 17) {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 12) {
                            IconTile(symbol: goal.symbol, color: goal.complete ? WH.mint : WH.blue, size: 43)
                            VStack(alignment: .leading, spacing: 6) { Text(goal.title).font(.system(size: 15, weight: .medium)); Text(goal.subtitle).font(.system(size: 11)).foregroundStyle(WH.muted).lineLimit(2) }
                            Spacer(minLength: 3)
                            Button { editing = goal } label: { Image(systemName: "ellipsis").font(.system(size: 17)).foregroundStyle(WH.muted).frame(width: 35, height: 40) }.buttonStyle(.plain).accessibilityLabel("编辑\(goal.title)")
                        }
                        HStack(spacing: 15) {
                            ProgressView(value: goal.progress).tint(goal.complete ? WH.mint : WH.blue)
                            Text("\(goal.current)/\(goal.target) \(goal.unit)").font(.system(size: 11)).foregroundStyle(WH.muted).monospacedDigit().fixedSize()
                            Button { store.logGoal(goal.id, amount: goal.complete ? -goal.current : increment(goal)) } label: { Text(goal.complete ? "已完成 ✓" : "记录 +\(increment(goal))").font(.system(size: 11, weight: .medium)).foregroundStyle(goal.complete ? WH.mint : .white).padding(.horizontal, 13).frame(height: 34).background(goal.complete ? WH.mint.opacity(0.1) : WH.blue, in: Capsule()) }.buttonStyle(.plain).accessibilityIdentifier("logGoal_\(goal.title)")
                        }
                    }.foregroundStyle(WH.ink)
                }
            }
        }
    }
    func increment(_ goal: HealthGoal) -> Int { min(goal.target - goal.current, goal.unit == "分钟" ? 10 : 1) }
    var timeline: some View {
        GlassCard(dark: true) {
            VStack(alignment: .leading, spacing: 18) {
                HStack { Text("今日行动时间线").font(.system(size: 17, weight: .medium)); Spacer(); Image(systemName: "calendar").foregroundStyle(.white.opacity(0.4)) }
                let entries = store.state.goals.flatMap { goal in goal.logs.filter { Calendar.current.isDateInToday($0.date) }.map { (goal.title, $0) } }.sorted { $0.1.date < $1.1.date }
                if entries.isEmpty { Text("今天还没有打卡记录。轻点目标上的「记录」，留下一次行动。").font(.system(size: 12)).foregroundStyle(.white.opacity(0.5)).lineSpacing(5).padding(.vertical, 10) }
                ForEach(entries, id: \.1.id) { title, log in
                    HStack(spacing: 12) { Circle().fill(log.amount > 0 ? WH.blue : WH.amber).frame(width: 6, height: 6); Text(log.date.formatted(date: .omitted, time: .shortened)).font(.system(size: 11)).foregroundStyle(.white.opacity(0.4)); Text(title).font(.system(size: 12)); Spacer(); Text(log.amount > 0 ? "+\(log.amount)" : "\(log.amount)").font(.system(size: 12)).foregroundStyle(log.amount > 0 ? Color(hex: 0x94D4F0) : WH.amber) }.padding(.vertical, 5)
                }
            }.foregroundStyle(.white)
        }
    }
}

struct GoalEditorView: View {
    @EnvironmentObject var store: HealthStore
    @Environment(\.dismiss) var dismiss
    let goal: HealthGoal?
    @State private var title = ""
    @State private var subtitle = ""
    @State private var target = 8
    @State private var unit = "杯"
    @State private var symbol = "drop"
    @State private var hour = 10
    @State private var delete = false
    @State private var validation: String?
    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: goal == nil ? "添加健康目标" : "编辑健康目标")
            Form {
                Section("给目标起个名字") { TextField("例如：规律饮水", text: $title).accessibilityIdentifier("goalTitle"); TextField("一句话说明（可选）", text: $subtitle) }
                Section("本轮计划") { Stepper("目标数量：\(target)", value: $target, in: 1...10000); Picker("单位", selection: $unit) { ForEach(["杯", "分钟", "次", "步"], id: \.self) { Text($0).tag($0) } }; Picker("图标", selection: $symbol) { ForEach(["drop", "figure.walk", "moon", "heart", "leaf", "book"], id: \.self) { Image(systemName: $0).tag($0) } } }
                Section("提醒时间") { Stepper("每天 \(String(format: "%02d", hour)):00", value: $hour, in: 0...23); Text("在「我的」开启通知后生效。通知内容不显示具体健康数据。").font(.footnote).foregroundStyle(WH.muted) }
                if let validation { Section { Text(validation).foregroundStyle(.red) } }
                Section { Button("保存目标") {
                    let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !clean.isEmpty, clean.count <= 40 else { validation = "名称不能为空，且最多 40 个字。"; return }
                    if var updated = goal { updated.title = clean; updated.subtitle = String(subtitle.prefix(100)); updated.target = target; updated.current = min(updated.current, target); updated.unit = unit; updated.symbol = symbol; updated.reminderHour = hour; store.updateGoal(updated) }
                    else { store.addGoal(HealthGoal(title: clean, subtitle: String(subtitle.prefix(100)), symbol: symbol, target: target, unit: unit, current: 0, reminderHour: hour)) }
                    if store.errorMessage == nil { dismiss() }
                }.accessibilityIdentifier("saveGoal") }
                if goal != nil { Section { Button("删除目标", role: .destructive) { delete = true } } }
            }
        }.frame(minWidth: 320, minHeight: 520)
        .onAppear { if let goal { title = goal.title; subtitle = goal.subtitle; target = goal.target; unit = goal.unit; symbol = goal.symbol; hour = goal.reminderHour } }
        .alert("删除这个目标？", isPresented: $delete) { Button("取消", role: .cancel) {}; Button("删除", role: .destructive) { if let goal { store.removeGoal(goal.id) }; dismiss() } } message: { Text("目标及其行动记录将从本机移除。") }
    }
}

struct GoalHistoryView: View {
    @EnvironmentObject var store: HealthStore
    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "行动记录")
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    let entries = store.state.goals.flatMap { goal in goal.logs.map { (goal.title, goal.unit, $0) } }.sorted { $0.2.date > $1.2.date }
                    if entries.isEmpty { EmptyCard(symbol: "clock", title: "从今天开始记录", text: "每一次打卡和撤销都会保留在这里。") }
                    ForEach(entries, id: \.2.id) { title, unit, log in
                        GlassCard { HStack { VStack(alignment: .leading, spacing: 6) { Text(title).font(.system(size: 15, weight: .medium)); Text(log.date.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 11)).foregroundStyle(WH.muted) }; Spacer(); Text("\(log.amount > 0 ? "+" : "")\(log.amount) \(unit)").font(.system(size: 15)).foregroundStyle(log.amount > 0 ? WH.blue : WH.amber) } }
                    }
                }.padding(20)
            }
        }.background(WH.canvas).frame(minWidth: 320, minHeight: 500)
    }
}
