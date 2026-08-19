import SwiftUI

enum QuicknoteField: Hashable {
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
            QuicknoteSidebarView(
                manager: manager,
                editingNote: $editingNote,
                customTitleInput: $customTitleInput,
                textInput: $textInput,
                focusedField: $focusedField,
                autoSaveCurrentWorkIfNeeded: autoSaveCurrentWorkIfNeeded
            )
            
            QuicknoteEditorView(
                customTitleInput: $customTitleInput,
                textInput: $textInput,
                editingNote: $editingNote,
                focusedField: $focusedField,
                onDismiss: onDismiss
            )
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
