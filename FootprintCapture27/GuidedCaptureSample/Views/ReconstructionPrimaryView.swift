import Foundation
import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "ReconstructionPrimaryView")

struct ReconstructionPrimaryView: View {
    @EnvironmentObject var appModel: AppDataModel
    let outputFile: URL

    @State private var completed = false
    @State private var cancelled = false

    var body: some View {
        if completed && !cancelled {
            ModelView(modelFile: outputFile, endCaptureCallback: { [weak appModel] in
                appModel?.endCapture()
            })
            .onAppear { UIApplication.shared.isIdleTimerDisabled = false }
        } else {
            ReconstructionProgressView(
                outputFile: outputFile,
                completed: $completed,
                cancelled: $cancelled
            )
        }
    }
}

struct ReconstructionProgressView: View {
    @EnvironmentObject var appModel: AppDataModel
    let outputFile: URL
    @Binding var completed: Bool
    @Binding var cancelled: Bool

    @State private var progress: Float = 0
    @State private var estimatedRemainingTime: TimeInterval?
    @State private var processingStageDescription: String?
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var isCancelling = false

    var body: some View {
        VStack(spacing: 0) {
            if !completed && !cancelled && !showingError {
                HStack {
                    Button("キャンセル") {
                        isCancelling = true
                        appModel.photogrammetrySession?.cancel()
                    }
                    .font(.headline)
                    .padding(30)
                    Spacer()
                }
            }

            Spacer()
            Text("3Dモデルを生成中")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            ProgressBarView(
                progress: progress,
                estimatedRemainingTime: estimatedRemainingTime,
                processingStageDescription: processingStageDescription
            )
            .padding(.horizontal, 24)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .alert("3Dモデルを生成できませんでした", isPresented: $showingError) {
            Button("撮影へ戻る") { appModel.state = .restart }
        } message: {
            Text(errorMessage)
        }
        .task {
            guard let session = appModel.photogrammetrySession,
                  let folder = appModel.captureFolderManager else {
                showError("再構成セッションまたはキャプチャフォルダが見つかりません。")
                return
            }

            do {
                // AppDataModel が準備した同じセッションを使う。
                try session.process(requests: [
                    .pointCloud,
                    .modelFile(url: outputFile)
                ])

                for await output in UntilProcessingCompleteFilter(input: session.outputs) {
                    switch output {
                    case .inputComplete:
                        break
                    case .requestProgress(let request, fractionComplete: let fractionComplete):
                        if case .modelFile = request {
                            progress = Float(fractionComplete)
                        }
                    case .requestProgressInfo(let request, let info):
                        if case .modelFile = request {
                            estimatedRemainingTime = info.estimatedRemainingTime
                            processingStageDescription = info.processingStage?.processingStageString
                        }
                    case .requestComplete(let request, let result):
                        if case .pointCloud = request,
                           case .pointCloud(let pointCloud) = result {
                            do {
                                try PointCloudStorage.save(pointCloud, to: folder.pointCloudURL)
                                logger.log("Saved \(pointCloud.points.count) reconstructed points")
                            } catch {
                                showError("点群の保存に失敗しました: \(error.localizedDescription)")
                            }
                        }
                    case .requestError(_, let error):
                        if !isCancelling {
                            showError(error.localizedDescription)
                        }
                    case .processingComplete:
                        if !showingError {
                            guard FileManager.default.fileExists(atPath: outputFile.path) else {
                                showError("3Dモデルの出力ファイルが見つかりません。")
                                break
                            }
                            completed = true
                            appModel.state = .viewing
                        }
                    case .processingCancelled:
                        cancelled = true
                        appModel.state = .restart
                    case .invalidSample(id: _, reason: _), .skippedSample(id: _),
                         .automaticDownsampling, .stitchingIncomplete:
                        break
                    @unknown default:
                        logger.warning("Unknown photogrammetry output")
                    }
                }
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    private func showError(_ message: String) {
        logger.error("Reconstruction failed: \(message)")
        errorMessage = message
        showingError = true
    }
}

// A single PLY preserves the points returned by PhotogrammetrySession.
// Write in chunks so large captures do not require another full copy in memory.
enum PointCloudStorage {
    static func save(_ pointCloud: PhotogrammetrySession.PointCloud, to url: URL) throws {
        let temporaryURL = url.deletingLastPathComponent()
            .appendingPathComponent(".\(UUID().uuidString).ply")
        let header = """
        ply
        format ascii 1.0
        comment PhotogrammetrySession point cloud
        element vertex \(pointCloud.points.count)
        property float x
        property float y
        property float z
        property uchar red
        property uchar green
        property uchar blue
        property uchar alpha
        end_header

        """

        try Data().write(to: temporaryURL)
        let handle = try FileHandle(forWritingTo: temporaryURL)
        do {
            try handle.write(contentsOf: Data(header.utf8))
            var buffer = Data()
            buffer.reserveCapacity(1_048_576)
            for point in pointCloud.points {
                let position = point.position
                let color = point.color ?? SIMD4<UInt8>(255, 255, 255, 255)
                let line = String(
                    format: "%.6f %.6f %.6f %d %d %d %d\n",
                    Double(position.x), Double(position.y), Double(position.z),
                    Int(color.x), Int(color.y), Int(color.z), Int(color.w)
                )
                buffer.append(contentsOf: line.utf8)
                if buffer.count >= 1_048_576 {
                    try handle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                }
            }
            if !buffer.isEmpty {
                try handle.write(contentsOf: buffer)
            }
            try handle.close()

            if FileManager.default.fileExists(atPath: url.path) {
                _ = try FileManager.default.replaceItemAt(url, withItemAt: temporaryURL)
            } else {
                try FileManager.default.moveItem(at: temporaryURL, to: url)
            }
        } catch {
            try? handle.close()
            try? FileManager.default.removeItem(at: temporaryURL)
            throw error
        }
    }
}

extension PhotogrammetrySession.Output.ProcessingStage {
    var processingStageString: String? {
        switch self {
        case .preProcessing: return "前処理中…"
        case .imageAlignment: return "画像を整列中…"
        case .pointCloudGeneration: return "点群を生成中…"
        case .meshGeneration: return "メッシュを生成中…"
        case .textureMapping: return "テクスチャをマッピング中…"
        case .optimization: return "最適化中…"
        default: return nil
        }
    }
}
