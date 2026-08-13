import SwiftUI
import AppKit

/// 🌟 彻底公开的下载界面，允许被主程序 FlashApp 跨文件夹/跨模块完美调用
public struct DownloadWindowView: View { // 👈 1. 结构体名字确保为 DownloadWindowView
    
    // 🌟 显式公开状态管理器的生命周期，防止跨模块编译断层
    @StateObject public var manager: DownloadManager
    
    // 🌟 公开输入框绑定
    @State public var urlInput: String = ""

    /// 🌟 显式提供公开的无参构造函数，并在内部完成大管家的安全初始化
    public init() { // 👈 2. 初始化函数名字
        self._manager = StateObject(wrappedValue: DownloadManager())
    }

    public var body: some View {
        VStack(spacing: 16) {
            // 1. 顶部链接输入区域
            HStack {
                TextField("请粘贴视频网页链接...", text: $urlInput)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isControlDisabled)
                
                if !urlInput.isEmpty && !isControlDisabled {
                    Button(action: { urlInput = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            HStack(spacing: 8) {
                Text("保存到")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(manager.selectedDownloadURL.path)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("选择...") {
                    chooseDownloadFolder()
                }
                .disabled(isControlDisabled)
            }
            
            // 2. 中间状态与进度条展示区域
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: currentProgress)
                    .progressViewStyle(.linear)
                
                HStack {
                    statusTextView
                    Spacer()
                }
                .font(.caption)
            }
            
            Divider()
            
            // 3. 底部控制按钮区域
            HStack {
                if case .success = manager.currentState {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                if case .success = manager.currentState {
                    Button("打开文件夹") {
                        manager.openLastDownloadFolder()
                    }
                }
                
                Button(action: handleButtonClick) {
                    Text(buttonTitle)
                        .frame(width: 80)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500, height: 220)
        .onDisappear {
            manager.cancelDownloadIfNeeded()
        }
    }
    
    // MARK: - 辅助计算属性
    var isControlDisabled: Bool {
        switch manager.currentState {
        case .downloading, .merging:
            return true
        default:
            return false
        }
    }
    
    var currentProgress: Double {
        switch manager.currentState {
        case .idle, .failure:
            return 0.0
        case .downloading(let progress):
            return progress
        case .merging, .success:
            return 1.0
        }
    }
    
    var buttonTitle: String {
        switch manager.currentState {
        case .downloading, .merging:
            return "取消下载"
        case .success, .failure:
            return "重新下载"
        case .idle:
            return "开始下载"
        }
    }
    
    @ViewBuilder
    var statusTextView: some View {
        switch manager.currentState {
        case .idle:
            Text("就绪，等待下载").foregroundColor(.secondary)
        case .downloading(let progress):
            Text("下载中... \(Int(progress * 100))%").foregroundColor(.blue)
        case .merging:
            Text("视频音频下载完成，正在合并中...").foregroundColor(.orange)
        case .success:
            Text("下载并合并完成！").foregroundColor(.green)
        case .failure(let error):
            Text("❌ 失败: \(error)").foregroundColor(.red)
        }
    }
    
    // MARK: - 交互事件分发
    func handleButtonClick() {
        switch manager.currentState {
        case .downloading, .merging:
            manager.cancelDownload()
        case .idle, .success, .failure:
            manager.startDownload(urlString: urlInput)
        }
    }
    
    func chooseDownloadFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = manager.selectedDownloadURL
        panel.prompt = "选择"
        
        if panel.runModal() == .OK, let folderURL = panel.url {
            manager.updateDownloadFolder(folderURL)
        }
    }
}

// 👈 3. 最底部的预览结构体名字也对应同步
struct DownloadWindowView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadWindowView()
    }
}
