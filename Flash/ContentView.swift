import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bolt.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.yellow)
            
            Text("Flash 窗口助手")
                .font(.headline)
            
            Text("当前版本: 1.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("提示：请确保在系统设置中开启了辅助功能权限。")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(width: 300, height: 250)
    }
}
