import SwiftUI

struct ContentView: View {
    @ObservedObject var noteManager: QuicknoteManager
    
    var body: some View {
        SettingsWindowView(noteManager: noteManager)
    }
}
