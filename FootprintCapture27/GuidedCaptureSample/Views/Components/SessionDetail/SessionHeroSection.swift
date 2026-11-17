import SwiftUI

struct SessionHeroSection: View {
    let thumbnailImage: CGImage?
    let hasModel: Bool
    let isReconstructing: Bool

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 20) {
                thumbnailSection
            }
            .padding(.vertical, 30)
        }
        .frame(height: 300)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(UIColor.systemBackground),
                Color(UIColor.systemGray6).opacity(0.3)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var thumbnailSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemGray5).opacity(0.8))
                .frame(width: 200, height: 200)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)

            if let thumbnailImage {
                Image(decorative: thumbnailImage, scale: 1.0)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                VStack {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(UIColor.systemGray2))
                    Text("読み込み中...")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.systemGray2))
                }
            }

            VStack {
                HStack {
                    Spacer()
                    StatusBadge(hasModel: hasModel, isReconstructing: isReconstructing)
                }
                Spacer()
            }
            .padding(12)
        }
    }
}

