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
        
        guard let windowElement = axUIElement(from: window) else {
            NSSound.beep()
            return
        }
        
        var rect: CGRect = .zero
        let frameAttr = "AXFrame" as CFString
        var frameValue: AnyObject?
        
        guard AXUIElementCopyAttributeValue(windowElement, frameAttr, &frameValue) == .success,
              let axFrameValue = axValue(from: frameValue) else {
            NSSound.beep()
            return
        }
        AXValueGetValue(axFrameValue, .cgRect, &rect)
        
        guard let usableScreens = screenDetection.detectScreen(for: rect) else { return }
        
        let parameters = RectCalculationParameters(
            window: windowElement,
            visibleFrameOfScreen: usableScreens.visibleFrame,
            action: action
        )
        
        let calculation = WindowCalculationFactory.getCalculation(for: action)
        let result = calculation.calculateRect(parameters)
        
        // 调用具备隐形保底和双阶段防溢出裁剪的 apply 方法
        apply(element: windowElement, rect: result.rect, visibleFrame: usableScreens.visibleFrame)
    }
    
    private func apply(element: AXUIElement, rect: CGRect, visibleFrame: CGRect) {
        
        // 🌟【隐形幕布 - 开启】
        // 核心机制：调用系统全局函数暂时冻结屏幕渲染。
        // 在这行代码之后发生的所有窗口尺寸变化、坐标位移，都只在内存中静默计算，绝对不会实时绘制到屏幕上。
        NSDisableScreenUpdates()
        
        // 🌟【隐形幕布 - 自动复原保底机制】
        // Swift 的 defer 特性：无论后面的代码是正常结束、还是在中途提前退出，
        // 最终在 apply 函数彻底走完的那一刹那，一定会执行 defer 块内部的代码，确保幕布必定被拉开。
        defer {
            // 🌟【隐形幕布 - 关闭并一次性渲染】
            // 恢复屏幕更新。此时，系统会把在内存里已经二次修正、裁剪完美的“最终版窗口状态”
            // 瞬间一次性绘制在屏幕上。肉眼完全看不到中间“先超出、后拉回”的位移过程，达到绝不闪烁的丝滑效果。
            NSEnableScreenUpdates()
        }
        
        // 第一阶段：先设定目标位置，再设定目标尺寸（在隐形状态下静默执行）
        setPosition(element: element, origin: rect.origin)
        setSize(element: element, size: rect.size)
        
        // 第二阶段：立即反查系统最终真实允许的 Frame 尺寸（在隐形状态下静默反查）
        guard let actualRect = readFrame(element: element) else { return }
        
        var finalOrigin = rect.origin
        var needReapplyPosition = false
        
        // 1. 横向溢出修正：解决右半屏超出屏幕 Bug
        if actualRect.width > rect.width {
            let isTargetingRightEdge = (rect.maxX >= visibleFrame.maxX - 5)
            if isTargetingRightEdge {
                // 强制往左推，确保右边绝不超出屏幕
                finalOrigin.x = visibleFrame.maxX - actualRect.width
                needReapplyPosition = true
            }
        }
        
        // 2. 纵向拉伸修正：解决接近全屏切回分屏时，窗口下方没到位的 Bug
        if actualRect.height != rect.height {
            let isTargetingBottomEdge = (rect.maxY >= visibleFrame.maxY - 5)
            if isTargetingBottomEdge {
                // 强制重新校准 Y 坐标，强行把窗口底部拉回对齐线
                finalOrigin.y = visibleFrame.maxY - actualRect.height
                needReapplyPosition = true
            }
        }
        
        // 3. 如果触发了上述任意一种边界溢出或未到位限制，重新修正一次绝对坐标（依旧在隐形状态下完成）
        if needReapplyPosition {
            setPosition(element: element, origin: finalOrigin)
        }
    }
    
    private func setPosition(element: AXUIElement, origin: CGPoint) {
        var origin = origin
        if let positionValue = AXValueCreate(.cgPoint, &origin) {
            AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, positionValue)
        }
    }
    
    private func setSize(element: AXUIElement, size: CGSize) {
        var size = size
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue)
        }
    }
    
    private func readFrame(element: AXUIElement) -> CGRect? {
        var actualValue: AnyObject?
        guard AXUIElementCopyAttributeValue(element, "AXFrame" as CFString, &actualValue) == .success,
              let axFrameValue = axValue(from: actualValue) else {
            return nil
        }
        var actualRect = CGRect.zero
        AXValueGetValue(axFrameValue, .cgRect, &actualRect)
        return actualRect
    }
    
    private func axUIElement(from value: AnyObject?) -> AXUIElement? {
        guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return unsafeBitCast(value, to: AXUIElement.self)
    }
    
    private func axValue(from value: AnyObject?) -> AXValue? {
        guard let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        return unsafeBitCast(value, to: AXValue.self)
    }
}
