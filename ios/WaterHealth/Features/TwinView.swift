import SwiftUI

struct TwinView: View {
    @EnvironmentObject var store: HealthStore
    @State private var selected: BodySystem = ProcessInfo.processInfo.arguments.contains("--neural") ? .nervous : ProcessInfo.processInfo.arguments.contains("--muscle") ? .musculoskeletal : ProcessInfo.processInfo.arguments.contains("--lungs") ? .respiratory : .cardiovascular
    @State private var detail: Metric?
    @State private var careTab = 0
    @State private var ageReport = ProcessInfo.processInfo.arguments.contains("--age-report")
    @State private var fullTwin = false
    @State private var showNutrition = false
    var systemMetrics: [Metric] { store.state.metrics.filter { $0.system == selected } }
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width >= 800
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !wide {
                        HStack { SectionHeading(title: "你好，\(store.state.profile.name.isEmpty ? "朋友" : store.state.profile.name)", subtitle: "让健康，有迹可循。"); Spacer(); Text(Date.now.formatted(.dateTime.month(.twoDigits).day(.twoDigits))).font(.system(size: 12)).foregroundStyle(WH.muted) }
                    }
                    if wide {
                        HStack(alignment: .top, spacing: 22) {
                            twinPanel(width: geo.size.width * 0.40, height: max(660, geo.size.height - 70))
                            VStack(spacing: 18) { systemHeader; ageCard; metricsCard; careCard; dailySummary }
                        }
                    } else {
                        systemHeader
                        twinPanel(width: geo.size.width - 40, height: 368)
                        ageCard
                        metricsCard
                        careCard
                        dailySummary
                    }
                    Text("人体图为健康可视化插画，不是医学影像。指标仅反映已记录的数据。").font(.system(size: 10)).foregroundStyle(WH.muted).padding(.horizontal, 4)
                }.padding(.horizontal, wide ? 28 : 20).padding(.bottom, 25)
            }
        }
        .sheet(item: $detail) { metric in MetricDetailView(metricID: metric.id).environmentObject(store) }
        .sheet(isPresented: $ageReport) { AgeReportView().environmentObject(store) }
        .sheet(isPresented: $showNutrition) { VStack { SheetHeader(title: "我的营养方案"); NutritionView() }.environmentObject(store) }
        .sheet(isPresented: $fullTwin) {
            VStack { SheetHeader(title: selected.title); TwinFigure(system: selected).frame(maxWidth: .infinity, maxHeight: .infinity); Text("可视化插画 · 非诊断影像").font(.footnote).foregroundStyle(WH.muted).padding() }.background(WH.canvas).frame(minWidth: 320, minHeight: 620)
        }
    }
    var systemHeader: some View {
        HStack(alignment: .center, spacing: 11) {
            IconTile(symbol: selected.symbol, size: 37)
            VStack(alignment: .leading, spacing: 4) { Text(selected.title).font(.system(size: 21, weight: .medium)); Text(selected.subtitle).font(.system(size: 11)).foregroundStyle(WH.muted) }
            Spacer(minLength: 4)
            Tag(text: store.state.isDemo ? "演示" : "已记录", color: WH.blue)
        }.foregroundStyle(WH.ink)
    }
    func twinPanel(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 28).fill(LinearGradient(colors: [Color.white.opacity(0.5), Color(hex: 0xD7E1EB).opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay { Ellipse().stroke(.white.opacity(0.7), lineWidth: 27).frame(width: 450, height: 580).rotationEffect(.degrees(30)).offset(x: 110, y: -40) }
            TwinFigure(system: selected).padding(.leading, 32).padding(.top, 12)
            HStack {
                VStack(spacing: 7) {
                    ForEach(BodySystem.allCases) { system in
                        Button { withAnimation(.easeInOut(duration: 0.2)) { selected = system } } label: {
                            Image(systemName: system.symbol).font(.system(size: 16, weight: .light)).foregroundStyle(selected == system ? .white : WH.blue.opacity(0.65)).frame(width: 36, height: 36).background(selected == system ? WH.blue : .white.opacity(0.65), in: Circle())
                        }.buttonStyle(.plain).accessibilityLabel(system.title).accessibilityAddTraits(selected == system ? .isSelected : [])
                    }
                }.padding(8).background(.white.opacity(0.38), in: Capsule())
                Spacer()
            }.padding(.leading, 10).frame(maxHeight: .infinity, alignment: .center)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) { Circle().fill(WH.mint).frame(width: 5, height: 5); Text("你的数字孪生").font(.system(size: 11, weight: .medium)) }
                Text("\(store.state.metrics.filter { $0.latest != nil }.count) 项健康指标").font(.system(size: 10)).foregroundStyle(WH.muted)
            }.padding(12).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14)).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 72).padding(.bottom, 14)
            CircleAction(symbol: "arrow.up.left.and.arrow.down.right", label: "放大人体视图") { fullTwin = true }.padding(12)
        }.frame(width: width, height: height).clipShape(RoundedRectangle(cornerRadius: 28))
    }
    var ageCard: some View {
        Button { ageReport = true } label: {
            GlassCard(padding: 17) {
                VStack(alignment: .leading, spacing: 15) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) { Text("生物年龄").font(.system(size: 11)).foregroundStyle(WH.muted); HStack(alignment: .firstTextBaseline, spacing: 3) { Text(store.state.profile.biologicalAge.map(String.init) ?? "—").font(.system(size: 38, weight: .light)); Text("岁").font(.system(size: 11)).foregroundStyle(WH.muted) } }
                        Spacer()
                        MiniBars(value: 8)
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) { Text("实际年龄").font(.system(size: 11)).foregroundStyle(WH.muted); HStack(alignment: .firstTextBaseline, spacing: 3) { Text("\(store.state.profile.age)").font(.system(size: 38, weight: .light)); Text("岁").font(.system(size: 11)).foregroundStyle(WH.muted) } }
                    }
                    ThinRule()
                    HStack { Text(store.state.isDemo ? "探索身体系统的年龄图景" : "添加专业检测报告，了解更多").font(.system(size: 11)).foregroundStyle(WH.muted); Spacer(); Text("查看报告").font(.system(size: 11)).foregroundStyle(WH.blue); Image(systemName: "arrow.up.right").font(.system(size: 10)).foregroundStyle(WH.blue) }
                }.foregroundStyle(WH.ink)
            }
        }.buttonStyle(.plain).accessibilityIdentifier("openAgeReport")
    }
    var metricsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 17) {
                HStack { Text("关键健康指标").font(.system(size: 17, weight: .medium)); Spacer(); Image(systemName: "arrow.up.right").font(.system(size: 13)).foregroundStyle(WH.muted) }
                if systemMetrics.isEmpty { Text("这个系统还没有结构化指标。可在数据管理中保存原始报告。").font(.system(size: 13)).foregroundStyle(WH.muted).padding(.vertical, 12) }
                ForEach(systemMetrics.prefix(3)) { metric in
                    Button { detail = metric } label: {
                        HStack(spacing: 11) {
                            IconTile(symbol: metric.symbol, color: metric.id == "ldl" ? WH.pink : WH.blue, size: 34)
                            VStack(alignment: .leading, spacing: 6) { Text(metric.name).font(.system(size: 12)); Text(metric.latest?.source ?? "暂无记录").font(.system(size: 9)).foregroundStyle(WH.muted) }
                            Spacer()
                            Text(metric.displayValue).font(.system(size: 24, weight: .light)).monospacedDigit()
                            Text(metric.unit).font(.system(size: 9)).foregroundStyle(WH.muted)
                            Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(WH.muted)
                        }.foregroundStyle(WH.ink).frame(minHeight: 48)
                    }.buttonStyle(.plain)
                    if metric.id != systemMetrics.prefix(3).last?.id { ThinRule() }
                }
            }
        }
    }
    var careCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeading(title: "专属健康计划", subtitle: "用日常的小行动，积累看得见的改变")
                Segments(items: ["行动计划", "营养清单", "生活方式"], selected: $careTab)
                if careTab == 1 {
                    ForEach(store.state.ingredients, id: \.self) { item in HStack { IconTile(symbol: "pills", color: WH.mint); Text(item).font(.system(size: 13)); Spacer(); Image(systemName: "checkmark.circle.fill").foregroundStyle(WH.mint) } }
                    if store.state.ingredients.isEmpty { Text("还没有营养清单。了解成分后，再与专业人士讨论。").font(.system(size: 12)).foregroundStyle(WH.muted) }
                    Button("管理营养清单  →") { showNutrition = true }.buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(WH.blue).frame(height: 38)
                } else {
                    ForEach(careTab == 0 ? Array(store.state.goals.prefix(3)) : store.state.goals.filter { $0.symbol != "heart" }) { goal in
                        HStack(spacing: 12) {
                            IconTile(symbol: goal.symbol, color: goal.symbol == "drop" ? WH.blue : WH.mint)
                            VStack(alignment: .leading, spacing: 5) { Text(goal.title).font(.system(size: 13, weight: .medium)); Text("\(goal.current) / \(goal.target) \(goal.unit)").font(.system(size: 11)).foregroundStyle(WH.muted) }
                            Spacer()
                            Button { store.logGoal(goal.id, amount: goal.complete ? -goal.current : 1) } label: { Image(systemName: goal.complete ? "checkmark.circle.fill" : "plus.circle").font(.system(size: 23, weight: .light)).foregroundStyle(goal.complete ? WH.mint : WH.blue).frame(width: 44, height: 44) }.buttonStyle(.plain).accessibilityLabel(goal.complete ? "撤销\(goal.title)" : "记录\(goal.title)")
                        }
                    }
                    if store.state.goals.isEmpty { Text("前往「目标」，添加你的第一个计划。").font(.system(size: 13)).foregroundStyle(WH.muted).padding(.vertical, 12) }
                }
            }.foregroundStyle(WH.ink)
        }
    }
    var dailySummary: some View {
        HStack(spacing: 12) {
            ForEach(["steps", "sleep"], id: \.self) { id in
                if let metric = store.metric(id) {
                    Button { detail = metric } label: {
                        GlassCard(padding: 15) { VStack(alignment: .leading, spacing: 10) { HStack { Image(systemName: metric.symbol).foregroundStyle(WH.blue); Text(metric.name).font(.system(size: 11)).foregroundStyle(WH.muted) }; Text(metric.displayValue).font(.system(size: 28, weight: .light)).foregroundStyle(WH.ink); Text(metric.unit).font(.system(size: 10)).foregroundStyle(WH.muted) } }
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}

struct TwinFigure: View {
    var system: BodySystem
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(assetName).resizable().scaledToFit().frame(width: geo.size.width, height: geo.size.height)
                if ![.cardiovascular, .nervous, .respiratory, .musculoskeletal].contains(system) {
                    let pos = position
                    Circle().fill(WH.blue.opacity(0.3)).frame(width: 65, height: 65).blur(radius: 20).position(x: geo.size.width * pos.0, y: geo.size.height * pos.1)
                    Circle().stroke(.white.opacity(0.9), lineWidth: 1).frame(width: 30, height: 30).position(x: geo.size.width * pos.0, y: geo.size.height * pos.1)
                    Image(systemName: system.symbol).font(.system(size: 15)).foregroundStyle(.white).position(x: geo.size.width * pos.0, y: geo.size.height * pos.1)
                }
            }
        }.accessibilityLabel("\(system.title)人体可视化插画")
    }
    var assetName: String {
        switch system {
        case .nervous: "NeuralTwin"
        case .musculoskeletal: "MuscleTwin"
        case .respiratory: "RespiratoryTwin"
        default: "DigitalTwin"
        }
    }
    var position: (CGFloat, CGFloat) {
        switch system {
        case .nervous: (0.5, 0.09)
        case .respiratory: (0.55, 0.23)
        case .digestive: (0.5, 0.34)
        case .metabolic: (0.48, 0.39)
        case .musculoskeletal: (0.48, 0.65)
        case .immune: (0.5, 0.28)
        case .renal: (0.43, 0.37)
        default: (0.55, 0.24)
        }
    }
}
