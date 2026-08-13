import SwiftUI

struct NamingRuleSettingsSection: View {
    @ObservedObject var noteManager: QuicknoteManager
    
    private let titleFont = Font.system(size: 13, weight: .medium)
    private let contentFont = Font.system(size: 13, weight: .regular)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Markdown 文件命名规则")
                .font(titleFont)
                .foregroundColor(Color(NSColor.labelColor))
            
            Picker("", selection: $noteManager.namingMode) {
                Text("前缀 ＋ 序号").tag(0)
                Text("序号 ＋ 后缀").tag(1)
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
            .font(contentFont)
            
            HStack(spacing: 12) {
                Text(noteManager.namingMode == 0 ? "前缀文本:" : "后缀文本:")
                    .font(contentFont)
                    .foregroundColor(Color(NSColor.labelColor))
                
                TextField("", text: $noteManager.customText)
                    .textFieldStyle(.roundedBorder)
                    .font(contentFont)
                    .frame(width: 180)
            }
        }
    }
}
