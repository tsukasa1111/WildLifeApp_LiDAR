/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The single entry point of the app.
*/

import SwiftUI

@main
struct GuidedCaptureSampleApp: App {
    static let subsystem: String = "com.example.apple-samplecode.guided-capture-sample"
    @StateObject private var appModel = AppDataModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
                .onAppear {
                    // アプリ起動時に縦画面固定を強制
                    forcePortraitOrientation()
                }
        }
    }
    
    private func forcePortraitOrientation() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        // 縦画面固定を強制
        let orientationUpdate = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
        windowScene.requestGeometryUpdate(orientationUpdate) { error in
            if error != nil {
                print("Failed to force portrait orientation: \(error)")
            }
        }
        
        // 追加の縦画面固定処理
        DispatchQueue.main.async {
            if let window = windowScene.windows.first {
                window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        }
    }
}
