import Foundation

class MaximizeCalculation: WindowCalculation {

    func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen
        return RectResult(visibleFrameOfScreen)
    }
}
