/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The top-level app view.
*/

import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "ContentView")

/// The root of the SwiftUI View graph.
struct ContentView: View {
    @EnvironmentObject var appModel: AppDataModel

    var body: some View {
        PrimaryView()
            .onAppear(perform: {
                UIApplication.shared.isIdleTimerDisabled = true
            })
            .onDisappear(perform: {
                UIApplication.shared.isIdleTimerDisabled = false
            })
    }
}
