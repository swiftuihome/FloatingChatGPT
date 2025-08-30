//
//  FloatingChatGPTApp.swift
//  FloatingChatGPT
//
//  Created by devlink on 2025/8/30.
//

import SwiftUI

@main
struct FloatingChatGPTApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {} // 保留空 Scene
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: FloatingWindowController?
    var containerView: NSView?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 外层容器 View，圆角 + 边框
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
        container.wantsLayer = true
        container.layer?.cornerRadius = 16
        container.layer?.masksToBounds = true
        container.layer?.borderWidth = 1
        container.layer?.borderColor = NSColor.darkGray.cgColor // 默认高亮色
        self.containerView = container
        
        // 毛玻璃背景
        let visualEffectView = NSVisualEffectView(frame: container.bounds)
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        
        container.addSubview(visualEffectView)
        
        // SwiftUI 内容
        let hostingView = NSHostingView(rootView: ContentView())
        hostingView.frame = container.bounds
        hostingView.autoresizingMask = [.width, .height]
        container.addSubview(hostingView)
        
        // 创建悬浮窗口
        windowController = FloatingWindowController(contentView: container)
        windowController?.showWindow(nil)
        
        // 监听焦点高亮
        /**
         NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: windowController?.window, queue: .main) { [weak self] _ in
         self?.containerView?.layer?.borderColor = NSColor.darkGray.cgColor
         }
         NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: windowController?.window, queue: .main) { [weak self] _ in
         self?.containerView?.layer?.borderColor = NSColor.darkGray.cgColor
         }
         */
    }
}

class FloatingWindow: NSWindow {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
}

class FloatingWindowController: NSWindowController {
    convenience init(contentView: NSView) {
        // 获取屏幕的尺寸
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        
        // 计算窗口在屏幕中心的位置
        let windowWidth: CGFloat = 300
        let windowHeight: CGFloat = 400
        let centerX = (screenFrame.width - windowWidth) / 2
        let centerY = (screenFrame.height - windowHeight) / 2
        
        let window = FloatingWindow(
            contentRect: NSRect(x: centerX, y: centerY, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        // 设置窗口最小尺寸
        window.minSize = NSSize(width: 300, height: 400)
        
        window.contentView = contentView
        self.init(window: window)
    }
}

struct FloatingContentView: NSViewRepresentable {
    func makeNSView(context: NSViewRepresentableContext<FloatingContentView>) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        
        let hostingView = NSHostingView(rootView: ContentView())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor)
        ])
        
        return visualEffectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: NSViewRepresentableContext<FloatingContentView>) {}
}

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var messages: [Message] = [
        Message(text: "欢迎使用悬浮 ChatGPT！我是您的AI助手，有什么可以帮您的吗？", isUser: false, timestamp: Date())
    ]
    @FocusState private var isInputFocused: Bool
    
    // 用于自动滚动到底部
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    struct Message: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let timestamp: Date
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("ChatGPT")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 在线状态指示器
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("在线")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // 右上角关闭按钮
                HStack {
                    Spacer()
                    Button(action: closeApplication) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .contentShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("退出应用")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .background(
                VisualEffectView(material: .headerView, blendingMode: .withinWindow)
                    .edgesIgnoringSafeArea(.top)
            )
            
            // 消息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom()
                }
                .onChange(of: messages.count) { _ in
                    scrollToBottom()
                }
            }
            
            // 输入区域
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    TextField("输入消息...", text: $inputText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isInputFocused)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(cgColor: NSColor.darkGray.cgColor), lineWidth: 1)
                        )
                        .onSubmit(sendMessage)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(inputText.isEmpty ? .gray : .blue)
                        //.contentTransition(.symbolEffect)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(inputText.isEmpty)
                    .keyboardShortcut(.return, modifiers: [])
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                VisualEffectView(material: .underWindowBackground, blendingMode: .withinWindow)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // 自动聚焦到输入框
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }
    
    // 关闭应用的方法 - 添加确认对话框
    private func closeApplication() {
        let alert = NSAlert()
        alert.messageText = "退出应用"
        alert.informativeText = "确定要退出悬浮 ChatGPT 吗？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "退出")
        alert.addButton(withTitle: "取消")
        
        // 显示对话框并处理结果
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let userMessage = Message(text: inputText, isUser: true, timestamp: Date())
        messages.append(userMessage)
        
        inputText = ""
        isInputFocused = true
        
        // 模拟AI回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let aiResponse = Message(
                text: "我已经收到您的消息：\"\(userMessage.text)\"。有什么其他问题吗？",
                isUser: false,
                timestamp: Date()
            )
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                messages.append(aiResponse)
            }
        }
    }
    
    private func scrollToBottom() {
        guard let lastMessage = messages.last else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

#Preview {
    ContentView()
}


// 消息气泡组件
struct MessageBubble: View {
    let message: ContentView.Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                messageContent
            } else {
                messageContent
                Spacer()
            }
        }
    }
    
    private var messageContent: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            Text(message.text)
                .font(.system(size: 14))
                .foregroundColor(message.isUser ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    message.isUser ?
                    AnyView(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    ) :
                        AnyView(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primary.opacity(0.1))
                        )
                )
            
            Text(timestampString)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var timestampString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
}

// VisualEffectView 用于 SwiftUI
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
