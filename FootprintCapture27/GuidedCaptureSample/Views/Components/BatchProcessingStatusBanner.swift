import SwiftUI

struct BatchProcessingStatusBanner: View {
    @EnvironmentObject var appModel: AppDataModel

    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            Group {
                switch appModel.batchProcessingStatus {
                case .idle:
                    EmptyView()
                case .processing(_, _, _):
                    ProgressView()
                        .scaleEffect(0.8)
                case .completed(_):
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                case .failed(_):
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }

            // Status Text
            VStack(alignment: .leading, spacing: 2) {
                switch appModel.batchProcessingStatus {
                case .idle:
                    EmptyView()
                case .processing(let current, let total, let currentName):
                    Text("一括処理中... (\(current)/\(total))")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("処理中: \(currentName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                case .completed(let processed):
                    Text("一括処理完了")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("\(processed)個の3Dモデルを生成しました")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .failed(let error):
                    Text("処理エラー")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Cancel button for processing state
            if case .processing(_, _, _) = appModel.batchProcessingStatus {
                Button("停止") { appModel.cancelBatchProcessing() }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundCardColor)
                .stroke(borderColor, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: appModel.batchProcessingStatus)
    }

    private var backgroundCardColor: Color {
        switch appModel.batchProcessingStatus {
        case .idle:
            return Color.clear
        case .processing(_, _, _):
            return Color.blue.opacity(0.1)
        case .completed(_):
            return Color.green.opacity(0.1)
        case .failed(_):
            return Color.red.opacity(0.1)
        }
    }

    private var borderColor: Color {
        switch appModel.batchProcessingStatus {
        case .idle:
            return Color.clear
        case .processing(_, _, _):
            return Color.blue.opacity(0.3)
        case .completed(_):
            return Color.green.opacity(0.3)
        case .failed(_):
            return Color.red.opacity(0.3)
        }
    }
}

