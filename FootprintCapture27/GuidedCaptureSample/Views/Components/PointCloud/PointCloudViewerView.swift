import SwiftUI

struct PointCloudViewerView: View {
    let pointCloudURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var pointCloudData: String = ""
    @State private var pointCount: Int = 0
    @State private var loadingError: String?
    @State private var showingDataView = false
    @State private var pointCloudPoints: [SIMD3<Float>] = []
    @State private var pointCloudColors: [SIMD3<Float>] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if !pointCloudData.isEmpty {
                    if showingDataView {
                        dataView
                    } else {
                        visualizationView
                    }

                    Button(action: { withAnimation { showingDataView.toggle() } }) {
                        HStack {
                            Image(systemName: showingDataView ? "cube.transparent" : "doc.text")
                            Text(showingDataView ? "3D表示に切り替え" : "データ表示に切り替え")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    ShareLink(item: pointCloudURL) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("点群ファイルを共有")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else if let error = loadingError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text("読み込みエラー").font(.title2).fontWeight(.bold)
                        Text(error).font(.body).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                } else {
                    VStack(spacing: 16) {
                        ProgressView().scaleEffect(1.5)
                        Text("点群データを読み込み中...").font(.headline)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("キャプチャプレビュー")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("完了") { dismiss() }.font(.headline).fontWeight(.semibold) } }
        }
        .task { await loadPointCloudData() }
    }

    private var visualizationView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("総点数").font(.caption).foregroundColor(.secondary)
                    Text("\(pointCount)点").font(.headline).fontWeight(.bold)
                }
                VStack(alignment: .center) {
                    Text("品質").font(.caption).foregroundColor(.secondary)
                    Text(getDensityEvaluation())
                        .font(.caption).fontWeight(.bold)
                        .foregroundColor(getDensityColor())
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(getDensityColor().opacity(0.2)).cornerRadius(4)
                }
                VStack(alignment: .trailing) {
                    Text("ファイル形式").font(.caption).foregroundColor(.secondary)
                    Text("PLY").font(.headline).fontWeight(.bold)
                }
                if let fileSize = getFileSize() {
                    VStack(alignment: .trailing) {
                        Text("サイズ").font(.caption).foregroundColor(.secondary)
                        Text(fileSize).font(.headline).fontWeight(.bold)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)

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

    private var dataView: some View {
        ScrollView {
            PointCloudDataView(data: pointCloudData, type: .enhanced, pointCount: pointCount)
        }
    }

    private func loadPointCloudData() async {
        do {
            let data = try String(contentsOf: pointCloudURL, encoding: .utf8)
            let (points, colors) = parsePointCloudData(data)
            await MainActor.run {
                self.pointCloudData = data
                self.pointCount = points.count
                self.pointCloudPoints = points
                self.pointCloudColors = colors
            }
        } catch {
            await MainActor.run { self.loadingError = error.localizedDescription }
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
                let c = line.split(separator: " ")
                if c.count >= 6,
                   let x = Float(c[0]),
                   let y = Float(c[1]),
                   let z = Float(c[2]),
                   let r = Int(c[3]),
                   let g = Int(c[4]),
                   let b = Int(c[5]) {
                    points.append(SIMD3<Float>(x, y, z))
                    colors.append(SIMD3<Float>(Float(r)/255.0, Float(g)/255.0, Float(b)/255.0))
                }
            }
        }
        return (points, colors)
    }

    private func getFileSize() -> String? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: pointCloudURL.path)
            if let size = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
        } catch { }
        return nil
    }

    private func getDensityEvaluation() -> String {
        if pointCount >= 500000 { return "超高密度" }
        else if pointCount >= 100000 { return "高密度" }
        else if pointCount >= 50000 { return "標準" }
        else if pointCount >= 10000 { return "低密度" }
        else { return "極低密度" }
    }

    private func getDensityColor() -> Color {
        if pointCount >= 500000 { return .purple }
        else if pointCount >= 100000 { return .green }
        else if pointCount >= 50000 { return .blue }
        else if pointCount >= 10000 { return .orange }
        else { return .red }
    }
}

