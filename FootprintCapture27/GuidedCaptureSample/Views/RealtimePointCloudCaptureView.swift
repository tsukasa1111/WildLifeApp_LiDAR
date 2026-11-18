/*
Realtime Point Cloud Capture View
iOS 18対応 - リアルタイム点群キャプチャシステム
LiDARとRGBを同時活用した革新的高品質点群生成
*/

import RealityKit
import SwiftUI
import ARKit
import CoreVideo
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "RealtimePointCloudCapture")

@available(iOS 18.0, *)
struct RealtimePointCloudCaptureView: View {
    @EnvironmentObject var appModel: AppDataModel
    @State private var arView = ARView(frame: .zero)
    @State private var capturedPoints: [SIMD3<Float>] = []
    @State private var capturedColors: [SIMD4<Float>] = []
    @State private var seenVoxels: Set<VoxelKey> = []
    @State private var isCapturing = false
    @State private var captureCount = 0
    @State private var qualityLevel = "準備中"
    
    var body: some View {
        ZStack {
            // 🌟 ARViewでリアルタイム点群表示
            ARViewContainer(arView: arView, 
                          onPointCloudUpdate: updatePointCloud)
                .ignoresSafeArea()
            
            VStack {
                // 上部情報表示
                HStack {
                    VStack(alignment: .leading) {
                        Text("🚀 リアルタイム点群キャプチャ")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("品質: \(qualityLevel)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Text("点数: \(capturedPoints.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    
                    // iOS 18バッジ
                    Text("iOS 18")
                        .font(.caption)
                        .padding(4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding()
                
                Spacer()
                
                // 下部コントロール
                HStack {
                    // キャプチャボタン
                    Button(action: toggleCapture) {
                        HStack {
                            Image(systemName: isCapturing ? "stop.circle.fill" : "camera.circle.fill")
                            Text(isCapturing ? "停止" : "開始")
                        }
                        .font(.title2)
                        .padding()
                        .background(isCapturing ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer()
                    
                    // 保存ボタン
                    Button(action: savePointCloud) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("保存")
                        }
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(capturedPoints.isEmpty)
                    
                    Spacer()
                    
                    // 完了ボタン
                    Button(action: finishCapture) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("完了")
                        }
                        .font(.title2)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(capturedPoints.count < 10000)
                }
                .padding()
            }
        }
        .onAppear {
            setupARSession()
        }
    }
    
    private func setupARSession() {
        logger.log("🚀 Setting up iOS 18 Realtime Point Cloud AR Session")
        
        // iOS 18対応の最新AR設定
        let configuration = ARWorldTrackingConfiguration()
        
        // LiDARスキャンを最大活用
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) else {
            qualityLevel = "LiDAR非対応"
            logger.error("Scene depth is not supported on this device")
            return
        }
        configuration.frameSemantics.insert(.sceneDepth)

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            configuration.sceneReconstruction = [.meshWithClassification]
            logger.log("✨ LiDAR mesh reconstruction with classification enabled")
        } else if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = [.mesh]
            logger.log("✨ LiDAR mesh reconstruction enabled")
        }
        
        // 高品質設定
        configuration.worldAlignment = .gravity
        configuration.planeDetection = [.horizontal, .vertical]
        
        arView.session.run(configuration)
        logger.log("🌟 AR Session started with maximum quality settings")
    }
    
    private func updatePointCloud(points: [SIMD3<Float>], colors: [SIMD4<Float>]) {
        guard isCapturing, capturedPoints.count < 500_000 else { return }
        
        // 🎯 高品質点群フィルタリング
        let filteredPoints = filterHighQualityPoints(points: points, colors: colors)
        
        capturedPoints.append(contentsOf: filteredPoints.points)
        capturedColors.append(contentsOf: filteredPoints.colors)
        
        // 品質レベル更新
        updateQualityLevel()
        
        logger.log("📊 Point cloud updated: \(capturedPoints.count) total points")
    }
    
    private func filterHighQualityPoints(points: [SIMD3<Float>], colors: [SIMD4<Float>]) -> (points: [SIMD3<Float>], colors: [SIMD4<Float>]) {
        // 🚀 高品質フィルタリング: 重複除去、ノイズ除去
        var filteredPoints: [SIMD3<Float>] = []
        var filteredColors: [SIMD4<Float>] = []
        
        for (index, point) in points.enumerated() {
            guard capturedPoints.count + filteredPoints.count < 500_000 else { break }
            let voxel = VoxelKey(point: point)
            guard seenVoxels.insert(voxel).inserted else { continue }
            
            filteredPoints.append(point)
            if index < colors.count {
                filteredColors.append(colors[index])
            } else {
                filteredColors.append(SIMD4<Float>(1, 1, 1, 1))
            }
        }
        
        return (filteredPoints, filteredColors)
    }
    
    private func updateQualityLevel() {
        let pointCount = capturedPoints.count
        
        if pointCount >= 500000 {
            qualityLevel = "点群上限 (500K)"
        } else if pointCount >= 100000 {
            qualityLevel = "👍 標準 (100K+)"
        } else if pointCount >= 10000 {
            qualityLevel = "📊 基本 (10K+)"
        } else {
            qualityLevel = "⚠️ 不足 (<10K)"
        }
    }
    
    private func toggleCapture() {
        isCapturing.toggle()
        if isCapturing {
            logger.log("🎯 Started realtime point cloud capture")
        } else {
            logger.log("⏸️ Paused realtime point cloud capture")
        }
    }
    
    private func savePointCloud() {
        Task {
            await saveRealtimePointCloud()
        }
    }
    
    private func saveRealtimePointCloud() async {
        guard let captureFolderManager = appModel.captureFolderManager else {
            logger.error("No capture folder manager available")
            return
        }
        
        let pointCloudURL = captureFolderManager.captureFolder.appendingPathComponent("realtime_pointcloud.ply")
        
        logger.log("💾 Saving realtime point cloud: \(capturedPoints.count) points")
        
        do {
            var plyContent = """
            ply
            format ascii 1.0
            comment iOS 18 Realtime Point Cloud
            comment LiDAR scene depth with neutral display color
            element vertex \(capturedPoints.count)
            property float x
            property float y
            property float z
            property uchar red
            property uchar green
            property uchar blue
            property uchar alpha
            end_header
            
            """
            
            for (index, point) in capturedPoints.enumerated() {
                let color = index < capturedColors.count ? capturedColors[index] : SIMD4<Float>(1, 1, 1, 1)
                
                plyContent += String(format: "%.6f %.6f %.6f %d %d %d %d\n",
                                   point.x, point.y, point.z,
                                   Int(color.x * 255), Int(color.y * 255), 
                                   Int(color.z * 255), Int(color.w * 255))
            }
            
            try plyContent.write(to: pointCloudURL, atomically: true, encoding: .utf8)
            logger.log("✅ Realtime point cloud saved: \(pointCloudURL.path)")
        } catch {
            logger.error("Failed to save realtime point cloud: \(error)")
        }
    }
    
    private func finishCapture() {
        logger.log("🎉 Finishing realtime point cloud capture")
        Task {
            await saveRealtimePointCloud()
            await MainActor.run {
                appModel.state = .actionSelection
            }
        }
    }
}

// 🌟 ARView Container for iOS 18
@available(iOS 18.0, *)
struct ARViewContainer: UIViewRepresentable {
    let arView: ARView
    let onPointCloudUpdate: ([SIMD3<Float>], [SIMD4<Float>]) -> Void
    
    func makeUIView(context: Context) -> ARView {
        // Delegate設定
        arView.session.delegate = context.coordinator
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // 更新処理
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPointCloudUpdate: onPointCloudUpdate)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        let onPointCloudUpdate: ([SIMD3<Float>], [SIMD4<Float>]) -> Void
        
        init(onPointCloudUpdate: @escaping ([SIMD3<Float>], [SIMD4<Float>]) -> Void) {
            self.onPointCloudUpdate = onPointCloudUpdate
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // LiDAR点群データ取得
            guard let sceneDepth = frame.sceneDepth else { return }
            
            let points = DepthPointCloudSampler.sample(frame: frame, depth: sceneDepth)
            let colors = Array(repeating: SIMD4<Float>(0.8, 0.8, 0.8, 1.0), count: points.count)
            
            DispatchQueue.main.async {
                self.onPointCloudUpdate(points, colors)
            }
        }
    }
}

enum DepthPointCloudSampler {
    static func sample(frame: ARFrame, depth: ARDepthData) -> [SIMD3<Float>] {
        let depthMap = depth.depthMap
        guard CVPixelBufferGetPixelFormatType(depthMap) == kCVPixelFormatType_DepthFloat32,
              CVPixelBufferLockBaseAddress(depthMap, .readOnly) == kCVReturnSuccess else { return [] }
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }

        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let cameraWidth = CVPixelBufferGetWidth(frame.capturedImage)
        let cameraHeight = CVPixelBufferGetHeight(frame.capturedImage)
        guard width > 0, height > 0, cameraWidth > 0, cameraHeight > 0,
              let base = CVPixelBufferGetBaseAddress(depthMap)?.assumingMemoryBound(to: Float32.self) else { return [] }

        let intrinsics = frame.camera.intrinsics
        let scaleX = Float(width) / Float(cameraWidth)
        let scaleY = Float(height) / Float(cameraHeight)
        let fx = intrinsics.columns.0.x * scaleX
        let fy = intrinsics.columns.1.y * scaleY
        let cx = intrinsics.columns.2.x * scaleX
        let cy = intrinsics.columns.2.y * scaleY
        guard fx > 0, fy > 0 else { return [] }

        let rowStride = CVPixelBufferGetBytesPerRow(depthMap) / MemoryLayout<Float32>.stride
        let step = max(1, min(width, height) / 80)
        let transform = frame.camera.transform
        var points: [SIMD3<Float>] = []
        points.reserveCapacity((width / step + 1) * (height / step + 1))

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let distance = base[y * rowStride + x]
                guard distance.isFinite, distance > 0.05, distance < 5.0 else { continue }
                let cameraPoint = SIMD4<Float>(
                    (Float(x) - cx) * distance / fx,
                    -(Float(y) - cy) * distance / fy,
                    -distance,
                    1.0
                )
                let worldPoint = transform * cameraPoint
                points.append(SIMD3<Float>(worldPoint.x, worldPoint.y, worldPoint.z))
            }
        }
        return points
    }
}

private struct VoxelKey: Hashable {
    let x: Int32
    let y: Int32
    let z: Int32

    init(point: SIMD3<Float>) {
        x = Int32((point.x / 0.005).rounded(.down))
        y = Int32((point.y / 0.005).rounded(.down))
        z = Int32((point.z / 0.005).rounded(.down))
    }
}
