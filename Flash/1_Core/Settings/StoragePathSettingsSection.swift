import SwiftUI

struct StoragePathSettingsSection: View {
    @ObservedObject var noteManager: QuicknoteManager
    
    private let titleFont = Font.system(size: 13, weight: .medium)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("文件存储位置")
                .font(titleFont)
                .foregroundColor(Color(NSColor.labelColor))
            
            HStack(spacing: 8) {
                Text(noteManager.storagePath)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(NSColor.separatorColor), lineWidth: 0.5))
                
                Button("选择...") {
                    chooseStorageFolder()
                }
            }
        }
    }
    
    private func chooseStorageFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "选择目录"
        
        if panel.runModal() == .OK, let url = panel.url {
            noteManager.storagePath = url.path
        }
    }
}
