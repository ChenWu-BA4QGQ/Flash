import SwiftUI

struct QuicknoteEditorView: View {
    @Binding var customTitleInput: String
    @Binding var textInput: String
    @Binding var editingNote: NoteModel?
    var focusedField: FocusState<QuicknoteField?>.Binding
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 0)
            
            TextField("标题...", text: $customTitleInput)
                .font(.system(size: 15, weight: .regular))
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .background(Color(NSColor.controlBackgroundColor))
                .focused(focusedField, equals: .title)
                .onSubmit {
                    focusedField.wrappedValue = .body
                }
            
            Color.clear.frame(height: 6)
            
            Divider()
                .background(Color(NSColor.separatorColor).opacity(0.15))
            
            MacTextEditor(
                text: $textInput,
                onCancel: {
                    customTitleInput = ""
                    textInput = ""
                    editingNote = nil
                    onDismiss()
                }
            )
            .focused(focusedField, equals: .body)
            .padding(.vertical, 12)
            .padding(.leading, 12)
            .padding(.trailing, 16)
        }
        .frame(minWidth: 260, idealWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
