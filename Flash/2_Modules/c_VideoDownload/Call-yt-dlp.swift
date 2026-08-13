import Foundation

/// 🌟 专门负责调用系统底层终端并运行 yt-dlp 的工具类
public class CallYtDlp {
    
    // 持有当前正在运行的后台进程，方便中途强行取消
    private var currentProcess: Process?
    
    public init() {}
    
    public func launchDownload(
        ytDlpPath: String,
        videoURL: String,
        ffmpegPath: String,
        outputPath: String,
        onOutputReceived: @escaping (String) -> Void,
        onLaunchFailure: @escaping (String) -> Void,
        onTermination: @escaping (Process) -> Void
    ) {
        // 1. 创建一个独立的后台进程
        let process = Process()
        self.currentProcess = process
        
        // 2. 直接调用 App 包内的 yt-dlp，避免依赖系统 PATH
        process.executableURL = URL(fileURLWithPath: ytDlpPath)
        
        // 3. 用参数数组传值，避免 URL 或路径里的特殊字符被 Shell 误解
        process.arguments = [
            videoURL,
            "--progress",
            "--ffmpeg-location", ffmpegPath,
            "-o", outputPath,
            "-f", "bestvideo+bestaudio/best",
            "--merge-output-format", "mp4"
        ]
        
        // 5. 部署“隐形管道（Pipe）”：拦截终端输出流
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe // 错误日志也并入同一管道，防止漏掉报错
        
        // 6. 开启多线程监听：只要后台工具人吐出一个字，立刻无延迟抓取
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            
            // 将二进制数据翻译成看得懂的 String 文本
            if let outputString = String(data: data, encoding: .utf8) {
                // 异步抛回主线程，确保 UI 刷新不卡顿
                DispatchQueue.main.async {
                    onOutputReceived(outputString)
                }
            }
        }
        
        // 7. 部署进程结束监听器
        process.terminationHandler = { finishedProcess in
            // 关闭管道，释放内存
            outputPipe.fileHandleForReading.readabilityHandler = nil
            self.currentProcess = nil
            
            DispatchQueue.main.async {
                onTermination(finishedProcess)
            }
        }
        
        // 8.正式在后台启动下载任务
        do {
            try process.run()
        } catch {
            print("❌ Flash 致命错误：无法拉起后台进程 -> \(error.localizedDescription)")
            self.currentProcess = nil
            onLaunchFailure(error.localizedDescription)
        }
    }
    
    /// 🌟 用户中途点击“取消下载”时调用的强杀函数
    public func stopDownload() {
        if currentProcess?.isRunning == true {
            currentProcess?.terminate()
        }
        currentProcess = nil
    }
}
