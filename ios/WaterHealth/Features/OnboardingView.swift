import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: HealthStore
    @State private var step = 0
    @State private var profile = Profile()
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(stops: [.init(color: Color(hex: 0x779FC0), location: 0), .init(color: Color(hex: 0xD8B5AA), location: 0.32), .init(color: Color(hex: 0xAB6F50), location: 0.50), .init(color: Color(hex: 0x1A2937), location: 0.67), .init(color: Color(hex: 0x0E1922), location: 1)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                Circle().fill(Color(hex: 0xF8D8A9)).frame(width: 140, height: 140).blur(radius: 40).offset(x: -120, y: -30)
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        Brand(light: true).padding(.top, 20)
                        Spacer(minLength: 20)
                        if step == 0 {
                            Text("你的身体，\n值得更懂一点。").font(.system(size: geo.size.width > 700 ? 47 : 35, weight: .light)).tracking(-1).foregroundStyle(.white).lineSpacing(8)
                            Text("连接每一份健康记录，\n看见属于你的完整健康图景。").font(.system(size: 15)).foregroundStyle(.white.opacity(0.75)).lineSpacing(6)
                            ZStack {
                                Circle().stroke(.white.opacity(0.14), lineWidth: 1).frame(width: 260, height: 260)
                                Circle().fill(.white.opacity(0.1)).frame(width: 205, height: 205).blur(radius: 10)
                                Image("DigitalTwin").resizable().scaledToFit().frame(height: 315)
                                VStack { Spacer(); HStack { Image(systemName: "heart.text.square"); Text("从一份档案，认识自己") }.font(.system(size: 12)).foregroundStyle(.white).padding(13).background(.ultraThinMaterial, in: Capsule()) }.padding(.bottom, 16)
                            }.frame(maxWidth: .infinity).frame(height: 320)
                            PrimaryButton(title: "建立我的健康档案") { withAnimation { step = 1 } }.accessibilityIdentifier("startProfile")
                            Button { store.finishOnboarding(profile: profile, demo: true) } label: { Text("先体验演示档案  →").font(.system(size: 14)).foregroundStyle(.white.opacity(0.85)).frame(maxWidth: .infinity).frame(height: 42) }.buttonStyle(.plain).accessibilityIdentifier("demoEntry")
                        } else {
                            Text("建立你的\n健康档案").font(.system(size: 36, weight: .light)).foregroundStyle(.white).lineSpacing(6)
                            Text("资料只保存在这台设备，你可以随时修改。 ").font(.system(size: 13)).foregroundStyle(.white.opacity(0.65))
                            GlassCard(dark: true, padding: 22) {
                                VStack(alignment: .leading, spacing: 21) {
                                    label("怎么称呼你")
                                    TextField("你的名字", text: $profile.name).textFieldStyle(.plain).font(.system(size: 17)).foregroundStyle(.white).padding(14).background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12)).accessibilityIdentifier("profileName")
                                    label("性别（可选）")
                                    HStack(spacing: 10) {
                                        ForEach(["男", "女", "未设置"], id: \.self) { sex in
                                            Button { profile.sex = sex } label: { Text(sex).font(.system(size: 15)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 47).background(profile.sex == sex ? WH.blue : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 13)) }.buttonStyle(.plain)
                                        }
                                    }
                                    HStack { label("年龄"); Spacer(); Text("\(profile.age) 岁").foregroundStyle(.white) }
                                    Slider(value: Binding(get: { Double(profile.age) }, set: { profile.age = Int($0) }), in: 18...100, step: 1).accessibilityLabel("年龄")
                                    HStack { label("身高"); Spacer(); Stepper("\(Int(profile.height)) cm", value: $profile.height, in: 100...230, step: 1).foregroundStyle(.white) }
                                    HStack { label("体重"); Spacer(); Stepper("\(Metric.format(profile.weight)) kg", value: $profile.weight, in: 30...250, step: 0.5).foregroundStyle(.white) }
                                }
                            }
                            HStack(alignment: .top, spacing: 8) { Image(systemName: "lock.shield"); Text("无需注册。数据不上传服务器；连接 Apple 健康、导入文件和通知均由你主动开启。").lineSpacing(4) }.font(.system(size: 11)).foregroundStyle(.white.opacity(0.6))
                            PrimaryButton(title: "开启我的健康旅程") { if profile.name.trimmingCharacters(in: .whitespaces).isEmpty { profile.name = "朋友" }; store.finishOnboarding(profile: profile, demo: false) }
                            Button("返回") { step = 0 }.buttonStyle(.plain).foregroundStyle(.white.opacity(0.6)).frame(maxWidth: .infinity).frame(height: 44)
                        }
                        Text("WaterHealth 提供记录与信息整理，不提供医学诊断。").font(.system(size: 10)).foregroundStyle(.white.opacity(0.45)).frame(maxWidth: .infinity).multilineTextAlignment(.center)
                    }.padding(28).frame(maxWidth: 480).frame(maxWidth: .infinity)
                }
            }
        }
    }
    func label(_ text: String) -> some View { Text(text).font(.system(size: 12)).foregroundStyle(.white.opacity(0.75)) }
}
