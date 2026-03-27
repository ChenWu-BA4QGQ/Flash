import CoreGraphics

struct AlmostMaximizeConfiguration {
    static let scale: CGFloat = 0.9
}

class AlmostMaximizeCalculation: WindowCalculation {
    func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let screen = params.visibleFrameOfScreen
        let scale = AlmostMaximizeConfiguration.scale
        
        // 使用 insetBy 会让代码看起来非常“高级”且易读
        // 它会自动帮你算好居中的 X 和 Y
        let dx = screen.width * (1 - scale) / 2
        let dy = screen.height * (1 - scale) / 2
        let targetRect = screen.insetBy(dx: dx, dy: dy)
        
        return RectResult(targetRect)
    }
}
