import Foundation

// 分发中心：根据动作匹配对应的计算类
struct WindowCalculationFactory {
    
    static func getCalculation(for action: WindowAction) -> WindowCalculation {
        switch action {
        case .leftHalf, .rightHalf:
            // 对应 LeftRightHalfCalculation.swift
            return LeftRightHalfCalculation()
            
        case .maximize:
            // 对应你拖入的独立文件 MaximizeCalculation.swift
            return MaximizeCalculation()
            
        case .almostMaximize:
            // 对应你拖入的独立文件 AlmostMaximizeCalculation.swift
            return AlmostMaximizeCalculation()
            
        // 如果有其他未定义的动作，默认返回全屏
        default:
            return MaximizeCalculation()
        }
    }
}
