/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for playing the tutorial.
*/

import SwiftUI

struct TutorialVideoView: View {
    @EnvironmentObject var appModel: AppDataModel
    let url: URL
    let isInReviewSheet: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            PlayerView(
                url: url,
                isInverted: false // 白いモヤの原因となるinvertを無効化
            )
            if isInReviewSheet {
                Spacer(minLength: 28)
            }
        }
        .foregroundColor(.white)
    }
}
