import SwiftUI

enum WH {
    static let blue = Color(hex: 0x147BFA)
    static let navy = Color(hex: 0x15375E)
    static let ink = Color(hex: 0x202B3A)
    static let muted = Color(hex: 0x788696)
    static let canvas = Color(hex: 0xEFF2F5)
    static let line = Color(hex: 0xDCE3EA)
    static let mint = Color(hex: 0x2BB69F)
    static let pink = Color(hex: 0xECA5CE)
    static let amber = Color(hex: 0xEFBA79)
    static let dark = Color(hex: 0x101F2C)
}

extension Color {
    init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1) }
}

struct WaterMark: View {
    var size: CGFloat = 36
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.29).fill(LinearGradient(colors: [Color(hex: 0x74C8ED), WH.blue, WH.navy], startPoint: .topLeading, endPoint: .bottomTrailing))
            WaterGlyph().stroke(.white, style: StrokeStyle(lineWidth: size * 0.065, lineCap: .round, lineJoin: .round)).padding(size * 0.20)
        }.frame(width: size, height: size).accessibilityLabel("WaterHealth 标志")
    }
}

struct WaterGlyph: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addCurve(to: CGPoint(x: r.width * 0.94, y: r.height * 0.64), control1: CGPoint(x: r.width * 0.60, y: r.height * 0.19), control2: CGPoint(x: r.width * 0.96, y: r.height * 0.40))
        p.addCurve(to: CGPoint(x: r.width * 0.06, y: r.height * 0.64), control1: CGPoint(x: r.width * 0.90, y: r.height * 1.08), control2: CGPoint(x: r.width * 0.10, y: r.height * 1.08))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY), control1: CGPoint(x: r.width * 0.03, y: r.height * 0.41), control2: CGPoint(x: r.width * 0.39, y: r.height * 0.20))
        p.move(to: CGPoint(x: r.width * 0.22, y: r.height * 0.54))
        p.addLine(to: CGPoint(x: r.width * 0.36, y: r.height * 0.76))
        p.addLine(to: CGPoint(x: r.width * 0.50, y: r.height * 0.56))
        p.addLine(to: CGPoint(x: r.width * 0.64, y: r.height * 0.76))
        p.addLine(to: CGPoint(x: r.width * 0.78, y: r.height * 0.54))
        return p
    }
}

struct Brand: View {
    var light = false
    var body: some View {
        HStack(spacing: 8) {
            WaterMark(size: 31)
            Text("WaterHealth").font(.system(size: 21, weight: .semibold, design: .rounded)).tracking(-0.8).foregroundStyle(light ? .white : WH.ink)
        }
    }
}

struct CanvasBackground: View {
    var dark = false
    var body: some View {
        GeometryReader { geo in
            ZStack {
                (dark ? WH.dark : WH.canvas)
                Ellipse().fill((dark ? WH.blue : .white).opacity(dark ? 0.13 : 0.8)).frame(width: geo.size.width * 1.4, height: geo.size.height * 0.6).rotationEffect(.degrees(-28)).offset(x: -geo.size.width * 0.35, y: -geo.size.height * 0.3).blur(radius: 40)
                Ellipse().stroke(.white.opacity(dark ? 0.06 : 0.65), lineWidth: 45).frame(width: 650, height: 900).rotationEffect(.degrees(32)).offset(x: 280, y: -140)
                Ellipse().fill(WH.blue.opacity(dark ? 0.11 : 0.05)).frame(width: 440, height: 440).offset(x: 170, y: 400).blur(radius: 70)
            }
        }.ignoresSafeArea().allowsHitTesting(false)
    }
}

struct GlassCard<Content: View>: View {
    var dark = false
    var padding: CGFloat = 18
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(padding).frame(maxWidth: .infinity, alignment: .leading)
            .background(dark ? Color.white.opacity(0.055) : .white.opacity(0.78), in: RoundedRectangle(cornerRadius: 23))
            .overlay(RoundedRectangle(cornerRadius: 23).stroke(.white.opacity(dark ? 0.15 : 0.92), lineWidth: 1))
            .shadow(color: .black.opacity(dark ? 0.04 : 0.035), radius: 15, x: 0, y: 7)
    }
}

struct SectionHeading: View {
    var title: String
    var subtitle: String? = nil
    var dark = false
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 21, weight: .semibold)).foregroundStyle(dark ? .white : WH.ink)
            if let subtitle { Text(subtitle).font(.system(size: 12)).foregroundStyle(dark ? .white.opacity(0.55) : WH.muted).lineSpacing(3) }
        }
    }
}

struct Tag: View {
    var text: String
    var color: Color = WH.blue
    var body: some View {
        HStack(spacing: 4) { Circle().fill(color).frame(width: 4, height: 4); Text(text).font(.system(size: 10, weight: .medium)) }
            .foregroundStyle(color).padding(.horizontal, 8).padding(.vertical, 5).background(color.opacity(0.09), in: Capsule())
    }
}

struct IconTile: View {
    var symbol: String
    var color: Color = WH.blue
    var size: CGFloat = 38
    var body: some View {
        Image(systemName: symbol).font(.system(size: size * 0.43, weight: .light)).foregroundStyle(color)
            .frame(width: size, height: size).background(LinearGradient(colors: [.white, color.opacity(0.16)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: size * 0.30))
            .overlay(RoundedRectangle(cornerRadius: size * 0.30).stroke(.white, lineWidth: 1)).accessibilityHidden(true)
    }
}

struct PrimaryButton: View {
    var title: String
    var symbol: String = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(title).font(.system(size: 15, weight: .medium)); Spacer(); Image(systemName: symbol) }
                .foregroundStyle(.white).padding(.horizontal, 20).frame(minHeight: 49)
                .background(LinearGradient(colors: [WH.blue, Color(hex: 0x0665EB)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
        }.buttonStyle(.plain)
    }
}

struct CircleAction: View {
    var symbol: String
    var label: String
    var dark = false
    var action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 17, weight: .light)).foregroundStyle(dark ? .white : WH.ink).frame(width: 44, height: 44).background(.white.opacity(dark ? 0.1 : 0.8), in: Circle()) }
            .buttonStyle(.plain).accessibilityLabel(label)
    }
}

struct Segments: View {
    let items: [String]
    @Binding var selected: Int
    var dark = false
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(items.indices, id: \.self) { i in
                    Button { withAnimation(.easeInOut(duration: 0.2)) { selected = i } } label: {
                        Text(items[i]).font(.system(size: 12, weight: selected == i ? .medium : .regular)).foregroundStyle(selected == i ? .white : dark ? .white.opacity(0.65) : WH.muted)
                            .padding(.horizontal, 15).frame(minHeight: 39).background(selected == i ? WH.blue : .clear, in: Capsule())
                    }.buttonStyle(.plain).accessibilityAddTraits(selected == i ? .isSelected : [])
                }
            }.padding(4).background(.white.opacity(dark ? 0.08 : 0.7), in: Capsule())
        }
    }
}

struct EmptyCard: View {
    var symbol = "tray"
    var title: String
    var text: String
    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                IconTile(symbol: symbol, size: 50)
                Text(title).font(.system(size: 17, weight: .medium)).foregroundStyle(WH.ink)
                Text(text).font(.system(size: 13)).foregroundStyle(WH.muted).multilineTextAlignment(.center).lineSpacing(4)
            }.frame(maxWidth: .infinity).padding(.vertical, 22)
        }
    }
}

struct SheetHeader: View {
    var title: String
    @Environment(\.dismiss) private var dismiss
    var body: some View { HStack { Text(title).font(.system(size: 21, weight: .semibold)); Spacer(); CircleAction(symbol: "xmark", label: "关闭") { dismiss() } }.padding(20) }
}

struct ThinRule: View { var body: some View { Rectangle().fill(WH.line.opacity(0.65)).frame(height: 1) } }

struct MiniBars: View {
    var value = 7
    var body: some View {
        HStack(spacing: 3) { ForEach(0..<12) { i in Capsule().fill(i < value ? WH.blue : WH.line).frame(width: 5, height: CGFloat(12 + (i % 3) * 5)) } }
    }
}

struct RangeStrip: View {
    var position: Double = 0.56
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(LinearGradient(colors: [WH.amber, WH.pink, Color(hex: 0x8ECBE0), WH.mint, WH.amber], startPoint: .leading, endPoint: .trailing)).frame(height: 5)
                Capsule().fill(WH.navy).frame(width: 3, height: 12).overlay(Capsule().stroke(.white, lineWidth: 1)).offset(x: max(0, geo.size.width - 3) * min(1, max(0, position)))
            }.frame(maxHeight: .infinity)
        }.frame(height: 14).accessibilityHidden(true)
    }
}
