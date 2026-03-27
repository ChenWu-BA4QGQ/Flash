import Foundation

class LeftRightHalfCalculation: WindowCalculation {
    func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrame = params.visibleFrameOfScreen
        
        var targetWidth = visibleFrame.width / 2
        let targetHeight = visibleFrame.height
        var targetX = visibleFrame.origin.x
        let targetY = visibleFrame.origin.y
        
        if params.action == .rightHalf {
            targetX += targetWidth
        }
        
        let finalRect = CGRect(x: targetX, y: targetY, width: targetWidth, height: targetHeight)
        return RectResult(finalRect)
    }
}
