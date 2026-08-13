import Cocoa //010
import MASShortcut //010
 //010
class ScreenshotManager: NSObject { //010
    private let screenshotShortcut = MASShortcut(keyCode: kVK_ANSI_A, modifierFlags: [.command, .shift]) //010
    private let larkBundleIdentifiers = ["com.electron.lark", "com.bytedance.lark"] //010
    private var isScreenshotShortcutRegistered = false //010
    private var isObservingRunningApplications = false //010
 //010
    func start() { //010
        observeRunningApplications() //010
        updateShortcutRegistration() //010
    } //010
 //010
    func openSystemScreenshotTool() { //010
        let screenshotAppURL = URL(fileURLWithPath: "/System/Applications/Utilities/Screenshot.app") //010
        NSWorkspace.shared.openApplication(at: screenshotAppURL, configuration: NSWorkspace.OpenConfiguration()) //010
    } //010
 //010
    private func observeRunningApplications() { //010
        guard !isObservingRunningApplications else { return } //010
 //010
        NSWorkspace.shared.notificationCenter.addObserver( //010
            self, //010
            selector: #selector(runningApplicationsChanged), //010
            name: NSWorkspace.didLaunchApplicationNotification, //010
            object: nil //010
        ) //010
        NSWorkspace.shared.notificationCenter.addObserver( //010
            self, //010
            selector: #selector(runningApplicationsChanged), //010
            name: NSWorkspace.didTerminateApplicationNotification, //010
            object: nil //010
        ) //010
 //010
        isObservingRunningApplications = true //010
    } //010
 //010
    @objc private func runningApplicationsChanged() { //010
        updateShortcutRegistration() //010
    } //010
 //010
    private func updateShortcutRegistration() { //010
        guard let monitor = MASShortcutMonitor.shared() else { return } //010
 //010
        if isLarkRunning { //010
            guard isScreenshotShortcutRegistered else { return } //010
            monitor.unregisterShortcut(screenshotShortcut) //010
            isScreenshotShortcutRegistered = false //010
            return //010
        } //010
 //010
        guard !isScreenshotShortcutRegistered else { return } //010
        if monitor.register(screenshotShortcut, withAction: openSystemScreenshotTool) { //010
            isScreenshotShortcutRegistered = true //010
        } //010
    } //010
 //010
    private var isLarkRunning: Bool { //010
        NSWorkspace.shared.runningApplications.contains { app in //010
            guard let bundleIdentifier = app.bundleIdentifier else { return false } //010
            return larkBundleIdentifiers.contains(bundleIdentifier) //010
        } //010
    } //010
} //010
