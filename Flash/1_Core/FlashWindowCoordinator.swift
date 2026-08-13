import AppKit
import SwiftUI

enum FlashWindowCoordinator {
    private enum WindowSize {
        static let download = NSSize(width: 500, height: 220)
        static let quicknote = NSSize(width: 440, height: 280)
        static let settings = NSSize(width: 440, height: 230)
    }
    
    private static var downloadWindowController: NSWindowController?
    private static var quicknoteWindowController: NSWindowController?
    private static var settingsWindowController: NSWindowController?
    
    static func openSettingsWindow() {
        if let controller = settingsWindowController {
            bringToFront(controller)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: WindowSize.settings),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "设置"
        window.center()
        window.contentView = NSHostingView(rootView: SettingsWindowView(noteManager: FlashServices.quicknoteManager))
        
        settingsWindowController = NSWindowController(window: window)
        bringToFront(settingsWindowController)
    }
    
    static func openDownloadWindow() {
        if let controller = downloadWindowController {
            bringToFront(controller)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: WindowSize.download),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Flash 视频下载助手"
        window.contentView = NSHostingView(rootView: DownloadWindowView())
        
        let controller = NSWindowController(window: window)
        downloadWindowController = controller
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            downloadWindowController = nil
        }
        
        bringToFront(controller)
    }
    
    static func toggleQuicknoteWindow() {
        if let controller = quicknoteWindowController, let window = controller.window {
            if window.isVisible {
                NotificationCenter.default.post(name: .quicknoteTriggerSave, object: nil)
            } else {
                showQuicknoteWindow(window)
            }
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: WindowSize.quicknote),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        configureQuicknoteWindow(window)
        
        window.contentView = NSHostingView(rootView: QuicknoteWindowView(
            manager: FlashServices.quicknoteManager,
            onDismiss: {
                quicknoteWindowController?.window?.orderOut(nil)
            }
        ))
        
        quicknoteWindowController = NSWindowController(window: window)
        showQuicknoteWindow(window)
    }
    
    private static func bringToFront(_ controller: NSWindowController?) {
        controller?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private static func configureQuicknoteWindow(_ window: NSWindow) {
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        
        let autoSaveName = "FlashQuicknotePosition"
        window.setFrameAutosaveName(autoSaveName)
        
        if UserDefaults.standard.string(forKey: "NSWindow Frame \(autoSaveName)") == nil {
            window.center()
        }
    }
    
    private static func showQuicknoteWindow(_ window: NSWindow) {
        moveQuicknoteWindowToCurrentScreenIfNeeded(window)
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .quicknoteWindowOpened, object: nil)
    }
    
    private static func moveQuicknoteWindowToCurrentScreenIfNeeded(_ window: NSWindow) {
        guard let screen = screenContainingMouse() ?? NSScreen.main else { return }
        guard !screen.visibleFrame.intersects(window.frame) else { return }
        
        let origin = CGPoint(
            x: screen.visibleFrame.midX - window.frame.width / 2,
            y: screen.visibleFrame.midY - window.frame.height / 2
        )
        window.setFrameOrigin(origin)
    }
    
    private static func screenContainingMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        }
    }
}
