import Foundation
import Combine
import AppKit

/// 🌟 标记下载任务在全生命周期中所处的具体状态
public enum DownloadState: Equatable {
    case idle                         // 空闲，等待粘贴链接
    case downloading(progress: Double) // 正在下载，附带当前进度数字（0.0 到 1.0）
    case merging                      // 视频音频下载完毕，ffmpeg 后台正在合并
    case success                      // 大功告成
    case failure(error: String)       // 出错
}

/// 🌟 整个下载业务的核心总指挥官类
public class DownloadManager: ObservableObject {
    private enum Constants {
        static let selectedDownloadPathKey = "FlashSelectedDownloadPath"
    }
    
    @Published public var currentState: DownloadState = .idle
    @Published public var selectedDownloadURL: URL {
        didSet {
            UserDefaults.standard.set(selectedDownloadURL.path, forKey: Constants.selectedDownloadPathKey)
        }
    }
    @Published public private(set) var lastDownloadFolderURL: URL?
    
    private let ytDlpCaller = CallYtDlp()
    private let textMonitor = Monitor()
    private var lastErrorLog = ""
    
    public init() {
        let fileManager = FileManager.default
        let defaultDownloadURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser
        
        if let savedPath = UserDefaults.standard.string(forKey: Constants.selectedDownloadPathKey) {
            self.selectedDownloadURL = URL(fileURLWithPath: savedPath)
        } else {
            self.selectedDownloadURL = defaultDownloadURL
        }
    }
    
    /// 🌟 外部界面点击“开始下载”时调用的总控制入口
    public func startDownload(urlString: String) {
        let cleanUrl = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUrl.isEmpty else {
            self.currentState = .failure(error: "输入的链接不能为空")
            return
        }
        
        // 1. 动态定位打包进 App 内部的下载组件
        guard let bundledYtDlpPath = Bundle.main.path(forResource: "yt-dlp", ofType: nil) else {
            self.currentState = .failure(error: "未在 App 资源包中找到 yt-dlp 组件")
            return
        }
        
        guard let bundledFfmpegPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil) else {
            self.currentState = .failure(error: "未在 App 资源包中找到 ffmpeg 组件")
            return
        }
        
        let fileManager = FileManager.default
        guard fileManager.isExecutableFile(atPath: bundledYtDlpPath) else {
            self.currentState = .failure(error: "yt-dlp 没有执行权限")
            return
        }
        
        guard fileManager.isExecutableFile(atPath: bundledFfmpegPath) else {
            self.currentState = .failure(error: "ffmpeg 没有执行权限")
            return
        }
        
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: selectedDownloadURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            self.currentState = .failure(error: "下载文件夹不存在")
            return
        }
        
        // 拼装出 yt-dlp 认识的输出模板：下载路径/%(title)s.%(ext)s（意思是：视频标题.当前格式）
        let downloadFolderURL = selectedDownloadURL
        let outputTemplate = downloadFolderURL.appendingPathComponent("%(title)s.%(ext)s").path
        
        // 2. 改变状态为下载中，进度初始为 0
        self.lastErrorLog = ""
        self.currentState = .downloading(progress: 0.0)
        
        // 3. 让底层工具人干活（把合法的下载路径和输出模板一起喂过去）
        ytDlpCaller.launchDownload(
            ytDlpPath: bundledYtDlpPath,
            videoURL: cleanUrl,
            ffmpegPath: bundledFfmpegPath,
            outputPath: outputTemplate, // 👈 完美投喂新参数
            onOutputReceived: { [weak self] rawLog in
                guard let self = self else { return }
                self.handleRawLog(rawLog)
            },
            onLaunchFailure: { [weak self] errorMessage in
                self?.currentState = .failure(error: "无法启动 yt-dlp：\(errorMessage)")
            },
            onTermination: { [weak self] process in
                guard let self = self else { return }
                if process.terminationStatus == 0 {
                    self.lastDownloadFolderURL = downloadFolderURL
                    self.currentState = .success
                } else {
                    if case .failure = self.currentState { return }
                    if self.currentState == .idle { return }
                    self.currentState = .failure(error: self.failureMessageFromLastLog())
                }
            }
        )
    }
    
    public func updateDownloadFolder(_ folderURL: URL) {
        self.selectedDownloadURL = folderURL
    }
    
    public func openLastDownloadFolder() {
        let folderURL = lastDownloadFolderURL ?? selectedDownloadURL
        NSWorkspace.shared.open(folderURL)
    }
    
    public func cancelDownload() {
        ytDlpCaller.stopDownload()
        self.currentState = .idle
    }
    
    public func cancelDownloadIfNeeded() {
        switch currentState {
        case .downloading, .merging:
            cancelDownload()
        default:
            break
        }
    }
    
    private func handleRawLog(_ log: String) {
        if log.localizedCaseInsensitiveContains("error") {
            self.lastErrorLog = log
        }
        
        if textMonitor.checkIfMerging(log: log) {
            self.currentState = .merging
            return
        }
        
        if let parsedPercent = textMonitor.parseProgress(log: log) {
            let normalizedProgress = parsedPercent / 100.0
            if case .downloading = self.currentState {
                self.currentState = .downloading(progress: normalizedProgress)
            }
        }
    }
    
    private func failureMessageFromLastLog() -> String {
        let trimmedLog = lastErrorLog.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLog.isEmpty else {
            return "下载失败：请检查链接有效性或网络连接"
        }
        
        let lastLine = trimmedLog
            .split(whereSeparator: \.isNewline)
            .last
            .map(String.init) ?? trimmedLog
        return "下载失败：\(lastLine)"
    }
}
