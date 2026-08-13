import Foundation

// 分发中心：根据动作匹配对应的计算类
struct WindowCalculationFactory {
    
    static func getCalculation(for action: WindowAction) -> WindowCalculation {
        switch action {
        case .leftHalf, .rightHalf:
            // 对应 LeftRightHalfCalculation.swift
            return LeftRightHalfCalculation()
            
        case .maxisize:
            return MaxsizeCalculation()
            
        case .almostMaxisize:
            return AlmostMaxsizeCalculation()
        }
    }
}
