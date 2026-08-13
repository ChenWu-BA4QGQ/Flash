import SwiftUI

// 统一纳管窗口内所有组件的焦点枚举
private enum QuicknoteField: Hashable {
    case title
    case body
}

public struct QuicknoteWindowView: View {
    @ObservedObject var manager: QuicknoteManager
    
    @State private var customTitleInput: String = ""
    @State private var textInput: String = ""
    @State private var editingNote: NoteModel? = nil
    
    // 🌟 统一的原生焦点管理器
    @FocusState private var focusedField: QuicknoteField?
    
    var onDismiss: () -> Void
    
    private func autoSaveCurrentWorkIfNeeded() {
        let trimmed = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            if editingNote == nil || editingNote?.content != textInput || editingNote?.title != customTitleInput {
                manager.saveNote(title: customTitleInput, content: textInput, overridingNote: editingNote)
            }
        } else if let noteToCleanup = editingNote {
            manager.deleteNoteFile(at: noteToCleanup.url)
        }
    }
    
    public var body: some View {
        HSplitView {
            // ================= 左侧历史区域 =================
            VStack(spacing: 0) {
                List {
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 11))
                        Text("新胶囊")
                            .font(.system(size: 13, weight: .regular))
                    }
                    .foregroundColor(editingNote == nil ? .accentColor : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                    .listRowBackground(editingNote == nil ? Color(NSColor.selectedControlColor).opacity(0.4) : Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        autoSaveCurrentWorkIfNeeded()
                        editingNote = nil
                        customTitleInput = ""
                        textInput = ""
                        focusedField = .body
                    }
                    
                    ForEach(manager.recentNotes) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.system(size: 11, weight: .regular))
                                .lineLimit(1)
                            
                            Text(note.content.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "无正文")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .listRowBackground(editingNote?.url == note.url ? Color(NSColor.selectedControlColor) : Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if editingNote?.url == note.url { return }
                            autoSaveCurrentWorkIfNeeded()
                            editingNote = note
                            customTitleInput = note.title
                            textInput = note.content
                        }
                        .contextMenu {
                            Button(action: { manager.duplicateNote(note: note) }) { Label("复制", systemImage: "doc.on.doc") }
                            Divider()
                            Button(role: .destructive, action: {
                                manager.deleteNoteFile(at: note.url)
                                if editingNote?.url == note.url {
                                    editingNote = nil
                                    customTitleInput = ""
                                    textInput = ""
                                }
                            }) { Label("删除", systemImage: "trash") }
                        }
                    }
                }
            }
            .padding(.top, 14)
            .frame(minWidth: 125, idealWidth: 145, maxWidth: 180)
            
            // ================= 右侧编辑区域 =================
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                
                TextField("标题...", text: $customTitleInput)
                    .font(.system(size: 15, weight: .regular))
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .focused($focusedField, equals: .title) // 绑定标题焦点
                    .onSubmit {
                        // 🌟 回车直接流转状态机，由 SwiftUI 官方底层驱动焦点无缝下移
                        focusedField = .body
                    }
                
                Color.clear.frame(height: 6)
                
                Divider()
                    .background(Color(NSColor.separatorColor).opacity(0.15))
                
                // 🌟 使用原生适配 `.focused` 饰电器的安全桥接组件
                MacTextEditor(
                    text: $textInput,
                    onCancel: {
                        customTitleInput = ""
                        textInput = ""
                        editingNote = nil
                        onDismiss()
                    }
                )
                .focused($focusedField, equals: .body) // 🌟 挂载原生焦点，让 SwiftUI 明确识别正文边界
                .padding(.vertical, 12)
                .padding(.leading, 12)
                .padding(.trailing, 16)
            }
            .frame(minWidth: 260, idealWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 440, height: 280)
        .background(Color(NSColor.controlBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: .quicknoteTriggerSave)) { _ in
            let trimmed = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
            focusedField = nil
            
            if !trimmed.isEmpty {
                manager.saveNote(title: customTitleInput, content: textInput, overridingNote: editingNote)
            } else if let noteToCleanup = editingNote {
                if noteToCleanup.content != textInput {
                    manager.deleteNoteFile(at: noteToCleanup.url)
                }
            }
            
            customTitleInput = ""
            textInput = ""
            editingNote = nil
            onDismiss()
        }
        .onReceive(NotificationCenter.default.publisher(for: .quicknoteWindowOpened)) { _ in
            if editingNote == nil {
                customTitleInput = ""
                textInput = ""
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focusedField = .body }
        }
        .onAppear {
            manager.loadRecentNotes()
            manager.startWatchingStorageFolder()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focusedField = .body }
        }
        .onDisappear {
            manager.stopWatchingStorageFolder()
        }
    }
}

// MARK: - 自定义具备响应链向下传递能力的原生滚动容器
private class FocusableScrollView: NSScrollView {
    override var acceptsFirstResponder: Bool { true }
    
    override func becomeFirstResponder() -> Bool {
        // 当 SwiftUI 系统要求滚动容器获焦时，直接无缝向下移交给内部真正的 NSTextView
        if let textView = self.documentView as? NSTextView {
            return self.window?.makeFirstResponder(textView) ?? false
        }
        return super.becomeFirstResponder()
    }
}

// MARK: - 彻底杜绝副作用的精简纯净 NSTextView 桥接器
private struct MacTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onCancel: () -> Void
    
    func makeNSView(context: Context) -> FocusableScrollView {
        let scrollView = FocusableScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        
        let textView = NSTextView(frame: .zero)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.drawsBackground = false
        textView.font = .systemFont(ofSize: 14)
        textView.delegate = context.coordinator
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 0, height: 0)
        
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true
        }
        
        scrollView.documentView = textView
        return scrollView
    }
    
    func updateNSView(_ nsView: FocusableScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        // 🌟 纯粹的数据单向同步，没有任何一丁点操控焦点的副作用代码，根治乱跳 Bug
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacTextEditor
        
        init(_ parent: MacTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                self.parent.onCancel()
                return true
            }
            return false
        }
    }
}
