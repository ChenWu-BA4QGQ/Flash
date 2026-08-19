import SwiftUI

struct QuicknoteSidebarView: View {
    @ObservedObject var manager: QuicknoteManager
    @Binding var editingNote: NoteModel?
    @Binding var customTitleInput: String
    @Binding var textInput: String
    var focusedField: FocusState<QuicknoteField?>.Binding
    var autoSaveCurrentWorkIfNeeded: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                newNoteRow
                
                ForEach(manager.recentNotes) { note in
                    noteRow(note)
                }
            }
        }
        .padding(.top, 14)
        .frame(minWidth: 125, idealWidth: 145, maxWidth: 180)
    }
    
    private var newNoteRow: some View {
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
            focusedField.wrappedValue = .body
        }
    }
    
    private func noteRow(_ note: NoteModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.system(size: 11, weight: .regular))
                .lineLimit(1)
            
            Text(notePreview(for: note))
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
    
    private func notePreview(for note: NoteModel) -> String {
        note.content.components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "无正文"
    }
}
