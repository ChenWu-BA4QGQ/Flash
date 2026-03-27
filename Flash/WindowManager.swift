import Cocoa
import ApplicationServices

class WindowManager: ObservableObject {
    private let screenDetection = ScreenDetection()
    
    func execute(_ action: WindowAction) {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else { return }
        
        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        var window: AnyObject?
        
        let focusedWindowAttr = "AXFocusedWindow" as CFString
        guard AXUIElementCopyAttributeValue(appElement, focusedWindowAttr, &window) == .success else {
            NSSound.beep()
            return
        }
        
        let windowElement = window as! AXUIElement
        
        var rect: CGRect = .zero
        let frameAttr = "AXFrame" as CFString
        var frameValue: AnyObject?
        
        if AXUIElementCopyAttributeValue(windowElement, frameAttr, &frameValue) == .success {
            AXValueGetValue(frameValue as! AXValue, .cgRect, &rect)
        } else {
            return
        }
        
        guard let usableScreens = screenDetection.detectScreen(for: rect) else { return }
        
        let parameters = RectCalculationParameters(
            window: windowElement,
            visibleFrameOfScreen: usableScreens.visibleFrame,
            action: action
        )
        
        let calculation = WindowCalculationFactory.getCalculation(for: action)
        let result = calculation.calculateRect(parameters)
        
        apply(element: windowElement, rect: result.rect)
    }
    
    private func apply(element: AXUIElement, rect: CGRect) {
        var origin = rect.origin
        var size = rect.size
        
        let positionValue = AXValueCreate(.cgPoint, &origin)
        let sizeValue = AXValueCreate(.cgSize, &size)
        
        if let pos = positionValue, let sz = sizeValue {
            AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sz)
            AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, pos)
        }
        
        var actualValue: AnyObject?
        if AXUIElementCopyAttributeValue(element, "AXFrame" as CFString, &actualValue) == .success {
            var actualRect = CGRect.zero
            AXValueGetValue(actualValue as! AXValue, .cgRect, &actualRect)
            
            if actualRect.size.width != size.width || actualRect.size.height != size.height {
                if let sz = sizeValue {
                    AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sz)
                }
            }
        }
    }
}
