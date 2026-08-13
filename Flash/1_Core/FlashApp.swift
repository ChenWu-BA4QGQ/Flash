import SwiftUI

@main
struct FlashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Flash", systemImage: "bolt.fill") {
            FlashMenuView()
        }
    }
}
