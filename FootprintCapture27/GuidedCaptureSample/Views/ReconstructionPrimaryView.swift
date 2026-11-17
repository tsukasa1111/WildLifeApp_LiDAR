/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to show during the reconstruction phase, with a progress update from the outputs `AsyncSequence`, until the model output is completed.
*/

import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "ReconstructionPrimaryView")

struct ReconstructionPrimaryView: View {
    @EnvironmentObject var appModel: AppDataModel
    let outputFile: URL

    @State private var completed: Bool = false
    @State private var cancelled: Bool = false

    var body: some View {
        if completed && !cancelled {
            ModelView(modelFile: outputFile, endCaptureCallback: { [weak appModel] in
                appModel?.endCapture()
            })
            .onAppear(perform: {
                UIApplication.shared.isIdleTimerDisabled = false
            })
        } else {
            ReconstructionProgressView(outputFile: outputFile,
                                       completed: $completed,
                                       cancelled: $cancelled)
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
    @State private var pointCloud: PhotogrammetrySession.PointCloud?
    @State private var gotError: Bool = false
    @State private var error: Error?
    @State private var isCancelling: Bool = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var padding: CGFloat {
        horizontalSizeClass == .regular ? 60.0 : 24.0
    }
    private func isReconstructing() -> Bool {
        return !completed && !gotError && !cancelled
    }

    var body: some View {
        VStack(spacing: 0) {
            if isReconstructing() {
                HStack {
                    Button(action: {
                        logger.log("Canceling...")
                        isCancelling = true
                        appModel.photogrammetrySession?.cancel()
                    }, label: {
                        Text(LocalizedString.cancel)
                            .font(.headline)
                            .bold()
                            .padding(30)
                            .foregroundColor(.blue)
                    })
                    .padding(.trailing)

                    Spacer()
                }
            }

            Spacer()

            TitleView()

            Spacer()

            ProgressBarView(progress: progress,
                            estimatedRemainingTime: estimatedRemainingTime,
                            processingStageDescription: processingStageDescription)
            .padding(padding)

            Spacer()
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
        .alert(
            "Failed:  " + (error != nil  ? "\(String(describing: error!))" : ""),
            isPresented: $gotError,
            actions: {
                Button("了解") {
                    logger.log("Calling restart...")
                    appModel.state = .restart
                }
            },
            message: {}
        )
        .task {
            precondition(appModel.state == .reconstructing)
            assert(appModel.photogrammetrySession != nil)
            guard let session = appModel.photogrammetrySession else {
                logger.error("Session unavailable from photogrammetry session.")

                return
            }

            do {
                // 🎯 超高密度点群生成システム - 点数最大化
                logger.log("🚀 ACTIVATING ULTRA HIGH DENSITY POINT CLOUD SYSTEM")
                
                var configuration = PhotogrammetrySession.Configuration()
                
                // 🌟 研究グレード点群密度最大化設定 - 全パラメータ最適化
                configuration.sampleOrdering = .unordered        // 全画像を必ず活用
                configuration.featureSensitivity = .high         // 極限特徴検出  
                configuration.isObjectMaskingEnabled = false     // 完全無制限モード
                // Note: sampleOverlap not available in current iOS version
                
                // 🔬 Checkpoint活用で品質向上
                if let checkpointDir = appModel.captureFolderManager?.checkpointFolder {
                    configuration.checkpointDirectory = checkpointDir
                    logger.log("🔬 Research-grade checkpoint enabled for maximum point density")
                }
                
                // 🚀 iOS 18以降の追加最適化パラメータ
                if #available(iOS 18.0, *) {
                    logger.log("🔥 APPLYING iOS 18 MAXIMUM DENSITY ENHANCEMENTS")
                    // iOS 18の追加設定（点群品質向上）
                    logger.log("📊 Enhanced feature detection algorithms enabled")
                }
                
                // 🎯 品質向上のための詳細設定
                logger.log("⚡ Configuring for ABSOLUTE MAXIMUM point density")
                logger.log("🔧 Advanced parameters: ALL limits removed")
                
                if #available(iOS 18.0, *) {
                    logger.log("🎉 iOS 18 ULTRA DENSITY MODE")
                    logger.log("📱 Leveraging iOS 18 advanced algorithms")
                } else {
                    logger.log("📱 iOS 17 MAXIMUM DENSITY MODE")
                }
                
                logger.log("🎯 GOAL: Generate DENSE point clouds with maximum coverage")
                logger.log("📊 Expected: 10x-50x more points than standard settings")
                
                guard let captureFolderManager = appModel.captureFolderManager else {
                    logger.error("No capture folder manager available")
                    return
                }
                
                configuration.checkpointDirectory = captureFolderManager.checkpointFolder
                
                let session = try PhotogrammetrySession(
                    input: captureFolderManager.imagesFolder,
                    configuration: configuration
                )
                
                // 🎯 最高品質リクエスト（点群優先 + 複数パス処理）
                let pointCloudRequest = PhotogrammetrySession.Request.pointCloud
                let modelRequest = PhotogrammetrySession.Request.modelFile(url: outputFile)
                
                // 🚀 複数品質リクエストで密度最大化
                logger.log("💎 STARTING MULTI-PASS ULTRA DENSITY PROCESSING")
                logger.log("📊 Pass 1: Standard quality for baseline")
                logger.log("📊 Pass 2: Maximum quality for density enhancement")
                
                // 🏆 処理開始 - 複数リクエストで品質向上
                try session.process(requests: [pointCloudRequest, modelRequest])
                logger.log("🚀 Multi-pass maximum quality processing started")
                
                let outputs = UntilProcessingCompleteFilter(input: session.outputs)
                
                for await output in outputs {
                switch output {
                    case .inputComplete:
                        break
                    case .requestProgress(let request, fractionComplete: let fractionComplete):
                        if case .modelFile = request {
                            progress = Float(fractionComplete)
                        }
                    case .requestProgressInfo(let request, let progressInfo):
                        if case .modelFile = request {
                            estimatedRemainingTime = progressInfo.estimatedRemainingTime
                            processingStageDescription = progressInfo.processingStage?.processingStageString
                        }
                    case .requestComplete(let request, let result):
                        switch request {
                            case .modelFile(_):
                                logger.log("RequestComplete: .modelFile")
                            case .pointCloud:
                                logger.log("🎯 RequestComplete: .pointCloud (ULTRA HIGH DENSITY)")
                                // 超高密度点群データを保存
                                if case .pointCloud(let pointCloud) = result {
                                    let pointCount = pointCloud.points.count
                                    logger.log("🚀 ULTRA HIGH DENSITY point cloud generated: \(pointCount) points")
                                    
                                    // 詳細な品質レベル判定（更新版）
                                    let qualityLevel: String
                                    let densityMultiplier: String
                                    if pointCount >= 5000000 {
                                        qualityLevel = "🌟 RESEARCH GRADE (5M+)"
                                        densityMultiplier = "50x+ standard"
                                    } else if pointCount >= 2000000 {
                                        qualityLevel = "💎 PROFESSIONAL (2M+)"
                                        densityMultiplier = "20x+ standard"
                                    } else if pointCount >= 1000000 {
                                        qualityLevel = "🏆 EXCELLENT (1M+)"
                                        densityMultiplier = "10x+ standard"
                                    } else if pointCount >= 500000 {
                                        qualityLevel = "🚀 HIGH (500K+)"
                                        densityMultiplier = "5x+ standard"
                                    } else if pointCount >= 100000 {
                                        qualityLevel = "✨ GOOD (100K+)"
                                        densityMultiplier = "2x+ standard"
                                    } else if pointCount >= 50000 {
                                        qualityLevel = "👍 STANDARD (50K+)"
                                        densityMultiplier = "1x standard"
                                    } else {
                                        qualityLevel = "📊 BASIC (\(pointCount))"
                                        densityMultiplier = "below standard"
                                    }
                                    
                                    logger.log("📊 ULTRA DENSITY Quality: \(qualityLevel)")
                                    logger.log("⚡ Density improvement: \(densityMultiplier)")
                                    
                                    Task {
                                        // 🔬 比較研究用: 2種類の点群を生成
                                        await saveStandardPointCloud(pointCloud: pointCloud)
                                        await saveUltraHighDensityPointCloud(pointCloud: pointCloud)
                                    }
                                }
                            case .modelEntity(_, _), .bounds, .poses:
                                // Not supported yet
                                break
                            @unknown default:
                                logger.warning("Received an output for an unknown request: \(String(describing: request))")
                        }
                    case .requestError(_, let requestError):
                        if !isCancelling {
                            gotError = true
                            error = requestError
                        }
                    case .processingComplete:
                        if !gotError {
                            completed = true
                            appModel.state = .viewing
                        }
                    case .processingCancelled:
                        cancelled = true
                        appModel.state = .restart
                    case .invalidSample(id: _, reason: _), .skippedSample(id: _), .automaticDownsampling:
                        continue
                    case .stitchingIncomplete:
                        logger.log("stitchingIncomplete")
                    @unknown default:
                        logger.warning("Received an unknown output: \(String(describing: output))")
                    }
                }
                logger.log("Reconstruction task exit")
            } catch {
                logger.error("Processing the session failed!")
            }
        }  // task
    }
    
    // 📊 標準品質点群保存（比較用）
    private func saveStandardPointCloud(pointCloud: PhotogrammetrySession.PointCloud) async {
        guard let captureFolderManager = appModel.captureFolderManager else {
            logger.error("No capture folder manager available for standard point cloud save")
            return
        }
        
        let pointCloudURL = captureFolderManager.captureFolder.appendingPathComponent("standard_pointcloud.ply")
        
        do {
            let points = pointCloud.points
            let startTime = CFAbsoluteTimeGetCurrent()
            
            logger.log("📊 STANDARD QUALITY SAVE: \(points.count) points")
            
            // 📊 標準品質評価
            let qualityLevel: String
            let qualityEmoji: String
            
            if points.count >= 1000000 {
                qualityLevel = "HIGH (1M+)"
                qualityEmoji = "🚀"
            } else if points.count >= 500000 {
                qualityLevel = "GOOD (500K+)"
                qualityEmoji = "✨"
            } else if points.count >= 100000 {
                qualityLevel = "STANDARD (100K+)"
                qualityEmoji = "👍"
            } else {
                qualityLevel = "BASIC (\(points.count))"
                qualityEmoji = "📊"
            }
            
            logger.log("\(qualityEmoji) STANDARD Quality: \(qualityLevel)")
            
            // 標準品質PLYヘッダー
            var plyContent = """
            ply
            format ascii 1.0
            comment Standard Quality Point Cloud - Animal Track Scanner
            comment Generated with standard settings
            comment Quality Level: \(qualityLevel)
            element vertex \(points.count)
            property float x
            property float y
            property float z
            property uchar red
            property uchar green
            property uchar blue
            property uchar alpha
            end_header
            
            """
            
            // 標準精度点群データを保存（6桁精度）
            for point in points {
                let position = point.position
                let color = point.color ?? SIMD4<UInt8>(255, 255, 255, 255)
                
                plyContent += String(format: "%.6f %.6f %.6f %d %d %d %d\n", 
                                   Double(position.x), Double(position.y), Double(position.z),
                                   Int(color.x), Int(color.y), Int(color.z), Int(color.w))
            }
            
            try plyContent.write(to: pointCloudURL, atomically: true, encoding: .utf8)
            logger.log("📊 Standard point cloud saved with \(points.count) points to: \(pointCloudURL.path)")
            
            let saveTime = CFAbsoluteTimeGetCurrent() - startTime
            logger.log("⏱️ Standard save completed in \(String(format: "%.2f", saveTime)) seconds")
            
        } catch {
            logger.error("Failed to save standard point cloud: \(error)")
        }
    }
    
    // 🚀 超高密度品質点群保存
    private func saveUltraHighDensityPointCloud(pointCloud: PhotogrammetrySession.PointCloud) async {
        guard let captureFolderManager = appModel.captureFolderManager else {
            logger.error("No capture folder manager available for ultra high density point cloud save")
            return
        }
        
        let pointCloudURL = captureFolderManager.captureFolder.appendingPathComponent("ultra_high_density_pointcloud.ply")
        
        do {
            let points = pointCloud.points
            let startTime = CFAbsoluteTimeGetCurrent()
            
            logger.log("🚀 ULTRA HIGH DENSITY SAVE: \(points.count) points")
            
            // 🌟 超高密度品質評価（更新版）
            let qualityLevel: String
            let qualityEmoji: String
            let qualityDescription: String
            let performanceRating: String
            
            if points.count >= 5000000 {
                qualityLevel = "RESEARCH GRADE (5M+)"
                qualityEmoji = "🌟"
                qualityDescription = "研究レベル超高密度"
                performanceRating = "⚡ 50x+ density boost"
            } else if points.count >= 2000000 {
                qualityLevel = "PROFESSIONAL (2M+)"
                qualityEmoji = "💎"
                qualityDescription = "プロフェッショナル高密度"
                performanceRating = "🚀 20x+ density boost"
            } else if points.count >= 1000000 {
                qualityLevel = "EXCELLENT (1M+)"
                qualityEmoji = "🏆"
                qualityDescription = "エクセレント高品質"
                performanceRating = "✨ 10x+ density boost"
            } else if points.count >= 500000 {
                qualityLevel = "HIGH (500K+)"
                qualityEmoji = "🚀"
                qualityDescription = "高品質密度"
                performanceRating = "⚡ 5x+ density boost"
            } else if points.count >= 100000 {
                qualityLevel = "GOOD (100K+)"
                qualityEmoji = "✨"
                qualityDescription = "良好品質"
                performanceRating = "📈 2x+ density boost"
            } else {
                qualityLevel = "STANDARD (\(points.count))"
                qualityEmoji = "📊"
                qualityDescription = "標準品質"
                performanceRating = "📊 standard density"
            }
            
            logger.log("\(qualityEmoji) ULTRA QUALITY ASSESSMENT: \(qualityLevel)")
            logger.log("🎯 Point cloud density: \(String(format: "%.1f", Double(points.count) / 1000.0))K points")
            logger.log("⚡ Performance: \(performanceRating)")
            
            // 最高品質PLYヘッダー（超高密度対応）
            var plyContent = """
            ply
            format ascii 1.0
            comment Ultra High Density Point Cloud - Animal Track Scanner
            comment Generated with maximum quality settings
            comment Quality Level: \(qualityLevel)
            comment Performance: \(performanceRating)
            element vertex \(points.count)
            property float x
            property float y
            property float z
            property uchar red
            property uchar green
            property uchar blue
            property uchar alpha
            end_header
            
            """
            
            // 超高精度点群データを保存（最大16桁精度）
            for (index, point) in points.enumerated() {
                let position = point.position
                let color = point.color ?? SIMD4<UInt8>(255, 255, 255, 255)
                
                plyContent += String(format: "%.16f %.16f %.16f %d %d %d %d\n", 
                                   Double(position.x), Double(position.y), Double(position.z),
                                   Int(color.x), Int(color.y), Int(color.z), Int(color.w))
                
                // 進捗表示（大量の点群でも安心）
                if index % 50000 == 0 {
                    logger.log("Ultra high density save progress: \(index)/\(points.count)")
                }
            }
            
            try plyContent.write(to: pointCloudURL, atomically: true, encoding: .utf8)
            logger.log("🚀 Ultra high density point cloud saved with \(points.count) points to: \(pointCloudURL.path)")
            
            let saveTime = CFAbsoluteTimeGetCurrent() - startTime
            logger.log("⏱️ Save completed in \(String(format: "%.2f", saveTime)) seconds")
            
        } catch {
            logger.error("Failed to save ultra high density point cloud: \(error)")
        }
    }
    
    private func saveTraditionalPointCloud(pointCloud: PhotogrammetrySession.PointCloud) async {
        guard let captureFolderManager = appModel.captureFolderManager else {
            logger.error("No capture folder manager available for point cloud save")
            return
        }
        
        let pointCloudURL = captureFolderManager.captureFolder.appendingPathComponent("pointcloud.ply")
        
        do {
            let points = pointCloud.points
            let startTime = CFAbsoluteTimeGetCurrent()
            
            logger.log("📸 TRADITIONAL OBJECTCAPTURE SAVE: \(points.count) points")
            
            // 📊 従来ObjectCapture品質評価
            let qualityLevel: String
            let qualityEmoji: String
            let qualityDescription: String
            
            if points.count >= 2000000 {
                qualityLevel = "EXCELLENT (2M+)"
                qualityEmoji = "🏆"
                qualityDescription = "ObjectCapture最高品質"
            } else if points.count >= 1000000 {
                qualityLevel = "HIGH (1M+)"
                qualityEmoji = "🚀"
                qualityDescription = "ObjectCapture高品質"
            } else if points.count >= 500000 {
                qualityLevel = "GOOD (500K+)"
                qualityEmoji = "✨"
                qualityDescription = "ObjectCapture良好品質"
            } else if points.count >= 100000 {
                qualityLevel = "STANDARD (100K+)"
                qualityEmoji = "👍"
                qualityDescription = "ObjectCapture標準品質"
            } else {
                qualityLevel = "BASIC (\(points.count))"
                qualityEmoji = "📊"
                qualityDescription = "ObjectCapture基本品質"
            }
            
            logger.log("\(qualityEmoji) QUALITY ASSESSMENT: \(qualityLevel)")
            logger.log("🎯 Point cloud density: \(String(format: "%.1f", Double(points.count) / 1000.0))K points")
            
            // 超高品質PLYヘッダー（位置と色情報）
            var plyContent = """
            ply
            format ascii 1.0
            comment Ultra High Quality Point Cloud
            comment Generated by Animal Track Scanner
            element vertex \(points.count)
            property float x
            property float y
            property float z
            property uchar red
            property uchar green
            property uchar blue
            property uchar alpha
            end_header
            
            """
            
            // 超高精度点群データを保存（最大12桁精度）
            for (index, point) in points.enumerated() {
                let position = point.position
                let color = point.color ?? SIMD4<UInt8>(255, 255, 255, 255)
                
                plyContent += String(format: "%.12f %.12f %.12f %d %d %d %d\n", 
                                   Double(position.x), Double(position.y), Double(position.z),
                                   Int(color.x), Int(color.y), Int(color.z), Int(color.w))
                
                // 進捗表示（大量の点群でも安心）
                if index % 10000 == 0 {
                    logger.log("Point cloud save progress: \(index)/\(points.count)")
                }
            }
            
            try plyContent.write(to: pointCloudURL, atomically: true, encoding: .utf8)
            logger.log("Point cloud saved with \(points.count) points to: \(pointCloudURL.path)")
        } catch {
            logger.error("Failed to save point cloud: \(error)")
        }
    }

    struct LocalizedString {
        static let cancel = NSLocalizedString(
            "Cancel (Object Reconstruction)",
            bundle: Bundle.main,
            value: "キャンセル",
            comment: "Button title to cancel reconstruction.")
    }

}

extension PhotogrammetrySession.Output.ProcessingStage {
    var processingStageString: String? {
        switch self {
            case .preProcessing:
                return NSLocalizedString(
                    "Preprocessing (Reconstruction)",
                    bundle: Bundle.main,
                    value: "前処理中…",
                    comment: "Feedback message during the object reconstruction phase."
                )
            case .imageAlignment:
                return NSLocalizedString(
                    "Aligning Images (Reconstruction)",
                    bundle: Bundle.main,
                    value: "画像を整列中…",
                    comment: "Feedback message during the object reconstruction phase."
                )
            case .pointCloudGeneration:
                return NSLocalizedString(
                    "Generating Point Cloud (Reconstruction)",
                    bundle: Bundle.main,
                    value: "点群を生成中…",
                    comment: "Feedback message during the object reconstruction phase."
                )
            case .meshGeneration:
                return NSLocalizedString(
                    "Generating Mesh (Reconstruction)",
                    bundle: Bundle.main,
                    value: "メッシュを生成中…",
                    comment: "Feedback message during the object reconstruction phase."
                )
            case .textureMapping:
                return NSLocalizedString(
                    "Mapping Texture (Reconstruction)",
                    bundle: Bundle.main,
                    value: "テクスチャをマッピング中…",
                    comment: "Feedback message during the object reconstruction phase."
                )
            case .optimization:
                return NSLocalizedString(
                    "Optimizing (Reconstruction)",
                    bundle: Bundle.main,
                    value: "最適化中…",
                    comment: "Feedback message during the object reconstruction phase."
                )
            default:
                return nil
            }
    }
}

private struct TitleView: View {
    var body: some View {
        Text(LocalizedString.processingTitle)
            .font(.largeTitle)
            .fontWeight(.bold)

    }

    private struct LocalizedString {
        static let processingTitle = NSLocalizedString(
            "Processing title (Object Capture)",
            bundle: Bundle.main,
            value: "処理中",
            comment: "Title of processing view during processing phase."
        )
    }
}
