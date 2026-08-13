import Foundation

/// 🌟 专门负责死死盯着终端输出日志、解析进度和状态的翻译官类
public class Monitor {
    
    // 创建一个精准匹配类似 "[download]  23.5% of" 中数字的正则表达式
    private var regex: NSRegularExpression?
    
    public init() {
        // 使用正则公式：抓取 [download] 后面跟着的任意数字、小数点及其后的数字
        let pattern = #"(?:\[download\])\s+(\d+(?:\.\d+)?)"#
        do {
            self.regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        } catch {
            print("❌ Flash 内部错误：无法创建正则表达式处理器")
        }
    }
    
    /// 🌟 核心解析函数：从一行原始日志中抠出下载百分比
    /// - Parameter log: 终端吐出来的一整行原始文本
    /// - Returns: 解析出来的浮点型数字（0.0 到 100.0），如果没匹配到则返回 nil
    public func parseProgress(log: String) -> Double? {
        guard let regex = self.regex, !log.isEmpty else { return nil }
        
        let range = NSRange(log.startIndex..<log.endIndex, in: log)
        
        // 在这一行字里寻找符合公式的段落
        if let match = regex.firstMatch(in: log, options: [], range: range) {
            // 抓取第一个括号里捕获到的纯数字文本
            if let percentRange = Range(match.range(at: 1), in: log) {
                let percentString = log[percentRange]
                // 把提取出的字符串转成 Swift 的 Double 数字
                return Double(percentString)
            }
        }
        return nil
    }
    
    /// 🌟 核心检测函数：判断终端是否正在用 ffmpeg 合并音视频
    /// - Parameter log: 终端吐出来的一整行原始文本
    /// - Returns: 如果正在合并返回 true，否则返回 false
    public func checkIfMerging(log: String) -> Bool {
        // yt-dlp 在合并时通常会吐出包含 [Merger] 或 Merging formats 的特有日志
        if log.contains("[Merger]") || log.contains("Merging formats") {
            return true
        }
        return false
    }
}
