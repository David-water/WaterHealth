import SwiftUI
import Charts

struct ReportsView: View {
    @EnvironmentObject var store: HealthStore
    @State private var category = ProcessInfo.processInfo.arguments.contains("--device-reports") ? 3 : 0
    @State private var selectedMetric: Metric?
    @State private var selectedSystem: BodySystem?
    @State private var age = false
    @State private var disease = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 21) {
                HStack { SectionHeading(title: "健康，清晰可见", subtitle: "汇总报告与日常记录，留意每一次变化"); Spacer(); IconTile(symbol: "chart.bar.doc.horizontal", size: 43) }
                Segments(items: ["系统报告", "疾病报告", "化验指标", "设备数据"], selected: $category)
                if category == 0 {
                    Button { age = true } label: {
                        GlassCard {
                            HStack(spacing: 16) {
                                IconTile(symbol: "hourglass", color: WH.amber, size: 49)
                                VStack(alignment: .leading, spacing: 7) { Text("身体的另一种年龄").font(.system(size: 17, weight: .medium)); Text("生物年龄报告与系统表现").font(.system(size: 12)).foregroundStyle(WH.muted) }
                                Spacer(); Image(systemName: "arrow.up.right").foregroundStyle(WH.blue)
                            }.foregroundStyle(WH.ink)
                        }
                    }.buttonStyle(.plain)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 310), spacing: 15)], spacing: 15) {
                        ForEach(BodySystem.allCases) { system in
                            Button { selectedSystem = system } label: {
                                GlassCard {
                                    HStack(alignment: .top, spacing: 13) {
                                        IconTile(symbol: system.symbol, color: color(system), size: 45)
                                        VStack(alignment: .leading, spacing: 10) { Text("\(system.title)报告").font(.system(size: 15, weight: .medium)); Text(system.subtitle).font(.system(size: 11)).foregroundStyle(WH.muted); Tag(text: "\(store.state.metrics.filter { $0.system == system && $0.latest != nil }.count) 项已记录", color: color(system)) }
                                        Spacer(minLength: 0); Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(WH.muted).padding(.top, 7)
                                    }.foregroundStyle(WH.ink).frame(minHeight: 80)
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                } else if category == 1 {
                    Button { disease = true } label: {
                        GlassCard { VStack(alignment: .leading, spacing: 17) {
                            HStack { IconTile(symbol: "heart", color: WH.pink, size: 49); VStack(alignment: .leading, spacing: 7) { Text("心血管风险档案").font(.system(size: 17, weight: .medium)); Text("关联指标、报告与就诊准备").font(.system(size: 11)).foregroundStyle(WH.muted) }; Spacer(); Image(systemName: "arrow.up.right").foregroundStyle(WH.blue) }
                            HStack { Text(store.state.isDemo ? "34.2%" : "未评估").font(.system(size: 35, weight: .light)); Spacer(); Tag(text: store.state.isDemo ? "风险示意 · 非医学评估" : "需要专业评估", color: WH.amber) }
                            RangeStrip(position: store.state.isDemo ? 0.69 : 0)
                            Text("将分散的健康信息整理为可回顾的档案，便于与专业人士沟通。").font(.system(size: 12)).foregroundStyle(WH.muted).lineSpacing(4)
                        }.foregroundStyle(WH.ink) }
                    }.buttonStyle(.plain)
                    EmptyCard(symbol: "doc.text.magnifyingglass", title: "更多专业报告", text: "在「我的 → 数据管理」保存原始诊断或检测报告。应用不自动计算疾病风险。")
                } else {
                    let metrics = store.state.metrics.filter { category == 2 ? ["hba1c", "ldl"].contains($0.id) : !["hba1c", "ldl"].contains($0.id) }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 310), spacing: 15)], spacing: 15) {
                        ForEach(metrics) { metric in
                            Button { selectedMetric = metric } label: {
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 15) {
                                        HStack { IconTile(symbol: metric.symbol, color: metric.id == "hba1c" ? WH.mint : WH.blue, size: 33); Text(metric.name).font(.system(size: 14, weight: .medium)); Spacer(); Image(systemName: "arrow.up.right").foregroundStyle(WH.muted).font(.system(size: 11)) }
                                        HStack(alignment: .firstTextBaseline) { Text(metric.displayValue).font(.system(size: 31, weight: .light)); Text(metric.unit).font(.system(size: 11)).foregroundStyle(WH.muted); Spacer(); Text("最近记录").font(.system(size: 10)).foregroundStyle(WH.muted) }
                                        MetricChart(metric: metric).frame(height: 140)
                                        Text(metric.latest.map { "\($0.date.formatted(date: .abbreviated, time: .omitted)) · \($0.source)" } ?? "暂无数据，轻点添加记录").font(.system(size: 10)).foregroundStyle(WH.muted)
                                    }.foregroundStyle(WH.ink)
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                }
                HStack(alignment: .top, spacing: 8) { Image(systemName: "info.circle"); Text("记录不等同于诊断。检验指标请结合报告中的参考范围和专业意见理解。").lineSpacing(3) }.font(.system(size: 11)).foregroundStyle(WH.muted)
            }.padding(20).padding(.bottom, 12)
        }
        .sheet(item: $selectedMetric) { MetricDetailView(metricID: $0.id).environmentObject(store) }
        .sheet(item: $selectedSystem) { SystemReportView(system: $0).environmentObject(store) }
        .sheet(isPresented: $age) { AgeReportView().environmentObject(store) }
        .sheet(isPresented: $disease) { DiseaseReportView().environmentObject(store) }
    }
    func color(_ system: BodySystem) -> Color { switch system { case .cardiovascular: WH.pink; case .immune: WH.mint; case .musculoskeletal: WH.amber; default: WH.blue } }
}

struct DiseaseReportView: View {
    @EnvironmentObject var store: HealthStore
    @State private var selectedMetric: Metric?
    @State private var questions: Set<String> = []
    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "心血管风险档案")
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack { IconTile(symbol: "heart", color: WH.pink, size: 50); Spacer(); Tag(text: store.state.isDemo ? "演示档案" : "待专业评估", color: WH.amber) }
                            Text(store.state.isDemo ? "34.2%" : "—").font(.system(size: 53, weight: .ultraLight))
                            Text("风险可视化示意").font(.system(size: 13)).foregroundStyle(WH.muted)
                            RangeStrip(position: store.state.isDemo ? 0.69 : 0)
                            Text("此数字用于设计演示，不由你的指标计算，不能作为疾病发生概率或诊断依据。").font(.system(size: 11)).foregroundStyle(WH.muted).lineSpacing(4)
                        }
                    }
                    SectionHeading(title: "关联数据", subtitle: "结合来源、日期和原始报告理解记录")
                    ForEach(store.state.metrics.filter { $0.system == .cardiovascular }) { metric in
                        Button { selectedMetric = metric } label: { GlassCard(padding: 16) { HStack { IconTile(symbol: metric.symbol); Text(metric.name).font(.system(size: 13)); Spacer(); Text("\(metric.displayValue) \(metric.unit)").font(.system(size: 14, weight: .medium)); Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(WH.muted) }.foregroundStyle(WH.ink) } }.buttonStyle(.plain)
                    }
                    GlassCard {
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeading(title: "就诊前，整理三个问题", subtitle: "勾选想与医生讨论的内容")
                            ForEach(["这些记录有哪些需要进一步了解的变化？", "还需要提供哪些检查或生活方式信息？", "下一次复查应重点关注什么？"], id: \.self) { question in
                                Button { if questions.contains(question) { questions.remove(question) } else { questions.insert(question) } } label: { HStack(alignment: .top, spacing: 9) { Image(systemName: questions.contains(question) ? "checkmark.circle.fill" : "circle").foregroundStyle(questions.contains(question) ? WH.blue : WH.muted); Text(question).font(.system(size: 12)).foregroundStyle(WH.ink).multilineTextAlignment(.leading); Spacer(minLength: 0) }.frame(minHeight: 40) }.buttonStyle(.plain)
                            }
                        }
                    }
                    Text("若出现正在加重的严重不适，应及时寻求专业帮助，不要等待应用评估。").font(.system(size: 11)).foregroundStyle(WH.muted).lineSpacing(4)
                }.padding(20)
            }
        }.background(WH.canvas).frame(minWidth: 320, minHeight: 550)
        .sheet(item: $selectedMetric) { MetricDetailView(metricID: $0.id).environmentObject(store) }
    }
}

struct MetricChart: View {
    var metric: Metric
    var dark = false
    var body: some View {
        Group {
            if metric.readings.isEmpty {
                VStack(spacing: 8) { Image(systemName: "chart.xyaxis.line").font(.system(size: 24, weight: .ultraLight)); Text("等待第一条记录").font(.system(size: 11)) }.foregroundStyle(WH.muted).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(Array(metric.readings.suffix(30))) { reading in
                    AreaMark(x: .value("日期", reading.date), yStart: .value("基线", domain.lowerBound), yEnd: .value("数值", reading.value)).foregroundStyle(LinearGradient(colors: [WH.blue.opacity(0.14), WH.blue.opacity(0.01)], startPoint: .top, endPoint: .bottom)).interpolationMethod(.linear)
                    LineMark(x: .value("日期", reading.date), y: .value(metric.name, reading.value)).foregroundStyle(WH.blue).lineStyle(StrokeStyle(lineWidth: 1.5)).interpolationMethod(.linear)
                    PointMark(x: .value("日期", reading.date), y: .value(metric.name, reading.value)).foregroundStyle(WH.blue).symbolSize(13)
                }.chartYScale(domain: domain).chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisGridLine().foregroundStyle(WH.line.opacity(dark ? 0.15 : 0.35)); AxisValueLabel(format: .dateTime.month(.twoDigits).day(.twoDigits)).font(.system(size: 8)).foregroundStyle(WH.muted) } }.chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3])).foregroundStyle(WH.line.opacity(dark ? 0.15 : 0.6)); AxisValueLabel().font(.system(size: 8)).foregroundStyle(WH.muted) } }
            }
        }
    }
    var domain: ClosedRange<Double> {
        let values = metric.readings.suffix(30).map(\.value)
        let low = values.min() ?? 0, high = values.max() ?? 1
        let padding = max((high - low) * 0.2, max(high * 0.04, 1))
        return max(0, low - padding)...(high + padding)
    }
}

struct MetricDetailView: View {
    @EnvironmentObject var store: HealthStore
    var metricID: String
    @State private var recording = false
    @State private var value = ""
    @State private var date = Date.now
    @State private var validation: String?
    var metric: Metric? { store.metric(metricID) }
    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: metric?.name ?? "健康指标")
            ScrollView {
                if let metric {
                    VStack(alignment: .leading, spacing: 20) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack { IconTile(symbol: metric.symbol, size: 48); Spacer(); Tag(text: metric.latest?.source ?? "暂无记录") }
                                HStack(alignment: .firstTextBaseline) { Text(metric.displayValue).font(.system(size: 54, weight: .ultraLight)); Text(metric.unit).font(.system(size: 14)).foregroundStyle(WH.muted) }
                                MetricChart(metric: metric).frame(height: 220)
                            }
                        }
                        PrimaryButton(title: "添加一条记录", symbol: "plus") { recording = true }
                        SectionHeading(title: "历史记录", subtitle: "每一次记录，都有来源可查")
                        if metric.readings.isEmpty { EmptyCard(title: "还没有数据", text: "手动记录设备或检验报告中的数值，也可以从 Apple 健康同步。") }
                        ForEach(metric.readings.sorted { $0.date > $1.date }) { item in
                            HStack { VStack(alignment: .leading, spacing: 5) { Text(item.date.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 12)); Text(item.source).font(.system(size: 10)).foregroundStyle(WH.muted) }; Spacer(); Text("\(Metric.format(item.value)) \(metric.unit)").font(.system(size: 16, weight: .medium)) }.padding(15).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                        }
                        Text("请使用与指标一致的单位。应用不会根据数值自动诊断，参考范围以你的检测机构报告为准。").font(.system(size: 11)).foregroundStyle(WH.muted).lineSpacing(4)
                    }.padding(20)
                }
            }
        }.background(WH.canvas).frame(minWidth: 320, minHeight: 540)
        .sheet(isPresented: $recording) {
            VStack(alignment: .leading, spacing: 22) {
                SheetHeader(title: "记录\(metric?.name ?? "指标")")
                VStack(alignment: .leading, spacing: 20) {
                    Text("数值（\(metric?.unit ?? "")）").font(.system(size: 13)).foregroundStyle(WH.muted)
                    TextField("请输入测量值", text: $value).textFieldStyle(.roundedBorder).font(.system(size: 24)).accessibilityIdentifier("readingValue")
                    DatePicker("记录时间", selection: $date, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
                    if let validation { Text(validation).font(.system(size: 12)).foregroundStyle(.red) }
                    PrimaryButton(title: "保存记录", symbol: "checkmark") {
                        guard let number = Double(value), number.isFinite, number >= 0, number <= 1_000_000 else { validation = "请输入 0–1000000 之间的有效数值。"; return }
                        store.addReading(metricID: metricID, value: number, date: date)
                        if store.errorMessage == nil { recording = false; value = "" }
                    }
                }.padding(.horizontal, 20)
                Spacer()
            }.frame(minWidth: 320, minHeight: 360).background(WH.canvas)
        }
    }
}

struct SystemReportView: View {
    @EnvironmentObject var store: HealthStore
    let system: BodySystem
    @State private var metric: Metric?
    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: system.title)
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    TwinFigure(system: system).frame(height: 270).frame(maxWidth: .infinity).background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 23))
                    SectionHeading(title: "系统记录概览", subtitle: system.subtitle)
                    let items = store.state.metrics.filter { $0.system == system }
                    ForEach(items) { item in
                        Button { metric = item } label: { GlassCard { HStack { IconTile(symbol: item.symbol); Text(item.name).font(.system(size: 14)); Spacer(); Text("\(item.displayValue) \(item.unit)").font(.system(size: 14, weight: .medium)); Image(systemName: "chevron.right").font(.system(size: 10)) }.foregroundStyle(WH.ink) } }.buttonStyle(.plain)
                    }
                    if items.isEmpty { EmptyCard(title: "等待更多健康记录", text: "这个系统尚未收录结构化指标。你可以在「我的 → 数据管理」保存对应的 PDF 报告。") }
                    GlassCard { VStack(alignment: .leading, spacing: 10) { Text("下一次就诊前").font(.system(size: 16, weight: .medium)); Text("整理原始报告、近期感受和希望了解的问题。趋势图帮助回顾记录，不能替代临床检查。").font(.system(size: 13)).foregroundStyle(WH.muted).lineSpacing(5) } }
                }.padding(20)
            }
        }.background(WH.canvas).frame(minWidth: 320, minHeight: 540)
        .sheet(item: $metric) { MetricDetailView(metricID: $0.id).environmentObject(store) }
    }
}

struct AgeReportView: View {
    @EnvironmentObject var store: HealthStore
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            CanvasBackground(dark: true)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack { Text("生物年龄报告").font(.system(size: 22, weight: .medium)); Spacer(); CircleAction(symbol: "xmark", label: "关闭", dark: true) { dismiss() } }
                    Tag(text: store.state.isDemo ? "虚构演示报告" : "尚无专业检测数据", color: Color(hex: 0x9BD5F2))
                    HStack(alignment: .firstTextBaseline, spacing: 8) { Text(store.state.profile.biologicalAge.map(String.init) ?? "—").font(.system(size: 64, weight: .ultraLight)); Text("岁").font(.system(size: 14)).foregroundStyle(.white.opacity(0.5)); Spacer(); VStack(alignment: .trailing, spacing: 7) { Text("实际年龄").font(.system(size: 12)).foregroundStyle(.white.opacity(0.5)); Text("\(store.state.profile.age) 岁").font(.system(size: 25, weight: .light)) } }
                    Text("用另一个维度，了解身体。").font(.system(size: 15)).foregroundStyle(.white.opacity(0.65))
                    AgeDial(value: store.state.profile.biologicalAge == nil ? 0 : 0.74, label: store.state.isDemo ? "示意百分位" : "等待检测", number: store.state.isDemo ? "74" : "—").frame(height: 250)
                    Text("百分位、系统年龄与下列指标均为设计演示。应用不根据日常记录推断生物年龄或疾病风险。").font(.system(size: 11)).foregroundStyle(.white.opacity(0.48)).lineSpacing(4)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        ageItem("端粒长度", value: "5.2", unit: "Kb", symbol: "dna")
                        ageItem("甲基化指标", value: "0.76", unit: "示意值", symbol: "circle.hexagongrid")
                        ageItem("免疫细胞", value: "60–80", unit: "% · 示意", symbol: "shield")
                        ageItem("炎症指标", value: "3.2", unit: "mg/L · 示意", symbol: "waveform.path")
                    }
                    GlassCard(dark: true) {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("系统年龄图景").font(.system(size: 17, weight: .medium))
                            ForEach(Array(zip(["心血管", "代谢", "肌肉与骨骼", "免疫"], [46, 44, 40, 42])), id: \.0) { name, age in
                                HStack { Text(name).font(.system(size: 12)).frame(width: 82, alignment: .leading); GeometryReader { geo in Capsule().fill(.white.opacity(0.09)).overlay(alignment: .leading) { Capsule().fill(LinearGradient(colors: [WH.blue, WH.pink], startPoint: .leading, endPoint: .trailing)).frame(width: geo.size.width * (store.state.isDemo ? Double(age) / 65 : 0)) } }.frame(height: 5); Text(store.state.isDemo ? "\(age) 岁" : "—").font(.system(size: 12)).frame(width: 36, alignment: .trailing) }.frame(height: 25)
                            }
                        }
                    }
                }.padding(24)
            }
        }.foregroundStyle(.white).frame(minWidth: 320, minHeight: 600)
    }
    func ageItem(_ title: String, value: String, unit: String, symbol: String) -> some View {
        GlassCard(dark: true, padding: 16) { VStack(alignment: .leading, spacing: 12) { HStack { Image(systemName: symbol).foregroundStyle(Color(hex: 0xA5D9F9)); Text(title).font(.system(size: 12)) }; Text(store.state.isDemo ? value : "—").font(.system(size: 28, weight: .light)); Text(unit).font(.system(size: 10)).foregroundStyle(.white.opacity(0.4)); RangeStrip() } }
    }
}

struct AgeDial: View {
    var value: Double
    var label: String
    var number: String
    var body: some View {
        GeometryReader { geo in
            let diameter = min(geo.size.width - 12, geo.size.height * 1.7)
            ZStack {
                ForEach(0..<80) { tick in
                    Rectangle().fill(.white.opacity(tick % 8 == 0 ? 0.6 : 0.18)).frame(width: 1, height: tick % 8 == 0 ? 15 : 8).offset(y: -diameter / 2).rotationEffect(.degrees(Double(tick) * 180 / 79 - 90))
                }
                Circle().trim(from: 0.5, to: 1).stroke(.white.opacity(0.08), lineWidth: 17).frame(width: diameter - 37, height: diameter - 37)
                Circle().trim(from: 0.5, to: 0.5 + 0.5 * value).stroke(AngularGradient(colors: [WH.blue, Color(hex: 0x82C5EB), WH.pink, WH.amber, WH.blue], center: .center), style: StrokeStyle(lineWidth: 17, lineCap: .butt)).frame(width: diameter - 37, height: diameter - 37)
                VStack(spacing: 6) { Text(number).font(.system(size: 58, weight: .ultraLight)); Text(label).font(.system(size: 12)).foregroundStyle(.white.opacity(0.5)) }.offset(y: -38)
            }.frame(width: geo.size.width, height: diameter).offset(y: geo.size.height - diameter / 2 - 12)
        }.clipped().accessibilityLabel("\(label) \(number)")
    }
}
