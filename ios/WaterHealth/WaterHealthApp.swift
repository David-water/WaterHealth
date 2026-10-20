import SwiftUI

@main
struct WaterHealthApp: App {
    @StateObject private var store: HealthStore
    init() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--uitesting") || args.contains("--screenshots") {
            let path = FileManager.default.temporaryDirectory.appendingPathComponent("WaterHealth-Testing-\(UUID().uuidString)")
            let testStore = HealthStore(directory: path)
            if args.contains("--demo") { testStore.finishOnboarding(profile: Profile(), demo: true) }
            if args.contains("--cart-fixture") { testStore.changeCart("daily", delta: 1); testStore.changeCart("omega", delta: 2) }
            if args.contains("--chat-fixture") { testStore.send("帮我总结最近的健康记录") }
            _store = StateObject(wrappedValue: testStore)
        } else { _store = StateObject(wrappedValue: HealthStore()) }
    }
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store).environment(\.locale, Locale(identifier: "zh_CN"))
                .tint(WH.blue)
        }
        #if os(macOS)
        .defaultSize(width: 1180, height: 880)
        #endif
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case twin = "数字孪生", reports = "健康报告", goals = "健康目标", nutrition = "营养药房", profile = "我的档案"
    var id: String { rawValue }
    var short: String { switch self { case .twin: "孪生"; case .reports: "报告"; case .goals: "目标"; case .nutrition: "营养"; case .profile: "我的" } }
    var symbol: String { switch self { case .twin: "square.grid.2x2"; case .reports: "chart.bar.doc.horizontal"; case .goals: "scope"; case .nutrition: "pills"; case .profile: "person.crop.circle" } }
}

struct RootView: View {
    @EnvironmentObject var store: HealthStore
    @State var tab: AppTab = .twin
    @State private var assistant = false
    @State private var cart = false
    init() {
        let args = ProcessInfo.processInfo.arguments
        let selected = args.firstIndex(of: "--tab").flatMap { index in index + 1 < args.count ? AppTab(rawValue: args[index + 1]) : nil } ?? .twin
        _tab = State(initialValue: selected)
        _assistant = State(initialValue: args.contains("--assistant"))
        _cart = State(initialValue: args.contains("--cart"))
    }
    var body: some View {
        Group {
            if store.state.onboardingComplete {
                GeometryReader { geo in
                    let wide = geo.size.width >= 800
                    let dark = tab == .goals
                    ZStack {
                        CanvasBackground(dark: dark)
                        VStack(spacing: 0) {
                            header(wide: wide, dark: dark).padding(.horizontal, wide ? 28 : 20).padding(.top, 9).padding(.bottom, 15)
                            if store.state.isDemo {
                                HStack(spacing: 5) { Circle().fill(WH.blue).frame(width: 4, height: 4); Text("演示档案 · 包含虚构示例记录").font(.system(size: 10)); Spacer(); Text("仅保存在本机").font(.system(size: 10)) }
                                    .foregroundStyle(dark ? .white.opacity(0.4) : WH.muted).padding(.horizontal, wide ? 30 : 22).padding(.bottom, 12)
                            }
                            Group {
                                switch tab {
                                case .twin: TwinView()
                                case .reports: ReportsView()
                                case .goals: GoalsView()
                                case .nutrition: NutritionView()
                                case .profile: ProfileView()
                                }
                            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                            if !wide { bottomBar(dark: dark) }
                        }
                    }
                }
            } else { OnboardingView() }
        }
        .sheet(isPresented: $assistant) { AssistantView().environmentObject(store).frame(minWidth: 320, minHeight: 500) }
        .preferredColorScheme(tab == .goals ? .dark : .light)
        .sheet(isPresented: $cart) { CartView().environmentObject(store).frame(minWidth: 320, minHeight: 500) }
        .alert("暂时无法完成", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) { Button("知道了", role: .cancel) { store.errorMessage = nil } } message: { Text(store.errorMessage ?? "") }
        .alert("WaterHealth", isPresented: Binding(get: { store.notice != nil }, set: { if !$0 { store.notice = nil } })) { Button("好", role: .cancel) { store.notice = nil } } message: { Text(store.notice ?? "") }
    }
    func header(wide: Bool, dark: Bool) -> some View {
        HStack(spacing: 12) {
            Brand(light: dark)
            Spacer(minLength: 6)
            if wide {
                HStack(spacing: 4) {
                    ForEach(AppTab.allCases) { item in
                        Button { tab = item } label: {
                            Text(item.rawValue).font(.system(size: 12, weight: tab == item ? .medium : .regular)).foregroundStyle(tab == item ? .white : dark ? .white.opacity(0.65) : WH.ink).padding(.horizontal, 16).frame(height: 40).background(tab == item ? WH.navy : .clear, in: Capsule())
                        }.buttonStyle(.plain)
                    }
                }
                Spacer(minLength: 6)
            }
            CircleAction(symbol: "sparkles", label: "打开健康助手", dark: dark) { assistant = true }.accessibilityIdentifier("openAssistant")
            if wide {
                CircleAction(symbol: "bag", label: "购物车", dark: dark) { cart = true }
                CircleAction(symbol: "person", label: "我的档案", dark: dark) { tab = .profile }
            }
        }
    }
    func bottomBar(dark: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { item in
                Button { tab = item } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.symbol).font(.system(size: 19, weight: tab == item ? .semibold : .regular))
                        Text(item.short).font(.system(size: 10, weight: tab == item ? .semibold : .regular))
                    }.foregroundStyle(tab == item ? WH.blue : dark ? .white.opacity(0.5) : WH.muted).frame(maxWidth: .infinity).frame(height: 58)
                }.buttonStyle(.plain).accessibilityIdentifier("tab_\(item.id)").accessibilityLabel(item.rawValue).accessibilityAddTraits(tab == item ? .isSelected : [])
            }
        }.padding(.horizontal, 8).padding(.top, 4).background(dark ? WH.dark.opacity(0.95) : .white.opacity(0.96)).overlay(alignment: .top) { Rectangle().fill(WH.line.opacity(dark ? 0.1 : 0.5)).frame(height: 0.5) }
    }
}
