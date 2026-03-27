# Flash 项目进度档案

## 1. 项目简介
- **名称**：Flash
- **目标**：一个使用 Swift 和 SwiftUI 开发的 macOS 窗口管理工具。
- **核心逻辑**：通过 Accessibility API 获取窗口，计算位置并移动。

## 2. 架构说明 (执行顺序)
1. FlashApp.swift (启动)
2. WindowManager.swift (监听并执行)
3. ScreenDetection.swift (获取屏幕参数)
4. WindowCalculationFactory.swift (派发任务)
5. CalculationHub/ (具体的计算逻辑)

## 3. 重点代码逻辑
- 窗口位置计算采用“物理贴边”算法：`visibleFrame.maxX - targetWidth`。
- 解决微信等窗口贴不到边的问题：设置 size 后立即读取实际 size 并反向修正位置。
