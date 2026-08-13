import CoreGraphics

struct AlmostMaxsizeConfiguration {
    static let scale: CGFloat = 0.9
}

class AlmostMaxsizeCalculation: WindowCalculation {
    func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let screen = params.visibleFrameOfScreen
        let scale = AlmostMaxsizeConfiguration.scale
        
        // 它会自动帮你算好居中的 X 和 Y
        let dx = screen.width * (1 - scale) / 2
        let dy = screen.height * (1 - scale) / 2
        let targetRect = screen.insetBy(dx: dx, dy: dy)
        
        return RectResult(targetRect)
    }
}
