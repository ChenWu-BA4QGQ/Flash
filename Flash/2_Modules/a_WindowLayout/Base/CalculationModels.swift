import Cocoa

protocol WindowCalculation {
    func calculateRect(_ params: RectCalculationParameters) -> RectResult
}

struct RectResult {
    let rect: CGRect
    init(_ rect: CGRect) { self.rect = rect }
}

struct RectCalculationParameters {
    let window: AXUIElement?
    let visibleFrameOfScreen: CGRect
    let action: WindowAction
}

// --- 核心修复：坐标系翻译官 ---
extension NSScreen {
    // 统一获取主屏幕高度，作为坐标转换的基准
    private static var primaryScreenHeight: CGFloat {
        return NSScreen.screens.first?.frame.height ?? 0
    }

    // 封装一个通用的转换逻辑，减少重复代码
    private func convertToCG(_ cocoaRect: CGRect) -> CGRect {
        var rect = cocoaRect
        // macOS 坐标转换公式：CG_Y = 主屏高度 - Cocoa_MaxY
        rect.origin.y = NSScreen.primaryScreenHeight - cocoaRect.maxY
        return rect
    }

    var cgFrame: CGRect {
        return convertToCG(self.frame)
    }
    
    var cgVisibleFrame: CGRect {
        return convertToCG(self.visibleFrame)
    }
}

struct UsableScreens {
    let currentScreen: NSScreen
    let numScreens: Int
    
    // 强制吐出翻译后的绝对可用区域
    var visibleFrame: CGRect {
        return currentScreen.cgVisibleFrame
    }
}
