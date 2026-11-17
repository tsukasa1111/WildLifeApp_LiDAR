/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Encapsulated View support for the scanning progress meter.
*/

// Should not depend on the data model, but driven from functional state passed into it.

import RealityKit
import SwiftUI

struct ProgressBarView: View {
    @EnvironmentObject var appModel: AppDataModel
    // The progress value from 0 to 1 that describes the amount of coverage completed.
    var progress: Float
    var estimatedRemainingTime: TimeInterval?
    var processingStageDescription: String?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var formattedEstimatedRemainingTime: String? {
        guard let estimatedRemainingTime else { return nil }

        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        return formatter.string(from: estimatedRemainingTime)
    }

    private var numOfImages: Int {
        guard let folderManager = appModel.captureFolderManager else { return 0 }
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: folderManager.imagesFolder,
            includingPropertiesForKeys: nil
        ) else {
            return 0
        }
        return urls.filter { $0.pathExtension.uppercased() == "HEIC" }.count
    }

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    Text(processingStageDescription ?? LocalizedString.processing)

                    Spacer()

                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .bold()
                        .monospacedDigit()
                }
                .font(.body)

                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    .scaleEffect(y: 1.5)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(.thinMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 8)

            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .center) {
                    Image(systemName: "photo")

                    Text(String(numOfImages))
                        .frame(alignment: .bottom)
                        .hidden()
                        .overlay {
                            Text(String(numOfImages))
                                .font(.caption)
                                .bold()
                        }
                }
                .font(.subheadline)
                .padding(.trailing, 16)

                VStack(alignment: .leading) {
                    Text(LocalizedString.processingModelDescription)

                    Text(String.localizedStringWithFormat(LocalizedString.estimatedRemainingTime,
                                                          formattedEstimatedRemainingTime ?? LocalizedString.calculating))
                }
                .font(.subheadline)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.thinMaterial.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }

    private struct LocalizedString {
        static let processing = NSLocalizedString(
            "Processing (Object Capture)",
            bundle: Bundle.main,
            value: "Processing…",
            comment: "Processing title for object reconstruction."
        )

        static let processingModelDescription = NSLocalizedString(
            "Keep app running while processing. (Object Capture)",
            bundle: Bundle.main,
            value: "Keep app running while processing.",
            comment: "Description displayed while processing the models."
        )

        static let estimatedRemainingTime = NSLocalizedString(
            "Estimated time remaining: %@ (Object Capture)",
            bundle: Bundle.main,
            value: "Estimated time remaining: %@",
            comment: "Estimated processing time it takes to reconstruct the object."
        )

        static let calculating = NSLocalizedString(
            "Calculating… (Estimated time, Object Capture)",
            bundle: Bundle.main,
            value: "Calculating…",
            comment: "When estimated processing time isn't available yet."
        )
    }

}
