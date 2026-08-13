import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private let shortcutRegistrar = GlobalShortcutRegistrar()
    private let accessibilityRequester = AccessibilityPermissionRequester()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        accessibilityRequester.requestAccessibility()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shortcutRegistrar.registerGlobalShortcuts()
            FlashServices.screenshotManager.start()
        }
    }
}
