import SwiftUI

struct FlashMenuView: View {
    var body: some View {
        Button("左半屏") {
            FlashServices.windowManager.execute(.leftHalf)
        }
        .keyboardShortcut(.leftArrow, modifiers: [.control, .option])
        
        Button("右半屏") {
            FlashServices.windowManager.execute(.rightHalf)
        }
        .keyboardShortcut(.rightArrow, modifiers: [.control, .option])
        
        Button("全屏") {
            FlashServices.windowManager.execute(.maxisize)
        }
        .keyboardShortcut(.return, modifiers: [.control, .option])
        
        Button("接近全屏") {
            FlashServices.windowManager.execute(.almostMaxisize)
        }
        .keyboardShortcut(.return, modifiers: [.control, .option, .command])
        
        Divider()
        
        Button("截图") {
            FlashServices.screenshotManager.openSystemScreenshotTool()
        }
        .keyboardShortcut("A", modifiers: [.command, .shift])
        
        Button("下载视频") {
            FlashWindowCoordinator.openDownloadWindow()
        }
        
        Button("闪念胶囊") {
            FlashWindowCoordinator.toggleQuicknoteWindow()
        }
        .keyboardShortcut(.space, modifiers: .option)
        
        Divider()
        
        Button("设置...") {
            FlashWindowCoordinator.openSettingsWindow()
        }
        
        Button("退出 Flash") {
            NSApplication.shared.terminate(nil)
        }
    }
}
