import SwiftUI

@main
struct GuidedCaptureSampleApp: App {
    static let subsystem: String = "com.example.apple-samplecode.guided-capture-sample"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AppDataModel.instance)
        }
    }
}
