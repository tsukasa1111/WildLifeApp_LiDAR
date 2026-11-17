/*
Hybrid Capture Primary View
ハイブリッドキャプチャシステム
従来のObject Capture + リアルタイム点群同時取得
*/

import RealityKit
import SwiftUI
import ARKit
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "HybridCapturePrimaryView")

struct HybridCapturePrimaryView: View {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession
    
    // リアルタイム点群状態
    @State private var realtimePoints: [SIMD3<Float>] = []
    @State private var realtimeColors: [SIMD4<Float>] = []
    @State private var arSession = ARSession()
    @State private var arCoordinator: ARSessionCoordinator?
    @State private var isRealtimeEnabled = true
    @State private var realtimeQuality = "準備中"
    @State private var showPointCloud = false
    
    var body: some View {
        ZStack {
            // 🎯 従来のObject Captureビュー（ベース）
            ObjectCaptureView(session: session,
                              cameraFeedOverlay: { 
                                  ZStack {
                                      HybridGradientBackground()
                                      
                                      // リアルタイム点群オーバーレイ
                                      if isRealtimeEnabled {
                                          RealtimeOverlayView()
                                      }
                                  }
                              })
            .hideObjectReticle(appModel.captureMode == .area)
            .blur(radius: appModel.showOverlaySheets ? 45 : 0)
            .transition(.opacity)
            
            // 🚀 リアルタイム点群ビュー（オーバーレイ）
            if showPointCloud && !realtimePoints.isEmpty {
                RealtimePointCloudOverlay(points: realtimePoints, colors: realtimeColors)
                    .allowsHitTesting(false)
                    .opacity(0.7)
            }
            
            // 🌟 ハイブリッドキャプチャオーバーレイ
            HybridCaptureOverlayView(session: session, 
                                   realtimePoints: realtimePoints,
                                   realtimeQuality: realtimeQuality,
                                   isRealtimeEnabled: $isRealtimeEnabled,
                                   showPointCloud: $showPointCloud)
        }
        .onAppear {
            setupHybridCapture()
        }
        .onDisappear {
            stopRealtimeCapture()
        }
    }
    
    // リアルタイムオーバーレイ情報
    private func RealtimeOverlayView() -> some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("リアルタイム点群")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    Text("\(realtimePoints.count) 点")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(realtimeQuality)
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                .padding(8)
                .background(Color.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Spacer()
            }
            .padding(.top, 50)
            .padding(.leading, 20)
            
            Spacer()
        }
    }
    
    private func setupHybridCapture() {
        logger.log("🌟 Setting up Hybrid Capture System")
        UIApplication.shared.isIdleTimerDisabled = true
        
        // ARセッション設定（リアルタイム点群用）
        if isRealtimeEnabled {
            setupRealtimePointCloudCapture()
        }
    }
    
    private func setupRealtimePointCloudCapture() {
        logger.log("🚀 Setting up realtime point cloud capture alongside Object Capture")
        
        let configuration = ARWorldTrackingConfiguration()

        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) else {
            isRealtimeEnabled = false
            logger.error("Scene depth is not supported on this device")
            return
        }
        configuration.frameSemantics.insert(.sceneDepth)
        
        // LiDARサポートチェック
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            configuration.sceneReconstruction = [.meshWithClassification]
            logger.log("✨ LiDAR mesh reconstruction with classification enabled for hybrid capture")
        } else if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = [.mesh]
            logger.log("✨ LiDAR mesh reconstruction enabled for hybrid capture")
        }
        
        configuration.worldAlignment = .gravity
        configuration.planeDetection = [.horizontal, .vertical]
        
        // ARセッションデリゲート設定
        let coordinator = ARSessionCoordinator(onPointCloudUpdate: updateRealtimePointCloud)
        arCoordinator = coordinator
        arSession.delegate = coordinator
        arSession.run(configuration)
        
        logger.log("🎯 Hybrid AR session started")
    }
    
    private func updateRealtimePointCloud(points: [SIMD3<Float>], colors: [SIMD4<Float>]) {
        // メインスレッドで更新
        DispatchQueue.main.async {
            let filteredData = self.filterRealtimePoints(points: points, colors: colors)
            self.realtimePoints.append(contentsOf: filteredData.points)
            self.realtimeColors.append(contentsOf: filteredData.colors)
            
            // 品質評価更新
            self.updateRealtimeQuality()
            
            // 🚀 点群数制限（メモリ使用量最適化）
            let maxRealtimePoints = getMaxRealtimePoints()
            if self.realtimePoints.count > maxRealtimePoints {
                let keepCount = maxRealtimePoints * 4 / 5 // 80%を保持
                self.realtimePoints = Array(self.realtimePoints.suffix(keepCount))
                self.realtimeColors = Array(self.realtimeColors.suffix(keepCount))
                logger.log("🔄 Trimmed realtime points: \(self.realtimePoints.count) points retained")
            }
        }
    }
    
    private func filterRealtimePoints(points: [SIMD3<Float>], colors: [SIMD4<Float>]) -> (points: [SIMD3<Float>], colors: [SIMD4<Float>]) {
        var filteredPoints: [SIMD3<Float>] = []
        var filteredColors: [SIMD4<Float>] = []
        
        for (index, point) in points.enumerated() {
            // 簡易重複チェック（パフォーマンス考慮）
            let isDuplicate = realtimePoints.suffix(1000).contains { existingPoint in
                simd_distance(point, existingPoint) < 0.005
            }
            guard !isDuplicate else { continue }
            
            filteredPoints.append(point)
            if index < colors.count {
                filteredColors.append(colors[index])
            } else {
                filteredColors.append(SIMD4<Float>(0.8, 0.8, 0.8, 1.0))
            }
        }
        
        return (filteredPoints, filteredColors)
    }
    
    private func updateRealtimeQuality() {
        let pointCount = realtimePoints.count
        
        if pointCount >= 500000 {
            realtimeQuality = "🏆 超高品質"
        } else if pointCount >= 200000 {
            realtimeQuality = "🚀 高品質"
        } else if pointCount >= 50000 {
            realtimeQuality = "✨ 良好"
        } else if pointCount >= 10000 {
            realtimeQuality = "👍 標準"
        } else {
            realtimeQuality = "📊 収集中"
        }
    }
    
    private func stopRealtimeCapture() {
        arSession.pause()
        arSession.delegate = nil
        arCoordinator = nil
        logger.log("⏸️ Realtime capture stopped")
    }
    
    // 🎯 デバイス性能に応じたリアルタイム点群の最大数
    private func getMaxRealtimePoints() -> Int {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        
        if totalMemory >= 8_000_000_000 { // 8GB以上
            return 100000 // 10万点
        } else if totalMemory >= 4_000_000_000 { // 4GB以上
            return 50000 // 5万点
        } else if totalMemory >= 3_000_000_000 { // 3GB以上
            return 25000 // 2.5万点
        } else {
            return 15000 // 1.5万点
        }
    }
    
    // リアルタイム点群をObject Captureデータと統合保存
    func saveHybridPointCloudData() async {
        guard let captureFolderManager = appModel.captureFolderManager else {
            logger.error("No capture folder manager available")
            return
        }
        
        let hybridPointCloudURL = captureFolderManager.captureFolder.appendingPathComponent("hybrid_pointcloud.ply")
        
        logger.log("💾 Saving hybrid point cloud: \(realtimePoints.count) realtime points")
        
        // 🚀 バックグラウンドでファイル生成（UIをブロックしない）
        await Task.detached(priority: .userInitiated) {
            do {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                var plyContent = """
                ply
                format ascii 1.0
                comment Hybrid Point Cloud - Object Capture + Realtime LiDAR
                comment Traditional Object Capture + Realtime AR points
                element vertex \(realtimePoints.count)
                property float x
                property float y
                property float z
                property uchar red
                property uchar green
                property uchar blue
                property uchar alpha
                end_header
                
                """
                
                // 📝 バッチ処理でパフォーマンス向上
                var batchContent = ""
                for (index, point) in realtimePoints.enumerated() {
                    let color = index < realtimeColors.count ? realtimeColors[index] : SIMD4<Float>(1, 1, 1, 1)
                    
                    batchContent += String(format: "%.6f %.6f %.6f %d %d %d %d\n",
                                       point.x, point.y, point.z,
                                       Int(color.x * 255), Int(color.y * 255), 
                                       Int(color.z * 255), Int(color.w * 255))
                    
                    // 1000行ごとにファイルに書き込み（メモリ使用量制限）
                    if index % 1000 == 0 && index > 0 {
                        plyContent += batchContent
                        batchContent = ""
                    }
                }
                
                plyContent += batchContent // 残りを追加
                
                try plyContent.write(to: hybridPointCloudURL, atomically: true, encoding: .utf8)
                
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                logger.log("✅ Hybrid point cloud saved in \(String(format: "%.2f", duration))s: \(hybridPointCloudURL.path)")
            } catch {
                logger.error("Failed to save hybrid point cloud: \(error)")
            }
        }.value
    }
}

// ARセッション管理用Coordinator
class ARSessionCoordinator: NSObject, ARSessionDelegate {
    let onPointCloudUpdate: ([SIMD3<Float>], [SIMD4<Float>]) -> Void
    
    init(onPointCloudUpdate: @escaping ([SIMD3<Float>], [SIMD4<Float>]) -> Void) {
        self.onPointCloudUpdate = onPointCloudUpdate
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // LiDAR深度データから点群を抽出
        guard let sceneDepth = frame.sceneDepth else { return }
        
        let points = DepthPointCloudSampler.sample(frame: frame, depth: sceneDepth)
        let colors = Array(repeating: SIMD4<Float>(0.8, 0.8, 0.8, 1.0), count: points.count)
        
        onPointCloudUpdate(points, colors)
    }
    
}

// リアルタイム点群表示オーバーレイ
struct RealtimePointCloudOverlay: View {
    let points: [SIMD3<Float>]
    let colors: [SIMD4<Float>]
    
    var body: some View {
        Canvas { context, size in
            // 簡易的な2D投影で点群を描画
            for (index, point) in points.enumerated() {
                let x = (point.x + 1.0) * Float(size.width) * 0.5
                let y = (1.0 - point.y) * Float(size.height) * 0.5
                
                if x >= 0 && x < Float(size.width) && y >= 0 && y < Float(size.height) {
                    let color = index < colors.count ? colors[index] : SIMD4<Float>(1, 1, 1, 1)
                    context.fill(
                        Path(ellipseIn: CGRect(x: CGFloat(x), y: CGFloat(y), width: 2, height: 2)),
                        with: .color(Color(red: CGFloat(color.x), green: CGFloat(color.y), blue: CGFloat(color.z)))
                    )
                }
            }
        }
    }
}

// ハイブリッドキャプチャ用オーバーレイ
struct HybridCaptureOverlayView: View {
    let session: ObjectCaptureSession
    let realtimePoints: [SIMD3<Float>]
    let realtimeQuality: String
    @Binding var isRealtimeEnabled: Bool
    @Binding var showPointCloud: Bool
    
    var body: some View {
        VStack {
            // 上部リアルタイム制御
            HStack {
                Button(action: { isRealtimeEnabled.toggle() }) {
                    HStack {
                        Image(systemName: isRealtimeEnabled ? "dot.radiowaves.left.and.right" : "dot.radiowaves.left.and.right")
                            .foregroundColor(isRealtimeEnabled ? .green : .gray)
                        Text(isRealtimeEnabled ? "実行中" : "停止中")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Spacer()
                
                Button(action: { showPointCloud.toggle() }) {
                    Image(systemName: showPointCloud ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 100)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 従来のキャプチャオーバーレイ
            CaptureOverlayView(session: session)
        }
    }
}

// HybridCapture用のGradientBackground
private struct HybridGradientBackground: View {
    private let gradient = LinearGradient(
        colors: [.black.opacity(0.4), .clear],
        startPoint: .top,
        endPoint: .bottom
    )
    private let frameHeight: CGFloat = 300

    var body: some View {
        VStack {
            gradient
                .frame(height: frameHeight)

            Spacer()

            gradient
                .rotation3DEffect(Angle(degrees: 180), axis: (x: 1, y: 0, z: 0))
                .frame(height: frameHeight)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
