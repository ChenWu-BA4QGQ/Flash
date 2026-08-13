import Foundation
import Combine

/// 闪念胶囊的底层业务及文件 I/O 核心大管家
public class QuicknoteManager: ObservableObject {
    
    private enum Constants {
        static let storagePathKey = "FlashNoteStoragePath"
        static let namingModeKey = "FlashNoteNamingMode"
        static let customTextKey = "FlashNoteCustomText"
        static let defaultCustomText = "Note"
        static let maxHistoryCount = 10
        static let mdExtension = "md"
    }
    
    /// 驱动 UI 侧边栏实时刷新的核心数据源
    @Published public private(set) var recentNotes: [NoteModel] = []
    
    @Published public var storagePath: String {
        didSet {
            UserDefaults.standard.set(storagePath, forKey: Constants.storagePathKey)
            restartWatching()
        }
    }
    @Published public var namingMode: Int {
        didSet { UserDefaults.standard.set(namingMode, forKey: Constants.namingModeKey) }
    }
    @Published public var customText: String {
        didSet { UserDefaults.standard.set(customText, forKey: Constants.customTextKey) }
    }
    
    private var folderWatcherSource: DispatchSourceFileSystemObject?
    private var folderFileDescriptor: Int32 = -1
    
    public init() {
        let defaultPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? NSHomeDirectory()
        
        self.storagePath = UserDefaults.standard.string(forKey: Constants.storagePathKey) ?? defaultPath
        self.namingMode = UserDefaults.standard.integer(forKey: Constants.namingModeKey)
        self.customText = UserDefaults.standard.string(forKey: Constants.customTextKey) ?? Constants.defaultCustomText
        
        loadRecentNotes()
    }
    
    public func startWatchingStorageFolder() {
        stopWatchingStorageFolder()
        
        let folderURL = URL(fileURLWithPath: storagePath)
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: folderURL.path) {
            try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        folderFileDescriptor = open(folderURL.path, O_EVTONLY)
        guard folderFileDescriptor >= 0 else { return }
        
        folderWatcherSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: folderFileDescriptor,
            eventMask: [.write],
            queue: DispatchQueue.global(qos: .userInteractive)
        )
        
        folderWatcherSource?.setEventHandler { [weak self] in
            self?.loadRecentNotes()
        }
        
        folderWatcherSource?.setCancelHandler { [weak self] in
            if let fd = self?.folderFileDescriptor, fd >= 0 {
                close(fd)
            }
            self?.folderFileDescriptor = -1
        }
        
        folderWatcherSource?.resume()
    }
    
    public func stopWatchingStorageFolder() {
        folderWatcherSource?.cancel()
        folderWatcherSource = nil
    }
    
    private func restartWatching() {
        stopWatchingStorageFolder()
        loadRecentNotes()
        startWatchingStorageFolder()
    }
    
    /// 🌟 优化第 4 点：引入高效率差量比对算法，拒绝直接全量覆写导致的 UI 闪烁卡顿
    public func loadRecentNotes() {
        let fileManager = FileManager.default
        let folderURL = URL(fileURLWithPath: storagePath)
        
        if !fileManager.fileExists(atPath: folderURL.path) {
            try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
            let mdFiles = fileURLs.filter { $0.pathExtension.lowercased() == Constants.mdExtension }
            
            let models = mdFiles.compactMap { url -> NoteModel? in
                guard let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
                      let modDate = resourceValues.contentModificationDate else { return nil }
                guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                let title = url.deletingPathExtension().lastPathComponent
                
                return NoteModel(url: url, title: title, content: content, modifiedDate: modDate)
            }
            
            let sortedNewModels = Array(models.sorted { $0.modifiedDate > $1.modifiedDate }.prefix(Constants.maxHistoryCount))
            
            DispatchQueue.main.async {
                // 核心微调比对：若新旧数组完全一致，直接跳过，保护原有滚动动画
                if self.recentNotes == sortedNewModels { return }
                self.recentNotes = sortedNewModels
            }
        } catch {
            print("❌ Flash 同步刷新失败: \(error.localizedDescription)")
        }
    }
    
    public func saveNote(title: String, content: String, overridingNote: NoteModel? = nil) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        let fileManager = FileManager.default
        let folderURL = URL(fileURLWithPath: storagePath)
        var targetFileURL: URL
        
        let sanitizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "/", with: "_")
        
        if !sanitizedTitle.isEmpty {
            targetFileURL = folderURL.appendingPathComponent("\(sanitizedTitle).\(Constants.mdExtension)")
        } else {
            targetFileURL = generateUniqueURL(in: folderURL)
        }
        
        if let oldNote = overridingNote, oldNote.url != targetFileURL {
            if fileManager.fileExists(atPath: oldNote.url.path) {
                try? fileManager.removeItem(at: oldNote.url)
            }
        }
        
        do {
            try trimmedContent.write(to: targetFileURL, atomically: true, encoding: .utf8)
            loadRecentNotes()
        } catch {
            print("❌ Flash 写入失败: \(error.localizedDescription)")
        }
    }
    
    public func deleteNoteFile(at url: URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
            loadRecentNotes()
        }
    }
    
    public func duplicateNote(note: NoteModel) {
        let folderURL = URL(fileURLWithPath: storagePath)
        let targetFileURL = generateUniqueURL(in: folderURL)
        
        do {
            let content = try String(contentsOf: note.url, encoding: .utf8)
            try content.write(to: targetFileURL, atomically: true, encoding: .utf8)
            loadRecentNotes()
        } catch {
            print("❌ Flash 复制失败: \(error.localizedDescription)")
        }
    }
    
    private func generateUniqueURL(in folderURL: URL) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd"
        let dateString = formatter.string(from: Date())
        
        let fileManager = FileManager.default
        let currentCustomText = UserDefaults.standard.string(forKey: Constants.customTextKey) ?? Constants.defaultCustomText
        let cleanCustomText = currentCustomText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "/", with: "_")
        
        var maxSequence = 0
        
        if let fileURLs = try? fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil) {
            let mdFiles = fileURLs.filter { $0.pathExtension.lowercased() == Constants.mdExtension }
            
            for url in mdFiles {
                let name = url.deletingPathExtension().lastPathComponent
                var numberStr = ""
                
                if namingMode == 0 {
                    let prefix = "\(cleanCustomText)_\(dateString)_"
                    if name.hasPrefix(prefix) {
                        numberStr = name.replacingOccurrences(of: prefix, with: "")
                    }
                } else {
                    let prefix = "\(dateString)_"
                    let suffix = "_\(cleanCustomText)"
                    if name.hasPrefix(prefix) && name.hasSuffix(suffix) {
                        numberStr = String(name.dropFirst(prefix.count).dropLast(suffix.count))
                    }
                }
                
                if let seq = Int(numberStr), seq > maxSequence {
                    maxSequence = seq
                }
            }
        }
        
        let sequenceNumber = maxSequence + 1
        let numberString = "\(dateString)_\(sequenceNumber)"
        let fileName = namingMode == 0 ? "\(cleanCustomText)_\(numberString).\(Constants.mdExtension)" : "\(numberString)_\(cleanCustomText).\(Constants.mdExtension)"
        
        return folderURL.appendingPathComponent(fileName)
    }
}
