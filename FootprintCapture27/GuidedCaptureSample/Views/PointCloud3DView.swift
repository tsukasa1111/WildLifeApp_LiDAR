/*
Point Cloud 3D Visualization View
SceneKitを使用した点群データの3D表示
*/

import SwiftUI
import SceneKit
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "PointCloud3DView")

struct PointCloud3DView: UIViewRepresentable {
    let points: [SIMD3<Float>]
    let colors: [SIMD3<Float>]
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = SCNScene()
        scnView.backgroundColor = UIColor.black // より良いコントラストのため黒背景
        scnView.allowsCameraControl = true
        
        // 超高品質レンダリング設定
        scnView.antialiasingMode = .multisampling4X
        scnView.preferredFramesPerSecond = 60
        scnView.rendersContinuously = false
        
        // 高品質ライティング
        scnView.autoenablesDefaultLighting = false
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 300
        ambientLight.color = UIColor.white
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scnView.scene?.rootNode.addChildNode(ambientNode)
        
        // メインライト
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 800
        directionalLight.color = UIColor.white
        let lightNode = SCNNode()
        lightNode.light = directionalLight
        lightNode.position = SCNVector3(5, 10, 5)
        lightNode.look(at: SCNVector3(0, 0, 0))
        scnView.scene?.rootNode.addChildNode(lightNode)
        
        // カメラ制御の改善
        scnView.defaultCameraController.maximumVerticalAngle = 89
        scnView.defaultCameraController.minimumVerticalAngle = -89
        scnView.defaultCameraController.maximumHorizontalAngle = 180
        scnView.defaultCameraController.minimumHorizontalAngle = -180
        
        // Add point cloud to scene
        addPointCloudToScene(scnView.scene!)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update the scene if needed
        uiView.scene?.rootNode.childNodes.forEach { $0.removeFromParentNode() }
        addPointCloudToScene(uiView.scene!)
    }
    
    private func addPointCloudToScene(_ scene: SCNScene) {
        guard !points.isEmpty else { 
            print("DEBUG: No points to display")
            return 
        }
        
        print("DEBUG: Adding \(points.count) points to scene")
        print("DEBUG: Colors count: \(colors.count)")
        
        // 🚀 パフォーマンス最適化 - デバイス性能に応じた点数制限
        let deviceMaxPoints = getMaxPointsForDevice()
        let maxPoints = min(points.count, deviceMaxPoints)
        let step = max(1, points.count / maxPoints)
        
        logger.log("🎯 Optimizing display: \(points.count) → \(maxPoints) points (step: \(step))")
        
        let sampledPoints = stride(from: 0, to: points.count, by: step).map { points[$0] }
        let sampledColors = stride(from: 0, to: colors.count, by: step).map { colors[$0] }
        
        print("DEBUG: Sampled points: \(sampledPoints.count)")
        print("DEBUG: Sample coordinates: \(Array(sampledPoints.prefix(3)))")
        
        // 究極効率の点群表示 - 最適化されたカスタムジオメトリ
        let vertices = sampledPoints.map { SCNVector3($0.x, $0.y, $0.z) }
        let vertexData = Data(bytes: vertices, count: vertices.count * MemoryLayout<SCNVector3>.size)
        
        let vertexSource = SCNGeometrySource(data: vertexData,
                                           semantic: .vertex,
                                           vectorCount: vertices.count,
                                           usesFloatComponents: true,
                                           componentsPerVector: 3,
                                           bytesPerComponent: MemoryLayout<Float>.size,
                                           dataOffset: 0,
                                           dataStride: MemoryLayout<SCNVector3>.size)
        
        // 色データを作成
        var colorArray: [SCNVector3] = []
        for i in 0..<vertices.count {
            if i < sampledColors.count {
                let color = sampledColors[i]
                colorArray.append(SCNVector3(color.x, color.y, color.z))
            } else {
                colorArray.append(SCNVector3(0.5, 0.5, 1.0)) // デフォルト色
            }
        }
        
        let colorData = Data(bytes: colorArray, count: colorArray.count * MemoryLayout<SCNVector3>.size)
        let colorSource = SCNGeometrySource(data: colorData,
                                          semantic: .color,
                                          vectorCount: colorArray.count,
                                          usesFloatComponents: true,
                                          componentsPerVector: 3,
                                          bytesPerComponent: MemoryLayout<Float>.size,
                                          dataOffset: 0,
                                          dataStride: MemoryLayout<SCNVector3>.size)
        
        // より見やすい点群表示のために複数のアプローチを試す
        
        // アプローチ1: 大きめの点として表示
        let indices = Array(0..<vertices.count).map { UInt32($0) }
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<UInt32>.size)
        let element = SCNGeometryElement(data: indexData,
                                       primitiveType: .point,
                                       primitiveCount: vertices.count,
                                       bytesPerIndex: MemoryLayout<UInt32>.size)
        
        let geometry = SCNGeometry(sources: [vertexSource, colorSource], elements: [element])
        
        // 超高品質点表示のためのマテリアル設定
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased // 物理ベースレンダリング
        material.isDoubleSided = true
        material.metalness.contents = 0.1
        material.roughness.contents = 0.2
        
        // 超高品質点テクスチャ設定
        let pointTexture = createUltraHighQualityPointTexture()
        material.diffuse.contents = pointTexture
        material.transparency = 0.95
        material.blendMode = .alpha
        
        // 発光効果でより鮮明に
        material.emission.contents = UIColor.white.withAlphaComponent(0.1)
        
        geometry.materials = [material]
        
        let pointCloudNode = SCNNode(geometry: geometry)
        scene.rootNode.addChildNode(pointCloudNode)
        
        // アプローチ2: 一部の点を小さな球体として表示（パフォーマンス考慮で間引き）
        let sphereStep = max(1, vertices.count / 1000) // 最大1000個の球体
        for i in stride(from: 0, to: vertices.count, by: sphereStep) {
            let sphereGeometry = SCNSphere(radius: 0.003)
            let sphereNode = SCNNode(geometry: sphereGeometry)
            sphereNode.position = vertices[i]
            
            let sphereMaterial = SCNMaterial()
            sphereMaterial.lightingModel = .constant
            if i < colorArray.count {
                let color = colorArray[i]
                sphereMaterial.diffuse.contents = UIColor(red: CGFloat(color.x), 
                                                        green: CGFloat(color.y), 
                                                        blue: CGFloat(color.z), 
                                                        alpha: 1.0)
            } else {
                sphereMaterial.diffuse.contents = UIColor.white
            }
            sphereGeometry.materials = [sphereMaterial]
            
            scene.rootNode.addChildNode(sphereNode)
        }
        
        print("DEBUG: Point cloud node added to scene")
        print("DEBUG: Node bounds: \(pointCloudNode.boundingBox)")
        
        // Position camera to view the point cloud
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        
        // Calculate bounding box of points
        if !sampledPoints.isEmpty {
            let minX = sampledPoints.map { $0.x }.min() ?? 0
            let maxX = sampledPoints.map { $0.x }.max() ?? 0
            let minY = sampledPoints.map { $0.y }.min() ?? 0
            let maxY = sampledPoints.map { $0.y }.max() ?? 0
            let minZ = sampledPoints.map { $0.z }.min() ?? 0
            let maxZ = sampledPoints.map { $0.z }.max() ?? 0
            
            let centerX = (minX + maxX) / 2
            let centerY = (minY + maxY) / 2
            let centerZ = (minZ + maxZ) / 2
            
            let sizeX = maxX - minX
            let sizeY = maxY - minY
            let sizeZ = maxZ - minZ
            let maxSize = max(sizeX, sizeY, sizeZ)
            
            // Position camera at a good distance
            let distance = maxSize * 2
            cameraNode.position = SCNVector3(centerX, centerY, centerZ + distance)
            cameraNode.look(at: SCNVector3(centerX, centerY, centerZ))
            
            print("DEBUG: Point cloud bounds - X: \(minX) to \(maxX), Y: \(minY) to \(maxY), Z: \(minZ) to \(maxZ)")
            print("DEBUG: Center: (\(centerX), \(centerY), \(centerZ))")
            print("DEBUG: Max size: \(maxSize), Camera distance: \(distance)")
            print("DEBUG: Camera position: \(cameraNode.position)")
        }
        
        scene.rootNode.addChildNode(cameraNode)
        
        // Add some ambient lighting
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 300
        scene.rootNode.addChildNode(ambientLight)
    }
    
    private func createUltraHighQualityPointTexture() -> UIImage {
        let size = CGSize(width: 128, height: 128) // 4倍高解像度
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let center = CGPoint(x: size.width/2, y: size.height/2)
            let radius = min(size.width, size.height) / 2.2
            
            // 放射状グラデーション（中心が明るく、外側が暗い）
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor.white.withAlphaComponent(1.0).cgColor,
                UIColor.white.withAlphaComponent(0.8).cgColor,
                UIColor.white.withAlphaComponent(0.4).cgColor,
                UIColor.clear.cgColor
            ]
            let locations: [CGFloat] = [0.0, 0.3, 0.7, 1.0]
            
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) {
                context.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: radius,
                    options: []
                )
            }
            
            // 中心に小さな明るい点を追加
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: CGRect(
                x: center.x - 2,
                y: center.y - 2,
                width: 4,
                height: 4
            ))
        }
    }
    
    private func createPointTexture() -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // 白い円を描画
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: rect.insetBy(dx: 4, dy: 4))
            
            // 境界線
            context.cgContext.setStrokeColor(UIColor.gray.cgColor)
            context.cgContext.setLineWidth(1)
            context.cgContext.strokeEllipse(in: rect.insetBy(dx: 4, dy: 4))
        }
    }
    
    // 🎯 デバイス性能に応じた最大点数を決定
    private func getMaxPointsForDevice() -> Int {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        
        // メモリ容量に基づく制限
        if totalMemory >= 8_000_000_000 { // 8GB以上
            return 50000 // 5万点
        } else if totalMemory >= 4_000_000_000 { // 4GB以上
            return 25000 // 2.5万点
        } else if totalMemory >= 3_000_000_000 { // 3GB以上
            return 15000 // 1.5万点
        } else {
            return 10000 // 1万点
        }
    }
}
