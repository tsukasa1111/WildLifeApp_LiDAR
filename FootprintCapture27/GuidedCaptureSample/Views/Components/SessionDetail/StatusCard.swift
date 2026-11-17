import SwiftUI

struct StatusCard: View {
    let hasModel: Bool
    let isReconstructing: Bool
    let reconstructionProgress: Double
    let reconstructionError: String?

    var body: some View {
        VStack(spacing: 16) {
            // Status header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: statusIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(statusColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(UIColor.label))

                    Text(statusSubtitle)
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.systemGray))
                }

                Spacer()
            }

            // Progress or error
            if isReconstructing {
                VStack(spacing: 12) {
                    ProgressView(value: reconstructionProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .scaleEffect(y: 2)

                    Text("\(Int(reconstructionProgress * 100))% 完了")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(UIColor.systemGray))
                }
            }

            if let error = reconstructionError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)

                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)

                    Spacer()
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var statusColor: Color {
        if isReconstructing { return .orange }
        if hasModel { return .green }
        return .blue
    }

    private var statusIcon: String {
        if isReconstructing { return "gear.circle.fill" }
        if hasModel { return "cube.fill" }
        return "camera.fill"
    }

    private var statusTitle: String {
        if isReconstructing { return "3Dモデル処理中" }
        if hasModel { return "3Dモデル準備完了" }
        return "写真キャプチャ完了"
    }

    private var statusSubtitle: String {
        if isReconstructing { return "3Dモデルを作成中" }
        if hasModel { return "表示・共有可能" }
        return "3Dモデル生成準備完了"
    }
}

