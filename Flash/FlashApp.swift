import SwiftUI
import ApplicationServices
import MASShortcut

@main
struct FlashApp: App {
    static let windowManager = WindowManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Flash", systemImage: "bolt.fill") {
            Button("左半屏") { FlashApp.execute(.leftHalf) }
            Button("右半屏") { FlashApp.execute(.rightHalf) }
            Divider()
            Button("全屏") { FlashApp.execute(.maximize) }
            Button("接近全屏") { FlashApp.execute(.almostMaximize) }
            Divider()
            SettingsLink { Text("设置...") }
            Button("退出 Flash") { NSApplication.shared.terminate(nil) }
        }
        Settings { ContentView() }
    }

    static func execute(_ action: WindowAction) {
        windowManager.execute(action)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        requestAccessibility()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.registerGlobalShortcuts()
        }
    }
    
    private func registerGlobalShortcuts() {
        let monitor = MASShortcutMonitor.shared()
        monitor?.unregisterAllShortcuts()
        
        let left = MASShortcut(keyCode: kVK_LeftArrow, modifierFlags: [.control, .option])
        monitor?.register(left) { FlashApp.execute(.leftHalf) }
        
        let right = MASShortcut(keyCode: kVK_RightArrow, modifierFlags: [.control, .option])
        monitor?.register(right) { FlashApp.execute(.rightHalf) }
        
        let max = MASShortcut(keyCode: kVK_Return, modifierFlags: [.control, .option])
        monitor?.register(max) { FlashApp.execute(.maximize) }
        
        let almost = MASShortcut(keyCode: kVK_Return, modifierFlags: [.control, .option, .command])
        monitor?.register(almost) { FlashApp.execute(.almostMaximize) }
    }
    
    private func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
