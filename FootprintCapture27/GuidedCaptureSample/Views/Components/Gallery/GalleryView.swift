import SwiftUI
import ImageIO

struct GC_GalleryView: View {
    @EnvironmentObject var appModel: AppDataModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var gridLayout: GridLayout = UIDevice.current.userInterfaceIdiom == .pad ? .three : .two

    // Filters and sort
    @State private var animalFilter: AnimalFilter = .all
    @State private var footprintFilter: FootprintFilter = .all
    @State private var sortOrder: SortOrder = .newest

    enum AnimalFilter: String, CaseIterable {
        case all = "すべて"
        case deer = "シカ"
        case wildBoar = "イノシシ"
        case other = "その他"


    }

    enum FootprintFilter: String, CaseIterable {
        case all = "すべて"
        case withFootprint = "足跡あり"
        case withoutFootprint = "足跡なし"
    }

    enum SortOrder: String, CaseIterable {
        case newest = "新しい順"
        case oldest = "古い順"
        case animalType = "動物種別"
        case hasModel = "3Dモデルを優先"
    }

    enum GridLayout: CaseIterable {
        case two, three, four

        var columnCount: Int {
            switch self {
            case .two: return 2
            case .three: return 3
            case .four: return UIDevice.current.userInterfaceIdiom == .pad ? 5 : 4
            }
        }

        var displayName: String {
            switch self {
            case .two: return "2列"
            case .three: return "3列"
            case .four: return UIDevice.current.userInterfaceIdiom == .pad ? "5列" : "4列"
            }
        }
    }

    var body: some View {
        let folders = captureFoldersWithImages ?? []
        let matches = filteredAndSortedURLs(folders)
        VStack(spacing: 0) {
            if appModel.batchProcessingStatus != .idle {
                BatchProcessingStatusBanner().padding(.horizontal)
            }
            if !folders.isEmpty {
                HStack {
                    Text(hasActiveFilters ? "全\(folders.count)件中 \(matches.count)件" : "全\(folders.count)件")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    displayOptions
                }
                .padding(.horizontal)
                if hasActiveFilters {
                    Text([animalFilter == .all ? nil : animalFilter.rawValue,
                          footprintFilter == .all ? nil : footprintFilter.rawValue]
                        .compactMap { $0 }.joined(separator: "・"))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                Divider()
            }

            if !matches.isEmpty {
                ScrollView {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                        ForEach(matches, id: \.self) { url in
                            ThumbnailView(captureFolderURL: url)
                        }
                    }
                    .padding(16)
                }
            } else if hasActiveFilters {
                ContentUnavailableView {
                    Label("条件に合う記録がありません", systemImage: "line.3.horizontal.decrease.circle")
                } actions: {
                    Button("絞り込みを解除") {
                        animalFilter = .all
                        footprintFilter = .all
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                ContentUnavailableView {
                    Label("まだ記録がありません", systemImage: "pawprint")
                } description: {
                    Text(appModel.cameraUnavailableMessage.isEmpty
                         ? "撮影した足跡や調査地点がここに並びます。"
                         : "対応する実機で撮影した記録がここに並びます。")
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var displayOptions: some View {
        Menu {
            Menu("動物の種類") {
                Picker("動物の種類", selection: $animalFilter) {
                    ForEach(AnimalFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.inline)
            }
            Menu("足跡の有無") {
                Picker("足跡の有無", selection: $footprintFilter) {
                    ForEach(FootprintFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.inline)
            }
            Menu("並べ替え") {
                Picker("並べ替え", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.inline)
            }
            if !dynamicTypeSize.isAccessibilitySize {
                Menu("列数") {
                    Picker("列数", selection: $gridLayout) {
                        ForEach(GridLayout.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.inline)
                }
            }
        } label: {
            Label("表示設定", systemImage: hasActiveFilters
                  ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .font(.subheadline.weight(.medium))
                .frame(minHeight: 44)
        }
        .accessibilityIdentifier("gallery.options")
    }

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : gridLayout.columnCount
        return Array(repeating: GridItem(.flexible(minimum: 0), spacing: 12, alignment: .top), count: count)
    }

    private var hasActiveFilters: Bool {
        animalFilter != .all || footprintFilter != .all
    }

    private func filteredAndSortedURLs(_ urls: [URL]) -> [URL] {
        // filter
        let filtered = urls.filter { url in
            guard let metadata = loadMetadata(from: url) else {
                return animalFilter == .all && footprintFilter == .all
            }
            switch animalFilter {
            case .all: break
            case .wildBoar:
                if !metadata.animalType.contains("イノシシ") { return false }
            case .deer:
                if !metadata.animalType.contains("シカ") { return false }
            case .other:
                if metadata.animalType.contains("イノシシ") || metadata.animalType.contains("シカ") { return false }
            }
            switch footprintFilter {
            case .all: break
            case .withFootprint:
                if !metadata.hasFootprint { return false }
            case .withoutFootprint:
                if metadata.hasFootprint { return false }
            }
            return true
        }

        // sort
        return filtered.sorted { url1, url2 in
            switch sortOrder {
            case .newest:
                return url1.path > url2.path
            case .oldest:
                return url1.path < url2.path
            case .animalType:
                let t1 = loadMetadata(from: url1)?.animalType ?? ""
                let t2 = loadMetadata(from: url2)?.animalType ?? ""
                return t1 < t2
            case .hasModel:
                let m1 = hasModel(in: url1)
                let m2 = hasModel(in: url2)
                if m1 != m2 { return m1 && !m2 }
                return url1.path > url2.path
            }
        }
    }

    var captureFoldersWithImages: [URL]? {
        guard let allFolders = captureFolderURLs else { return nil }
        return allFolders.filter { folderURL in
            let imageFolderURL = folderURL.appendingPathComponent(CaptureFolderManager.imagesFolderName)
            guard let imageURLs = try? FileManager.default.contentsOfDirectory(
                at: imageFolderURL,
                includingPropertiesForKeys: nil,
                options: []
            ) else { return false }
            let imageFiles = imageURLs.filter { url in
                let ext = url.pathExtension.lowercased()
                return ["jpg","jpeg","png","heic"].contains(ext)
            }
            return !imageFiles.isEmpty
        }
    }

    var captureFolderURLs: [URL]? {
        let topLevelFolder = URL.documentsDirectory
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: topLevelFolder,
                includingPropertiesForKeys: nil,
                options: [])
            return contents.filter { url in
                var isDirectory: ObjCBool = false
                return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                    && isDirectory.boolValue
            }.sorted { $0.path > $1.path }
        } catch {
            return nil
        }
    }

    // MARK: - Helpers
    private func loadMetadata(from url: URL) -> TraceMetadata? {
        let metadataURL = url.appendingPathComponent("metadata.json")
        guard FileManager.default.fileExists(atPath: metadataURL.path),
              let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode(TraceMetadata.self, from: data) else { return nil }
        return metadata
    }

    private func hasModel(in url: URL) -> Bool {
        let modelsFolder = url.appendingPathComponent("Models")
        guard FileManager.default.fileExists(atPath: modelsFolder.path) else { return false }
        return (try? FileManager.default.contentsOfDirectory(at: modelsFolder, includingPropertiesForKeys: nil))?.contains { $0.pathExtension.lowercased() == "usdz" } ?? false
    }

}

private struct ThumbnailView: View {
    @EnvironmentObject var appModel: AppDataModel
    let captureFolderURL: URL
    @State private var thumbnail: CGImage?
    @State private var showSessionDetail = false
    @State private var refreshID = 0

    var body: some View {
        Button {
            showSessionDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle()
                    .fill(.quaternary)
                    .aspectRatio(1.25, contentMode: .fit)
                    .overlay { thumbnailImage }
                    .clipped()
                    .overlay(alignment: .topTrailing) { statusBadge.id(refreshID) }

                VStack(alignment: .leading, spacing: 4) {
                    Text(animalTypeText)
                        .font(.headline)
                    Text(displayDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("gallery.record.\(captureFolderURL.lastPathComponent)")
        .sheet(isPresented: $showSessionDetail, onDismiss: { refreshID += 1 }) {
            SessionDetailView(
                captureFolderURL: captureFolderURL,
                imageCount: imageCount,
                onModelGenerated: { refreshID += 1 }
            )
            .environmentObject(appModel)
        }
        .task(id: captureFolderURL) {
            let imagesFolder = captureFolderURL.appendingPathComponent(CaptureFolderManager.imagesFolderName)
            let firstImage = (try? FileManager.default.contentsOfDirectory(at: imagesFolder, includingPropertiesForKeys: nil))?
                .filter { ["jpg", "jpeg", "png", "heic"].contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
                .first
            guard let firstImage else { return }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 300
            ]
            if let source = CGImageSourceCreateWithURL(firstImage as CFURL, nil) {
                thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
            }
        }
    }

    private var thumbnailImage: some View {
        return Group {
            if let thumbnail {
                Image(decorative: thumbnail, scale: 1.0).resizable().scaledToFill()
            } else {
                ZStack {
                    Color.gray.opacity(0.1)
                    Image(systemName: "photo").font(.system(size: 24)).foregroundColor(.secondary)
                }
            }
        }
    }

    private var displayDate: String {
        let name = captureFolderURL.lastPathComponent
        let timestamp = String(name.prefix(20))
        guard let date = ISO8601DateFormatter().date(from: timestamp) else { return name }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }

    private var imageCount: Int {
        let imagesFolder = captureFolderURL.appendingPathComponent(CaptureFolderManager.imagesFolderName)
        return (try? FileManager.default.contentsOfDirectory(at: imagesFolder, includingPropertiesForKeys: nil))?
            .filter { ["jpg", "jpeg", "png", "heic"].contains($0.pathExtension.lowercased()) }.count ?? 0
    }

    private var animalTypeText: String {
        if let md = loadMetadata(from: captureFolderURL) {
            return md.hasFootprint ? md.animalType : "足跡なし"
        }
        return "動物未記録"
    }

    private func loadMetadata(from url: URL) -> TraceMetadata? {
        let path = url.appendingPathComponent("metadata.json")
        guard FileManager.default.fileExists(atPath: path.path), let data = try? Data(contentsOf: path) else { return nil }
        return try? JSONDecoder().decode(TraceMetadata.self, from: data)
    }

    private var statusBadge: some View {
        Text(hasModel(in: captureFolderURL) ? "3D" : "写真")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.black.opacity(0.75), in: Capsule())
            .padding(6)
    }

    private func hasModel(in url: URL) -> Bool {
        let modelsFolder = url.appendingPathComponent("Models")
        guard FileManager.default.fileExists(atPath: modelsFolder.path) else { return false }
        return (try? FileManager.default.contentsOfDirectory(at: modelsFolder, includingPropertiesForKeys: nil))?.contains { $0.pathExtension.lowercased() == "usdz" } ?? false
    }
}
