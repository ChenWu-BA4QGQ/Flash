import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var noteManager: QuicknoteManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            StoragePathSettingsSection(noteManager: noteManager)
            
            Divider()
            
            NamingRuleSettingsSection(noteManager: noteManager)
            
            Spacer()
        }
        .padding(24)
        .frame(width: 440, height: 230)
    }
}
