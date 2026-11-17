import SwiftUI

struct StatusBadge: View {
    let hasModel: Bool
    let isReconstructing: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(backgroundColor)
                .frame(width: 100, height: 32)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)

                Text(statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
    }

    private var backgroundColor: Color {
        if isReconstructing { return Color.orange.opacity(0.9) }
        if hasModel { return Color.green.opacity(0.85) }
        return Color.blue.opacity(0.85)
    }

    private var iconName: String {
        if isReconstructing { return "gear" }
        if hasModel { return "cube.fill" }
        return "camera.fill"
    }

    private var statusText: String {
        if isReconstructing { return "処理中" }
        if hasModel { return "3Dモデル" }
        return "写真"
    }
}

