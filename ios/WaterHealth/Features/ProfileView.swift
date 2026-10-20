import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import QuickLook
#endif

struct ProfileView: View {
    @EnvironmentObject var store: HealthStore
    @State private var profile = false
    @State private var data = ProcessInfo.processInfo.arguments.contains("--data-manager")
    @State private var devices = ProcessInfo.processInfo.arguments.contains("--devices")
    @State private var orders = false
    @State private var privacy = false
    @State private var reset = false
    @State private var resetDemo = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeading(title: "你的健康档案", subtitle: "把资料整理好，把生活过轻松")
                GlassCard(padding: 22) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 15) { ZStack { Circle().fill(WH.blue.opacity(0.13)); Image(systemName: "person").font(.system(size: 31, weight: .ultraLight)).foregroundStyle(WH.blue) }.frame(width: 62, height: 62); VStack(alignment: .leading, spacing: 7) { Text(store.state.profile.name.isEmpty ? "朋友" : store.state.profile.name).font(.system(size: 23, weight: .medium)); Text("\(store.state.profile.age) 岁 · \(store.state.profile.sex)").font(.system(size: 12)).foregroundStyle(WH.muted) }; Spacer(); Button { profile = true } label: { Image(systemName: "pencil").foregroundStyle(WH.blue).frame(width: 44, height: 44) }.buttonStyle(.plain).accessibilityLabel("编辑个人档案") }
                        ThinRule()
                        HStack { profileStat("身高", "\(Int(store.state.profile.height))", "cm"); Spacer(); profileStat("体重", Metric.format(store.state.profile.weight), "kg"); Spacer(); profileStat("BMI", Metric.format(store.state.profile.bmi), "记录值") }
                    }
                }
                VStack(spacing: 12) {
                    menu("数据管理", subtitle: "导入报告、查看附件、导出档案", symbol: "folder", action: { data = true })
                    menu("Apple 健康", subtitle: "由你授权，按需读取健康记录", symbol: "heart.text.square", action: { devices = true })
                    menu("订单记录", subtitle: "\(store.state.orders.count) 份本地模拟订单", symbol: "bag", action: { orders = true })
                }
                GlassCard {
                    HStack(spacing: 12) { IconTile(symbol: "bell", color: WH.amber); VStack(alignment: .leading, spacing: 5) { Text("目标提醒").font(.system(size: 14, weight: .medium)); Text("按目标设定的时间，温柔提醒").font(.system(size: 10)).foregroundStyle(WH.muted) }; Spacer(); Toggle("目标提醒", isOn: Binding(get: { store.state.notificationsEnabled }, set: { value in Task { await store.setNotifications(value) } })).labelsHidden().tint(WH.blue) }
                }
                menu("隐私与数据", subtitle: "本地存储、权限及使用边界", symbol: "lock.shield", action: { privacy = true })
                GlassCard { VStack(alignment: .leading, spacing: 16) { Text("档案模式").font(.system(size: 15, weight: .medium)); Text(store.state.isDemo ? "你正在使用虚构演示档案。清空后，可以建立自己的真实记录。" : "当前为个人档案模式。切换演示前，请先导出需要保留的数据。").font(.system(size: 12)).foregroundStyle(WH.muted).lineSpacing(4); Button { resetDemo = !store.state.isDemo; reset = true } label: { Text(store.state.isDemo ? "清空演示，建立我的档案" : "切换到演示档案").font(.system(size: 12)).foregroundStyle(WH.blue).frame(minHeight: 36) }.buttonStyle(.plain) } }
                HStack { Brand(); Spacer(); Text("版本 1.0.0").font(.system(size: 10)).foregroundStyle(WH.muted) }.padding(.top, 9)
            }.padding(20).padding(.bottom, 20)
        }
        .sheet(isPresented: $profile) { ProfileEditorView().environmentObject(store) }
        .sheet(isPresented: $data) { DataManagementView().environmentObject(store) }
        .sheet(isPresented: $devices) { DevicesView().environmentObject(store) }
        .sheet(isPresented: $orders) { OrdersView().environmentObject(store) }
        .sheet(isPresented: $privacy) { PrivacyView() }
        .alert("替换当前档案？", isPresented: $reset) { Button("取消", role: .cancel) {}; Button("替换", role: .destructive) { store.reset(demo: resetDemo) } } message: { Text("当前档案、附件、对话、目标及模拟订单将被清除。请先在数据管理中导出需要保留的记录。") }
    }
    func profileStat(_ title: String, _ value: String, _ unit: String) -> some View { VStack(alignment: .leading, spacing: 7) { Text(title).font(.system(size: 10)).foregroundStyle(WH.muted); HStack(alignment: .firstTextBaseline, spacing: 3) { Text(value).font(.system(size: 27, weight: .light)); Text(unit).font(.system(size: 9)).foregroundStyle(WH.muted) } } }
    func menu(_ title: String, subtitle: String, symbol: String, action: @escaping () -> Void) -> some View { Button(action: action) { GlassCard(padding: 16) { HStack(spacing: 12) { IconTile(symbol: symbol); VStack(alignment: .leading, spacing: 5) { Text(title).font(.system(size: 14, weight: .medium)); Text(subtitle).font(.system(size: 10)).foregroundStyle(WH.muted) }; Spacer(); Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(WH.muted) }.foregroundStyle(WH.ink) } }.buttonStyle(.plain) }
}

struct ProfileEditorView: View {
    @EnvironmentObject var store: HealthStore
    @Environment(\.dismiss) var dismiss
    @State private var profile = Profile()
    var body: some View {
        VStack(spacing: 0) { SheetHeader(title: "编辑个人档案"); Form { Section("基本信息") { TextField("名字", text: $profile.name); Picker("性别", selection: $profile.sex) { ForEach(["男", "女", "未设置"], id: \.self) { Text($0).tag($0) } }; Stepper("年龄：\(profile.age) 岁", value: $profile.age, in: 18...100) }; Section("身体记录") { Stepper("身高：\(Int(profile.height)) cm", value: $profile.height, in: 100...230, step: 1); Stepper("体重：\(Metric.format(profile.weight)) kg", value: $profile.weight, in: 30...250, step: 0.5) }; Section { Button("保存档案") { profile.name = String(profile.name.trimmingCharacters(in: .whitespaces).prefix(30)); if profile.name.isEmpty { profile.name = "朋友" }; store.updateProfile(profile); if store.errorMessage == nil { dismiss() } } } } }.onAppear { profile = store.state.profile }.frame(minWidth: 320, minHeight: 450)
    }
}

struct DataManagementView: View {
    @EnvironmentObject var store: HealthStore
    @State private var importing = false
    @State private var exporting = false
    @State private var exportFile = ExportFile(data: Data())
    @State private var exportType: UTType = .json
    @State private var exportName = "WaterHealth-健康档案"
    @State private var previewURL: URL?
    @State private var remove: HealthDocument?
    @State private var showRemove = false
    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "数据管理")
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) { IconTile(symbol: "arrow.up.doc", size: 49); SectionHeading(title: "把健康记录，放在一起", subtitle: "PDF 保存为原始附件；CSV 导入结构化指标"); PrimaryButton(title: "导入 PDF / CSV", symbol: "plus") { importing = true }; Text("PDF ≤25 MB · CSV ≤2 MB · UTF-8 编码").font(.system(size: 10)).foregroundStyle(WH.muted) }
                    }
                    HStack(spacing: 12) { Button { exportFile = ExportFile(data: Data(CSVImporter.template.utf8)); exportType = .commaSeparatedText; exportName = "WaterHealth-导入模板"; exporting = true } label: { Label("CSV 模板", systemImage: "doc.badge.arrow.down").font(.system(size: 12)).foregroundStyle(WH.blue).frame(maxWidth: .infinity).frame(height: 44).background(.white, in: Capsule()) }.buttonStyle(.plain); Button { do { exportFile = ExportFile(data: try store.exportData()); exportType = .json; exportName = "WaterHealth-健康档案"; exporting = true } catch { store.errorMessage = error.localizedDescription } } label: { Label("导出档案", systemImage: "square.and.arrow.up").font(.system(size: 12)).foregroundStyle(WH.blue).frame(maxWidth: .infinity).frame(height: 44).background(.white, in: Capsule()) }.buttonStyle(.plain) }
                    SectionHeading(title: "我的原始报告", subtitle: "\(store.state.documents.count) 份附件 · 保存在本机")
                    if store.state.documents.isEmpty { EmptyCard(symbol: "doc.text", title: "等待你的第一份报告", text: "导入原始报告后，可以随时查看或分享。PDF 内容不会自动转成指标。") }
                    ForEach(store.state.documents.sorted { $0.addedAt > $1.addedAt }) { document in
                        GlassCard(padding: 15) {
                            HStack(spacing: 11) { IconTile(symbol: document.kind == "PDF" ? "doc.richtext" : "tablecells"); Button { previewURL = store.documentURL(document) } label: { VStack(alignment: .leading, spacing: 6) { Text(document.name).font(.system(size: 13, weight: .medium)).lineLimit(2); Text("\(ByteCountFormatter.string(fromByteCount: Int64(document.size), countStyle: .file)) · \(document.addedAt.formatted(date: .abbreviated, time: .omitted))").font(.system(size: 9)).foregroundStyle(WH.muted) }.foregroundStyle(WH.ink).frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(.plain); if let url = store.documentURL(document) { ShareLink(item: url) { Image(systemName: "square.and.arrow.up").font(.system(size: 14)).frame(width: 30, height: 44) } }; Button { remove = document; showRemove = true } label: { Image(systemName: "trash").font(.system(size: 13)).foregroundStyle(WH.muted).frame(width: 30, height: 44) }.buttonStyle(.plain).accessibilityLabel("删除\(document.name)") }
                        }
                    }
                    GlassCard { VStack(alignment: .leading, spacing: 12) { Text("CSV 格式").font(.system(size: 16, weight: .medium)); Text("metric,value,unit,date").font(.system(size: 12, design: .monospaced)).foregroundStyle(WH.blue); Text("指标名、数值、单位、日期。单位必须与应用一致；日期支持 YYYY-MM-DD 或 ISO 8601。错误文件整批拒绝，不会部分写入。").font(.system(size: 11)).foregroundStyle(WH.muted).lineSpacing(4); ForEach(DemoData.emptyMetrics) { metric in HStack { Text(metric.id).font(.system(size: 11, design: .monospaced)); Spacer(); Text("\(metric.name) · \(metric.unit)").font(.system(size: 10)).foregroundStyle(WH.muted) } } } }
                    Text("导出的 JSON 包含档案、指标、目标、对话及订单记录，附件文件需单独分享保存。导出文件含个人健康数据，请选择你信任的保存位置。").font(.system(size: 10)).foregroundStyle(WH.muted).lineSpacing(4)
                }.padding(20)
            }
        }.background(WH.canvas).frame(minWidth: 320, minHeight: 550)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf, .commaSeparatedText], allowsMultipleSelection: false) { result in switch result { case .success(let urls): if let url = urls.first { store.importFile(url) }; case .failure(let error): store.errorMessage = error.localizedDescription } }
        .fileExporter(isPresented: $exporting, document: exportFile, contentType: exportType, defaultFilename: exportName) { result in if case let .failure(error) = result { store.errorMessage = error.localizedDescription } }
        #if os(iOS)
        .quickLookPreview($previewURL)
        #else
        .onChange(of: previewURL) { _, url in if let url { NSWorkspace.shared.open(url); previewURL = nil } }
        #endif
        .alert("删除这份附件？", isPresented: $showRemove) { Button("取消", role: .cancel) {}; Button("删除", role: .destructive) { if let remove { store.removeDocument(remove) } } } message: { Text("原始附件会从本机移除，已导入的指标记录仍保留。") }
    }
}

struct DevicesView: View {
    @EnvironmentObject var store: HealthStore
    #if os(iOS)
    @StateObject private var health = HealthKitService()
    #endif
    var body: some View {
        VStack(spacing: 0) { SheetHeader(title: "连接 Apple 健康"); ScrollView { VStack(alignment: .leading, spacing: 23) { ZStack { Circle().fill(WH.blue.opacity(0.05)).frame(width: 190, height: 190); RoundedRectangle(cornerRadius: 25).fill(LinearGradient(colors: [WH.ink, Color(hex: 0x4B6677)], startPoint: .leading, endPoint: .trailing)).frame(width: 100, height: 135); Image(systemName: "heart.fill").font(.system(size: 45, weight: .light)).foregroundStyle(WH.pink) }.frame(maxWidth: .infinity); SectionHeading(title: "把日常，连接起来", subtitle: "从 Apple 健康读取你允许的记录"); GlassCard { VStack(alignment: .leading, spacing: 13) { ForEach(["静息心率", "血氧饱和度", "血压", "今日步数"], id: \.self) { item in HStack { Image(systemName: "checkmark.circle").foregroundStyle(WH.mint); Text(item).font(.system(size: 14)); Spacer(); Text("只读").font(.system(size: 10)).foregroundStyle(WH.muted) } } } }; Text("点击同步后，系统会让你选择允许读取的数据。应用无法知道某项读取权限是否被拒绝；没有记录时会显示相应提示。").font(.system(size: 12)).foregroundStyle(WH.muted).lineSpacing(5)
            #if os(iOS)
            PrimaryButton(title: health.isLoading ? "正在同步…" : "授权并同步", symbol: "arrow.triangle.2.circlepath") { Task { await health.connect(to: store) } }.disabled(health.isLoading)
            Text(health.status).font(.system(size: 12)).foregroundStyle(WH.muted)
            #else
            Text("Apple 健康同步仅在 iOS 设备上提供。").font(.system(size: 13)).foregroundStyle(WH.muted)
            #endif
        }.padding(24) } }.background(WH.canvas).frame(minWidth: 320, minHeight: 550)
    }
}

struct OrdersView: View {
    @EnvironmentObject var store: HealthStore
    var body: some View { VStack(spacing: 0) { SheetHeader(title: "订单记录"); ScrollView { VStack(spacing: 17) { if store.state.orders.isEmpty { EmptyCard(symbol: "bag", title: "还没有模拟订单", text: "在营养药房选择商品后，可将购物车保存为本地订单记录。") }; ForEach(store.state.orders) { order in GlassCard { VStack(alignment: .leading, spacing: 13) { HStack { Tag(text: "本地模拟订单", color: WH.mint); Spacer(); Text(order.date.formatted(date: .abbreviated, time: .omitted)).font(.system(size: 10)).foregroundStyle(WH.muted) }; ForEach(order.items) { line in HStack { Text(DemoData.products.first { $0.id == line.productID }?.name ?? line.productID).font(.system(size: 13)); Spacer(); Text("× \(line.quantity)").font(.system(size: 12)).foregroundStyle(WH.muted) } }; ThinRule(); HStack { Text("未支付 · 无实际交易").font(.system(size: 10)).foregroundStyle(WH.muted); Spacer(); Text(String(format: "¥%.2f", Double(order.totalCents) / 100)).font(.system(size: 21, weight: .light)) } } } } }.padding(20) } }.background(WH.canvas).frame(minWidth: 320, minHeight: 500) }
}

struct PrivacyView: View {
    var body: some View { VStack(spacing: 0) { SheetHeader(title: "隐私与数据"); ScrollView { VStack(alignment: .leading, spacing: 20) { GlassCard { VStack(alignment: .leading, spacing: 15) { IconTile(symbol: "lock.shield", size: 50); SectionHeading(title: "你的记录，留在你手里", subtitle: "无需账户 · 本地优先"); Text("档案、记录、附件、目标和对话保存在本机的应用沙盒。iOS 文件使用完整文件保护，设备锁定时受系统数据保护机制限制。应用未接入广告、分析 SDK 或云端健康数据库。").font(.system(size: 13)).foregroundStyle(WH.muted).lineSpacing(5) } }; info("Apple 健康", "由你在系统授权界面选择可读取的项目。应用只读取，不写入；可以在系统健康或隐私设置中撤销权限。"); info("文件导入与导出", "文件由你主动选择。PDF 作为原始附件保存；CSV 经校验后导入指标。JSON 导出包含个人记录，附件需单独保存。"); info("通知", "只有你开启目标提醒时才请求通知权限。提醒内容不含具体健康指标。"); info("使用范围", "人体图和生物年龄示意用于可视化展示；健康助手采用本地规则，不提供诊断或处方。药房只支持本地模拟订单。"); info("清除数据", "在「我的档案 → 档案模式」替换档案，会移除本机当前记录及附件。删除前请先保存需要保留的原始文件。卸载应用也可能使本机数据丢失。") }.padding(20) } }.background(WH.canvas).frame(minWidth: 320, minHeight: 550) }
    func info(_ title: String, _ text: String) -> some View { VStack(alignment: .leading, spacing: 9) { Text(title).font(.system(size: 16, weight: .medium)); Text(text).font(.system(size: 13)).foregroundStyle(WH.muted).lineSpacing(5) } }
}
