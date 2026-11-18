import SwiftUI

struct SimplePointCloudView: View {
    let captureFolderURL: URL
    let pointCloudType: PointCloudType

    @State private var pointCloudData: String = ""
    @State private var pointCount: Int = 0
    @State private var fileSize: Int64 = 0
    @State private var isLoading = true
    @State private var pointCloudPoints: [SIMD3<Float>] = []
    @State private var pointCloudColors: [SIMD3<Float>] = []
    @State private var showDetails = false

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView("点群データを読み込み中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 12) {
                    Text("総点数: \(formatNumber(pointCount))点").font(.title2).fontWeight(.bold)
                    Text("ファイルサイズ: \(formatFileSize(fileSize))").font(.subheadline).foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

                PointCloud3DView(points: pointCloudPoints, colors: pointCloudColors)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(12)
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("ピンチでズーム・ドラッグで回転")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(8)
                                    .padding()
                            }
                        }
                    )
            }
        }
        .padding()
        .task { await loadSimplePointCloudData() }
    }

    private func loadSimplePointCloudData() async {
        let url = captureFolderURL.appendingPathComponent(pointCloudType.rawValue)
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            let (points, colors) = parsePointCloudData(data)
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = attributes[.size] as? Int64 ?? 0
            await MainActor.run {
                pointCloudData = data
                pointCount = points.count
                fileSize = size
                pointCloudPoints = points
                pointCloudColors = colors
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }

    private func parsePointCloudData(_ data: String) -> ([SIMD3<Float>], [SIMD3<Float>]) {
        let lines = data.components(separatedBy: .newlines)
        var points: [SIMD3<Float>] = []
        var colors: [SIMD3<Float>] = []
        var isDataSection = false
        for line in lines {
            if line == "end_header" { isDataSection = true; continue }
            if isDataSection && !line.isEmpty {
                let components = line.components(separatedBy: " ")
                if components.count >= 6,
                   let x = Float(components[0]),
                   let y = Float(components[1]),
                   let z = Float(components[2]),
                   let r = Int(components[3]),
                   let g = Int(components[4]),
                   let b = Int(components[5]) {
                    points.append(SIMD3<Float>(x, y, z))
                    colors.append(SIMD3<Float>(Float(r) / 255.0, Float(g) / 255.0, Float(b) / 255.0))
                }
            }
        }
        return (points, colors)
    }

    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter(); formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func formatFileSize(_ size: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

