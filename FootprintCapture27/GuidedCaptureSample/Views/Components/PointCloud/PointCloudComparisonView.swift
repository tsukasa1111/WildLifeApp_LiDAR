import SwiftUI

struct PointCloudComparisonView: View {
    let captureFolderURL: URL
    @State var selectedType: PointCloudType
    let availableTypes: [PointCloudType]
    @Environment(\.dismiss) private var dismiss
    @State private var pointCloudData: [PointCloudType: String] = [:]
    @State private var pointCounts: [PointCloudType: Int] = [:]
    @State private var fileSizes: [PointCloudType: Int64] = [:]
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if availableTypes.count > 1 {
                    VStack(spacing: 12) {
                        Text("🔬 点群データ比較").font(.title2).fontWeight(.bold)
                        Picker("点群タイプ", selection: $selectedType) {
                            ForEach(availableTypes, id: \.rawValue) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        if pointCounts.count > 1 {
                            HStack(spacing: 20) {
                                ForEach(availableTypes, id: \.rawValue) { type in
                                    VStack(spacing: 4) {
                                        Text(type == .standard ? "📊" : "🚀").font(.title2)
                                        Text("\(pointCounts[type] ?? 0)").font(.headline).fontWeight(.bold)
                                        Text("points").font(.caption).foregroundColor(.secondary)
                                        if let size = fileSizes[type] {
                                            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)).font(.caption2).foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(8)
                                    .background(type == selectedType ? Color.blue.opacity(0.1) : Color.clear)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGroupedBackground))
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isLoading {
                            ProgressView("読み込み中...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let data = pointCloudData[selectedType] {
                            PointCloudDataView(data: data, type: selectedType, pointCount: pointCounts[selectedType] ?? 0)
                        } else {
                            Text("データが読み込めませんでした").foregroundColor(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("点群データ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("閉じる") { dismiss() } } }
        }
        .task { await loadAllPointCloudData() }
        .onChange(of: selectedType) { _, _ in Task { if pointCloudData[selectedType] == nil { await loadPointCloudData(for: selectedType) } } }
    }

    private func loadAllPointCloudData() async {
        isLoading = true
        for type in availableTypes { await loadPointCloudData(for: type) }
        isLoading = false
    }

    private func loadPointCloudData(for type: PointCloudType) async {
        let url = captureFolderURL.appendingPathComponent(type.rawValue)
        do {
            let data = try String(contentsOf: url)
            let lines = data.components(separatedBy: .newlines)
            let pointCount = lines.filter { !$0.isEmpty && !$0.hasPrefix("ply") && !$0.hasPrefix("format") && !$0.hasPrefix("comment") && !$0.hasPrefix("element") && !$0.hasPrefix("property") && !$0.hasPrefix("end_header") }.count
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            await MainActor.run {
                pointCloudData[type] = data
                pointCounts[type] = pointCount
                fileSizes[type] = fileSize
            }
        } catch {
            print("Failed to load point cloud data for \(type): \(error)")
        }
    }
}
