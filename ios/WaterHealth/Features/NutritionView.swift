import SwiftUI

struct NutritionView: View {
    @EnvironmentObject var store: HealthStore
    @State private var category = ProcessInfo.processInfo.arguments.contains("--shop") ? 1 : 0
    @State private var cart = false
    @State private var product: Product?
    @State private var search = ""
    let ingredients = ["复合维生素", "Omega-3", "镁元素", "维生素 D", "钙元素", "辅酶 Q10"]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 21) {
                HStack { SectionHeading(title: "让照顾，更贴近你", subtitle: "了解营养成分，整理专属健康清单"); Spacer(); Button { cart = true } label: { ZStack(alignment: .topTrailing) { IconTile(symbol: "bag", size: 44); if store.cartCount > 0 { Text("\(store.cartCount)").font(.system(size: 9, weight: .bold)).foregroundStyle(.white).padding(5).background(WH.blue, in: Circle()).offset(x: 4, y: -4) } } }.buttonStyle(.plain).accessibilityLabel("购物车 \(store.cartCount) 件").accessibilityIdentifier("openCart") }
                Segments(items: ["专属营养方案", "健康药房"], selected: $category)
                if category == 0 {
                    GlassCard {
                        HStack(alignment: .center, spacing: 18) {
                            BottleView(color: WH.blue, symbol: "leaf", name: "DAILY").frame(width: 94, height: 145)
                            VStack(alignment: .leading, spacing: 11) { Tag(text: "WaterHealth 营养清单"); Text("每个人的需求，\n都值得认真了解。").font(.system(size: 20, weight: .light)).lineSpacing(4); Text("从成分档案开始，与医生或药师共同讨论适合你的方案。").font(.system(size: 11)).foregroundStyle(WH.muted).lineSpacing(4) }
                        }
                    }
                    SectionHeading(title: "我的成分清单", subtitle: "已选择 \(store.state.ingredients.count) 项 · 仅整理清单，不决定剂量")
                    ForEach(ingredients, id: \.self) { name in
                        Button { store.toggleIngredient(name) } label: {
                            GlassCard(padding: 16) { HStack(spacing: 12) { Image(systemName: store.state.ingredients.contains(name) ? "checkmark.circle.fill" : "circle").font(.system(size: 19, weight: .light)).foregroundStyle(store.state.ingredients.contains(name) ? WH.mint : WH.line); VStack(alignment: .leading, spacing: 5) { Text(name).font(.system(size: 14, weight: .medium)); Text("添加到与专业人士讨论的清单").font(.system(size: 10)).foregroundStyle(WH.muted) }; Spacer(); Image(systemName: "plus").font(.system(size: 11)).foregroundStyle(WH.blue) }.foregroundStyle(WH.ink) }
                        }.buttonStyle(.plain).accessibilityLabel("\(store.state.ingredients.contains(name) ? "移除" : "选择")\(name)")
                    }
                    PrimaryButton(title: "浏览健康药房", symbol: "pills") { category = 1 }
                } else {
                    HStack { Image(systemName: "magnifyingglass").foregroundStyle(WH.muted); TextField("搜索营养品、检测套装", text: $search).textFieldStyle(.plain).font(.system(size: 13)); if !search.isEmpty { Button { search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(WH.muted) }.buttonStyle(.plain) } }.padding(14).background(.white.opacity(0.8), in: Capsule())
                    let products = DemoData.products.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.category.contains(search) }
                    if products.isEmpty { EmptyCard(symbol: "magnifyingglass", title: "没有找到相关商品", text: "试试「营养」或「检测」。") }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 13)], spacing: 13) {
                        ForEach(products) { item in
                            Button { product = item } label: {
                                GlassCard(padding: 15) { VStack(alignment: .leading, spacing: 12) { BottleView(color: Color(hex: item.colorHex), symbol: item.symbol, name: item.id.uppercased()).frame(height: 145).frame(maxWidth: .infinity); Tag(text: item.category, color: Color(hex: item.colorHex)); Text(item.name).font(.system(size: 15, weight: .medium)); Text(item.subtitle).font(.system(size: 10)).foregroundStyle(WH.muted).lineLimit(2).frame(minHeight: 28, alignment: .top); HStack { Text(item.priceText).font(.system(size: 17, weight: .medium)); Spacer(); Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundStyle(WH.blue) } }.foregroundStyle(WH.ink) }
                            }.buttonStyle(.plain)
                        }
                    }
                }
                Text("商品和价格用于本地购物流程演示，不能支付或实际下单。营养品使用与剂量请咨询医生或药师。").font(.system(size: 10)).foregroundStyle(WH.muted).lineSpacing(4)
            }.padding(20).padding(.bottom, 15)
        }
        .sheet(isPresented: $cart) { CartView().environmentObject(store) }
        .sheet(item: $product) { ProductDetailView(product: $0).environmentObject(store) }
    }
}

struct BottleView: View {
    var color: Color
    var symbol: String
    var name: String
    var body: some View {
        GeometryReader { geo in
            let width = min(92.0, geo.size.width * 0.75)
            ZStack {
                Ellipse().fill(color.opacity(0.12)).frame(width: width * 1.2, height: 15).blur(radius: 7).offset(y: 63)
                RoundedRectangle(cornerRadius: 18).fill(LinearGradient(colors: [Color.white.opacity(0.5), color.opacity(0.27), color.opacity(0.5), color.opacity(0.15)], startPoint: .leading, endPoint: .trailing)).frame(width: width, height: 113).overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.8), lineWidth: 1)).offset(y: 6)
                RoundedRectangle(cornerRadius: 5).fill(LinearGradient(colors: [WH.ink, Color(hex: 0x547081), WH.ink], startPoint: .leading, endPoint: .trailing)).frame(width: width * 0.88, height: 23).offset(y: -52)
                VStack(spacing: 5) { Image(systemName: symbol).font(.system(size: 18, weight: .light)); Text("WaterHealth").font(.system(size: 8, weight: .semibold)); Text(String(name.prefix(10))).font(.system(size: 7)).tracking(1); Rectangle().fill(.white.opacity(0.3)).frame(height: 0.5); Text("日常 · 用心").font(.system(size: 6)) }.foregroundStyle(.white).padding(8).frame(width: width + 1, height: 64).background(color.opacity(0.95)).offset(y: 13)
            }.frame(width: geo.size.width, height: geo.size.height)
        }.accessibilityHidden(true)
    }
}

struct ProductDetailView: View {
    @EnvironmentObject var store: HealthStore
    @Environment(\.dismiss) var dismiss
    let product: Product
    @State private var added = false
    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "成分与商品档案")
            ScrollView { VStack(alignment: .leading, spacing: 22) { BottleView(color: Color(hex: product.colorHex), symbol: product.symbol, name: product.id.uppercased()).frame(height: 245).frame(maxWidth: .infinity).background(LinearGradient(colors: [.white, Color(hex: product.colorHex).opacity(0.06)], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 25)); Tag(text: product.category); Text(product.name).font(.system(size: 28, weight: .light)); Text(product.subtitle).font(.system(size: 14)).foregroundStyle(WH.muted); GlassCard { VStack(alignment: .leading, spacing: 12) { Text("使用前，先了解").font(.system(size: 17, weight: .medium)); Text("这是一份演示商品档案，不构成针对个人的营养或用药建议。请与专业人士核对是否适合、与现有药物是否存在相互作用，并以实际商品标签为准。").font(.system(size: 13)).foregroundStyle(WH.muted).lineSpacing(5) } }; HStack { Text(product.priceText).font(.system(size: 28, weight: .light)); Spacer(); Tag(text: "演示价格") }; PrimaryButton(title: added ? "已加入购物车" : "加入购物车", symbol: added ? "checkmark" : "bag") { store.changeCart(product.id, delta: 1); added = true }; Text("本地模拟流程 · 无支付和物流服务").font(.system(size: 11)).foregroundStyle(WH.muted).frame(maxWidth: .infinity) }.padding(20) }
        }.background(WH.canvas).frame(minWidth: 320, minHeight: 550)
    }
}

struct CartView: View {
    @EnvironmentObject var store: HealthStore
    @State private var confirm = false
    @State private var success = false
    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: success ? "计划已保存" : "购物车")
            ScrollView {
                VStack(spacing: 15) {
                    if success { EmptyCard(symbol: "checkmark.seal", title: "模拟订单已保存", text: "可在「我的 → 订单记录」回顾你的清单。没有发生支付，也没有向商家提交订单。") }
                    else if store.state.cart.isEmpty { EmptyCard(symbol: "bag", title: "购物车还是空的", text: "在健康药房打开商品档案，添加你想了解的产品。") }
                    ForEach(store.state.cart) { line in
                        if let product = DemoData.products.first(where: { $0.id == line.productID }) {
                            GlassCard { HStack(spacing: 13) { BottleView(color: Color(hex: product.colorHex), symbol: product.symbol, name: product.id.uppercased()).frame(width: 67, height: 115); VStack(alignment: .leading, spacing: 12) { Text(product.name).font(.system(size: 15, weight: .medium)); Text(product.priceText).font(.system(size: 12)).foregroundStyle(WH.muted); HStack(spacing: 15) { Button { store.changeCart(product.id, delta: -1) } label: { Image(systemName: "minus.circle").font(.system(size: 21)).frame(width: 30, height: 30) }.buttonStyle(.plain).accessibilityLabel("减少\(product.name)"); Text("\(line.quantity)").font(.system(size: 14)).monospacedDigit(); Button { store.changeCart(product.id, delta: 1) } label: { Image(systemName: "plus.circle").font(.system(size: 21)).frame(width: 30, height: 30) }.buttonStyle(.plain).accessibilityLabel("增加\(product.name)") }.foregroundStyle(WH.blue) }; Spacer() } }
                        }
                    }
                }.padding(20)
            }
            if !store.state.cart.isEmpty {
                VStack(spacing: 15) { HStack { Text("总计").font(.system(size: 13)); Spacer(); Text(String(format: "¥%.2f", Double(store.cartTotal) / 100)).font(.system(size: 26, weight: .light)) }; PrimaryButton(title: "保存模拟订单", symbol: "checkmark") { confirm = true }; Text("不会支付或向商家下单").font(.system(size: 10)).foregroundStyle(WH.muted) }.padding(20).background(.white.opacity(0.9))
            }
        }.background(WH.canvas).frame(minWidth: 320, minHeight: 520)
        .alert("保存为模拟订单？", isPresented: $confirm) { Button("取消", role: .cancel) {}; Button("保存") { if store.checkout() { success = true } } } message: { Text("清单将保存在本机，购物车随后清空。没有实际交易。") }
    }
}
