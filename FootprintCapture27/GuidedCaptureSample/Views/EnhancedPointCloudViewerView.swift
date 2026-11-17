/*
Enhanced Point Cloud Viewer View
拡張点群ビューア - 複数の点群タイプ対応
従来・ハイブリッド・リアルタイム・超高品質点群の切り替え表示
*/

import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "EnhancedPointCloudViewer")

struct EnhancedPointCloudViewerView: View {
    let captureFolderURL: URL
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPointCloudType: PointCloudType = .best
    @State private var pointCloudData: String = ""
    @State private var pointCount: Int = 0
    @State private var loadingError: String?
    @State private var showingDataView = false
    @State private var pointCloudPoints: [SIMD3<Float>] = []
    @State private var pointCloudColors: [SIMD3<Float>] = []
    
    enum PointCloudType: CaseIterable {
        case best
        case ios18MaxQuality
        case ultraQuality
        case hybrid
        case realtime
        case traditional
        
        var displayName: String {
            switch self {
            case .best: return "🏆 最高品質"
            case .ios18MaxQuality: return "👑 iOS 18最高"
            case .ultraQuality: return "🌟 超高品質"
            case .hybrid: return "🚀 ハイブリッド"
            case .realtime: return "⚡ リアルタイム"
            case .traditional: return "📸 従来"
            }
        }
        
        var fileName: String {
            switch self {
            case .best: return "" // 動的に決定
            case .ios18MaxQuality: return "ios18_maximum_quality_pointcloud.ply"
            case .ultraQuality: return "ultra_quality_pointcloud.ply"
            case .hybrid: return "hybrid_pointcloud.ply"
            case .realtime: return "realtime_pointcloud.ply"
            case .traditional: return "pointcloud.ply"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 点群タイプ選択
                pointCloudTypeSelector
                
                if !pointCloudData.isEmpty {
                    // 点群情報表示
                    pointCloudInfoCard
                    
                    if showingDataView {
                        // データビュー
                        dataView
                    } else {
                        // 3D可視化ビュー
                        visualizationView
                    }
                    
                    // 表示切り替えボタン
                    toggleViewButton
                } else if let error = loadingError {
                    // エラー表示
                    errorView(error: error)
                } else {
                    // ローディング表示
                    loadingView
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("点群ビューア")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadPointCloudData()
        }
        .onChange(of: selectedPointCloudType) { _, _ in
            loadPointCloudData()
        }
    }
    
    private var pointCloudTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("点群タイプ")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availablePointCloudTypes, id: \.fileName) { type in
                        Button(action: {
                            selectedPointCloudType = type
                        }) {
                            VStack(spacing: 4) {
                                Text(type.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                
                                if type == selectedPointCloudType {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 6, height: 6)
                                } else {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(type == selectedPointCloudType ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var pointCloudInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("点群統計")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(selectedPointCloudType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(pointCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("点")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 品質レベル表示
            HStack {
                Text("品質レベル:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(getQualityLevel())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(getQualityColor())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var dataView: some View {
        ScrollView {
            Text(pointCloudData)
                .font(.system(.caption, design: .monospaced))
                .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .frame(maxHeight: 400)
    }
    
    private var visualizationView: some View {
        VStack {
            if !pointCloudPoints.isEmpty {
                PointCloud3DView(points: pointCloudPoints, colors: pointCloudColors)
                    .frame(height: 400)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 400)
                    .overlay(
                        VStack {
                            Image(systemName: "cube.transparent")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("3D点群を読み込み中...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
    }
    
    private var toggleViewButton: some View {
        Button(action: {
            withAnimation {
                showingDataView.toggle()
            }
        }) {
            HStack {
                Image(systemName: showingDataView ? "cube.transparent" : "doc.text")
                Text(showingDataView ? "3D表示に切り替え" : "データ表示に切り替え")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("エラー")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("再試行") {
                loadPointCloudData()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("点群データを読み込み中...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var availablePointCloudTypes: [PointCloudType] {
        var types: [PointCloudType] = [.best]
        
        for type in PointCloudType.allCases where type != .best {
            let url = getPointCloudURL(for: type)
            if FileManager.default.fileExists(atPath: url.path) {
                types.append(type)
            }
        }
        
        return types
    }
    
    private func getPointCloudURL(for type: PointCloudType) -> URL {
        if type == .best {
            return getBestPointCloudURL()
        } else {
            return captureFolderURL.appendingPathComponent(type.fileName)
        }
    }
    
    private func getBestPointCloudURL() -> URL {
        let ios18MaxQuality = captureFolderURL.appendingPathComponent("ios18_maximum_quality_pointcloud.ply")
        let ultraQuality = captureFolderURL.appendingPathComponent("ultra_quality_pointcloud.ply")
        let hybrid = captureFolderURL.appendingPathComponent("hybrid_pointcloud.ply")
        let realtime = captureFolderURL.appendingPathComponent("realtime_pointcloud.ply")
        let traditional = captureFolderURL.appendingPathComponent("pointcloud.ply")
        
        if FileManager.default.fileExists(atPath: ios18MaxQuality.path) {
            return ios18MaxQuality
        } else if FileManager.default.fileExists(atPath: ultraQuality.path) {
            return ultraQuality
        } else if FileManager.default.fileExists(atPath: hybrid.path) {
            return hybrid
        } else if FileManager.default.fileExists(atPath: realtime.path) {
            return realtime
        } else {
            return traditional
        }
    }
    
    private func loadPointCloudData() {
        let url = getPointCloudURL(for: selectedPointCloudType)
        
        // 🔄 UI状態をローディングに設定
        self.loadingError = nil
        self.pointCloudData = ""
        self.pointCount = 0
        self.pointCloudPoints = []
        self.pointCloudColors = []
        
        logger.log("🔄 Starting to load point cloud: \(url.lastPathComponent)")
        
        Task.detached(priority: .userInitiated) {
            do {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // 📁 ファイルサイズチェック
                let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
                logger.log("📁 File size: \(fileSize / 1024)KB")
                
                if fileSize > 50 * 1024 * 1024 { // 50MB以上
                    await MainActor.run {
                        self.loadingError = "ファイルサイズが大きすぎます（\(fileSize / 1024 / 1024)MB）。処理をスキップします。"
                    }
                    return
                }
                
                // 📖 ファイル読み込み
                logger.log("📖 Reading file...")
                let data = try String(contentsOf: url)
                let readTime = CFAbsoluteTimeGetCurrent()
                logger.log("📖 File read completed in \(String(format: "%.2f", readTime - startTime))s")
                
                // 🔍 データ解析（軽量化）
                logger.log("🔍 Parsing point cloud data...")
                let parsedData = await parsePointCloudDataOptimized(data)
                let parseTime = CFAbsoluteTimeGetCurrent()
                logger.log("🔍 Parsing completed in \(String(format: "%.2f", parseTime - readTime))s")
                
                // 🎯 UI更新
                await MainActor.run {
                    self.pointCloudData = data.count > 100000 ? String(data.prefix(100000)) + "\\n... (truncated)" : data
                    self.pointCount = parsedData.pointCount
                    self.pointCloudPoints = parsedData.points
                    self.pointCloudColors = parsedData.colors
                    self.loadingError = nil
                }
                
                let totalTime = CFAbsoluteTimeGetCurrent() - startTime
                logger.log("✅ Point cloud loaded successfully in \(String(format: "%.2f", totalTime))s: \(parsedData.pointCount) points")
                
            } catch {
                logger.error("❌ Failed to load point cloud: \(error)")
                await MainActor.run {
                    self.loadingError = "点群データの読み込みに失敗: \(error.localizedDescription)"
                    self.pointCloudData = ""
                    self.pointCount = 0
                    self.pointCloudPoints = []
                    self.pointCloudColors = []
                }
            }
        }
    }
    
    private func parsePointCloudDataOptimized(_ data: String) async -> (pointCount: Int, points: [SIMD3<Float>], colors: [SIMD3<Float>]) {
        return await Task.detached(priority: .userInitiated) {
            return self.parsePointCloudDataInternal(data, maxPoints: 10000) // 表示用に10K点に制限
        }.value
    }
    
    private func parsePointCloudData(_ data: String) -> (pointCount: Int, points: [SIMD3<Float>], colors: [SIMD3<Float>]) {
        return parsePointCloudDataInternal(data, maxPoints: nil)
    }
    
    private func parsePointCloudDataInternal(_ data: String, maxPoints: Int?) -> (pointCount: Int, points: [SIMD3<Float>], colors: [SIMD3<Float>]) {
        let lines = data.components(separatedBy: .newlines)
        var points: [SIMD3<Float>] = []
        var colors: [SIMD3<Float>] = []
        var isDataSection = false
        var totalPointCount = 0
        
        // 📊 事前にメモリ確保（パフォーマンス向上）
        if let maxPoints = maxPoints {
            points.reserveCapacity(maxPoints)
            colors.reserveCapacity(maxPoints)
        }
        
        let step = if let maxPoints = maxPoints, lines.count > maxPoints * 2 {
            max(1, lines.count / maxPoints) // サンプリング間隔
        } else {
            1
        }
        
        logger.log("🔍 Parsing with step: \(step), maxPoints: \(maxPoints ?? -1)")
        
        for (index, line) in lines.enumerated() {
            if line == "end_header" {
                isDataSection = true
                continue
            }
            
            if isDataSection && !line.isEmpty {
                totalPointCount += 1
                
                // サンプリング制御
                if index % step != 0 && maxPoints != nil {
                    continue
                }
                
                // 最大点数制限
                if let maxPoints = maxPoints, points.count >= maxPoints {
                    break
                }
                
                let components = line.components(separatedBy: .whitespaces)
                if components.count >= 6 {
                    if let x = Float(components[0]),
                       let y = Float(components[1]),
                       let z = Float(components[2]),
                       let r = Float(components[3]),
                       let g = Float(components[4]),
                       let b = Float(components[5]) {
                        
                        points.append(SIMD3<Float>(x, y, z))
                        colors.append(SIMD3<Float>(r/255.0, g/255.0, b/255.0))
                    }
                }
            }
        }
        
        logger.log("📊 Parsed \(points.count) display points from \(totalPointCount) total points")
        return (totalPointCount, points, colors)
    }
    
    private func getQualityLevel() -> String {
        if pointCount >= 2000000 {
            return "研究グレード"
        } else if pointCount >= 1000000 {
            return "プロフェッショナル"
        } else if pointCount >= 500000 {
            return "高品質"
        } else if pointCount >= 100000 {
            return "標準"
        } else if pointCount >= 10000 {
            return "基本"
        } else {
            return "低密度"
        }
    }
    
    private func getQualityColor() -> Color {
        if pointCount >= 2000000 {
            return .purple
        } else if pointCount >= 1000000 {
            return .blue
        } else if pointCount >= 500000 {
            return .green
        } else if pointCount >= 100000 {
            return .orange
        } else {
            return .red
        }
    }
}