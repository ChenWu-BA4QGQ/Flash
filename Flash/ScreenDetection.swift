import Cocoa

class ScreenDetection {
    func detectScreen(for windowRect: CGRect) -> UsableScreens? {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return nil }

        var bestScreen = screens[0]
        var maxArea: CGFloat = -1 // 初始值设为负，确保即便只有一点重合也能抓到

        for screen in screens {
            let screenFrame = screen.cgFrame
            let intersection = windowRect.intersection(screenFrame)
            
            if !intersection.isNull {
                let area = intersection.width * intersection.height
                if area > maxArea {
                    maxArea = area
                    bestScreen = screen
                }
            }
        }
        
        return UsableScreens(currentScreen: bestScreen, numScreens: screens.count)
    }
}
