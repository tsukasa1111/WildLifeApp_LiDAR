import SwiftUI

struct SessionHeroSection: View {
    let thumbnailImage: CGImage?
    let hasModel: Bool
    let isReconstructing: Bool

    var body: some View {
        ZStack {
            Color(uiColor: .secondarySystemBackground)
            if let thumbnailImage {
                Image(decorative: thumbnailImage, scale: 1)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 190)
        .overlay(alignment: .topTrailing) {
            StatusBadge(hasModel: hasModel, isReconstructing: isReconstructing)
                .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding()
    }
}
