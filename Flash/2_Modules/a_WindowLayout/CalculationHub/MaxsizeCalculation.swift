import Foundation

class MaxsizeCalculation: WindowCalculation {

    func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen
        return RectResult(visibleFrameOfScreen)
    }
}
