import Carbon
import MASShortcut

final class GlobalShortcutRegistrar {
    func registerGlobalShortcuts() {
        let monitor = MASShortcutMonitor.shared()
        monitor?.unregisterAllShortcuts()
        
        let left = MASShortcut(keyCode: kVK_LeftArrow, modifierFlags: [.control, .option])
        monitor?.register(left) {
            FlashServices.windowManager.execute(.leftHalf)
        }
        
        let right = MASShortcut(keyCode: kVK_RightArrow, modifierFlags: [.control, .option])
        monitor?.register(right) {
            FlashServices.windowManager.execute(.rightHalf)
        }
        
        let max = MASShortcut(keyCode: kVK_Return, modifierFlags: [.control, .option])
        monitor?.register(max) {
            FlashServices.windowManager.execute(.maxisize)
        }
        
        let almost = MASShortcut(keyCode: kVK_Return, modifierFlags: [.control, .option, .command])
        monitor?.register(almost) {
            FlashServices.windowManager.execute(.almostMaxisize)
        }
        
        let quicknote = MASShortcut(keyCode: Int(kVK_Space), modifierFlags: [.option])
        monitor?.register(quicknote) {
            FlashWindowCoordinator.toggleQuicknoteWindow()
        }
    }
}
