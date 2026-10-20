import SwiftUI

struct AssistantView: View {
    @EnvironmentObject var store: HealthStore
    @State private var input = ""
    @State private var clear = false
    @FocusState private var focused: Bool
    var body: some View {
        VStack(spacing: 0) {
            HStack { WaterMark(size: 34); VStack(alignment: .leading, spacing: 3) { Text("健康助手").font(.system(size: 20, weight: .medium)); Text("本地数据解读 · 无需联网").font(.system(size: 10)).foregroundStyle(WH.muted) }; Spacer(); Button { clear = true } label: { Image(systemName: "trash").foregroundStyle(WH.muted).frame(width: 35, height: 44) }.buttonStyle(.plain).accessibilityLabel("清空对话"); DismissButton() }.padding(20)
            ThinRule()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if store.state.chat.isEmpty {
                            VStack(alignment: .leading, spacing: 19) {
                                Image(systemName: "sparkles").font(.system(size: 35, weight: .ultraLight)).foregroundStyle(WH.blue).padding(.top, 25)
                                Text("你好，\(store.state.profile.name.isEmpty ? "朋友" : store.state.profile.name)。\n一起理清健康记录。").font(.system(size: 27, weight: .light)).lineSpacing(6)
                                Text("我可以整理最近的指标、回顾目标和解释应用的使用方式。").font(.system(size: 13)).foregroundStyle(WH.muted).lineSpacing(4)
                                ForEach(["帮我总结最近的健康记录", "我的目标完成得怎么样？", "回顾一下我的睡眠记录"], id: \.self) { prompt in
                                    Button { store.send(prompt) } label: { HStack { Text(prompt).font(.system(size: 13)); Spacer(); Image(systemName: "arrow.up.right").font(.system(size: 11)) }.foregroundStyle(WH.blue).padding(17).background(.white, in: RoundedRectangle(cornerRadius: 15)) }.buttonStyle(.plain)
                                }
                            }
                        }
                        ForEach(store.state.chat) { message in
                            HStack(alignment: .top, spacing: 9) {
                                if message.isUser { Spacer(minLength: 35) } else { WaterMark(size: 26).padding(.top, 3) }
                                Text(message.text).font(.system(size: 14)).lineSpacing(5).foregroundStyle(message.isUser ? .white : WH.ink).textSelection(.enabled).padding(16).background(message.isUser ? WH.blue : .white, in: RoundedRectangle(cornerRadius: 19)).frame(maxWidth: 600, alignment: .leading)
                                if !message.isUser { Spacer(minLength: 20) }
                            }.id(message.id)
                        }
                        Text("基于本机记录的规则解读，未连接大模型。不能提供诊断、处方或药物剂量。").font(.system(size: 10)).foregroundStyle(WH.muted).lineSpacing(4).padding(.top, 10)
                    }.padding(20)
                }.onChange(of: store.state.chat.count) { _, _ in if let last = store.state.chat.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } } }
            }
            HStack(alignment: .bottom, spacing: 12) {
                TextField("聊聊你的健康记录…", text: $input, axis: .vertical).lineLimit(1...4).textFieldStyle(.plain).font(.system(size: 14)).focused($focused).onSubmit(send).accessibilityIdentifier("chatInput")
                Button(action: send) { Image(systemName: "arrow.up").font(.system(size: 17, weight: .medium)).foregroundStyle(.white).frame(width: 40, height: 40).background(WH.blue, in: Circle()) }.buttonStyle(.plain).disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityLabel("发送").accessibilityIdentifier("sendChat")
            }.padding(12).padding(.leading, 5).background(.white, in: RoundedRectangle(cornerRadius: 24)).padding(16)
        }.background(WH.canvas).frame(minWidth: 320, minHeight: 540)
        .alert("清空对话？", isPresented: $clear) { Button("取消", role: .cancel) {}; Button("清空", role: .destructive) { store.clearChat() } } message: { Text("所有对话记录将从本机移除。") }
    }
    func send() { store.send(input); input = ""; focused = false }
}

struct DismissButton: View {
    @Environment(\.dismiss) var dismiss
    var body: some View { CircleAction(symbol: "xmark", label: "关闭") { dismiss() } }
}
