import SwiftUI

struct GC_GalleryView: View {
    @EnvironmentObject var appModel: AppDataModel
    @Binding var showCaptureFolders: Bool
    @State private var gridLayout: GridLayout = .three

    // Filters and sort
    @State private var showFilterMenu = false
    @State private var animalFilter: AnimalFilter = .all
    @State private var footprintFilter: FootprintFilter = .all
    @State private var sortOrder: SortOrder = .newest

    enum AnimalFilter: String, CaseIterable {
        case all = "すべて"
        case deer = "シカ"
        case wildBoar = "イノシシ"
        case other = "その他"

        var icon: String {
            switch self {
            case .all: return "すべて"
            case .deer: return "🦌"
            case .wildBoar: return "🐗"
            case .other: return "❓"
            }
        }
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
        case hasModel = "3Dモデルあり"
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
        VStack(spacing: 0) {
            // Batch Processing Status Banner (external component)
            if appModel.batchProcessingStatus != .idle {
                BatchProcessingStatusBanner()
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            if let filtered = filteredAndSortedURLs, !filtered.isEmpty {
                galleryGridView(for: filtered)
            } else {
                EmptyGalleryView()
            }
        }
    }

    @ViewBuilder
    func galleryGridView(for urls: [URL]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(urls, id: \.self) { url in
                    ThumbnailView(captureFolderURL: url, frameSize: itemSize)
                        .id(url.path)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            footerControls
                .padding(.horizontal)
                .padding(.vertical, 12)
        }
    }

    private var footerControls: some View {
        VStack(spacing: 10) {
            HStack {
                Menu {
                    Picker("列数", selection: $gridLayout) {
                        ForEach(GridLayout.allCases, id: \.self) { layout in
                            Text(layout.displayName).tag(layout)
                        }
                    }
                } label: {
                    Label(gridLayout.displayName, systemImage: "rectangle.grid.2x2")
                }

                Spacer()

                Menu {
                    Picker("動物フィルタ", selection: $animalFilter) {
                        ForEach(AnimalFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    Picker("足跡フィルタ", selection: $footprintFilter) {
                        ForEach(FootprintFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    Picker("ソート", selection: $sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                } label: {
                    Label("表示設定", systemImage: "line.3.horizontal.decrease.circle")
                }
            }

            Button("キャンセル") {
                withAnimation(.easeInOut(duration: 0.3)) { showCaptureFolders = false }
            }
            .foregroundColor(.accentColor)
        }
    }

    // MARK: - Computed
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: gridLayout.columnCount)
    }

    var hasActiveFilters: Bool {
        animalFilter != .all || footprintFilter != .all || sortOrder != .newest
    }

    var filteredAndSortedURLs: [URL]? {
        guard let urls = captureFoldersWithImages else { return nil }

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

    var itemSize: CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let padding: CGFloat = 40
        let spacing: CGFloat = 12
        let count = gridLayout.columnCount
        let availableWidth = screenWidth - padding - (spacing * CGFloat(count - 1))
        let itemWidth = availableWidth / CGFloat(count)
        return CGSize(width: itemWidth, height: itemWidth + 70)
    }

    var navigationTitle: String {
        guard let total = captureFoldersWithImages?.count else { return LocalizedString.captures }
        let filtered = filteredAndSortedURLs?.count ?? 0
        if hasActiveFilters && filtered != total {
            return "\(LocalizedString.captures) (\(filtered)/\(total))"
        } else {
            return "\(LocalizedString.captures) (\(total)件)"
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
        guard let topLevelFolder = appModel.captureFolderManager?.appDocumentsFolder else { return nil }
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: topLevelFolder,
                includingPropertiesForKeys: nil,
                options: [])
            return contents.filter { $0.hasDirectoryPath }.sorted { $0.path > $1.path }
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

    private struct LocalizedString {
        static let captures = NSLocalizedString(
            "Captures (Object Capture)",
            bundle: Bundle.main,
            value: "キャプチャ一覧",
            comment: "Title for the folder view.")
    }
}

private struct EmptyGalleryView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.blue.opacity(0.1), Color.green.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 140, height: 140)
                VStack(spacing: 8) {
                    Image(systemName: "camera.circle")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(LinearGradient(colors: [.blue, .green], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.orange.opacity(0.7))
                        .offset(x: 20, y: -10)
                }
            }
            VStack(spacing: 12) {
                Text("まだキャプチャがありません").font(.title2).fontWeight(.semibold)
                VStack(spacing: 8) {
                    Text("動物の痕跡をスキャンして")
                    Text("記録を開始しましょう")
                }
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill").font(.system(size: 16, weight: .medium)).foregroundColor(.yellow)
                    Text("明るい環境で撮影すると質が上がります").font(.subheadline)
                    Spacer()
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.1)))
            }
            .padding(.horizontal)
            Spacer()
        }
        .padding(.bottom, 24)
    }
}

private struct ThumbnailView: View {
    @EnvironmentObject var appModel: AppDataModel
    let captureFolderURL: URL
    let frameSize: CGSize

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                thumbnailImage
                statusBadge
            }
            .frame(width: frameSize.width, height: frameSize.width)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(captureFolderURL.lastPathComponent)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                HStack(spacing: 6) {
                    Image(systemName: "pawprint.fill").font(.system(size: 10)).foregroundColor(.orange)
                    Text(animalTypeText).font(.caption).foregroundColor(.secondary).lineLimit(1)
                    Spacer()
                }
            }
            .frame(width: frameSize.width)
        }
    }

    private var thumbnailImage: some View {
        let imagesFolder = captureFolderURL.appendingPathComponent(CaptureFolderManager.imagesFolderName)
        let firstImage = (try? FileManager.default.contentsOfDirectory(at: imagesFolder, includingPropertiesForKeys: nil))?
            .first { ["jpg","jpeg","png","heic"].contains($0.pathExtension.lowercased()) }
        return Group {
            if let url = firstImage, let data = try? Data(contentsOf: url), let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg).resizable().scaledToFill()
            } else {
                ZStack {
                    Color.gray.opacity(0.1)
                    Image(systemName: "photo").font(.system(size: 24)).foregroundColor(.secondary)
                }
            }
        }
    }

    private var animalTypeText: String {
        if let md = loadMetadata(from: captureFolderURL) { return md.animalType }
        return "-"
    }

    private func loadMetadata(from url: URL) -> TraceMetadata? {
        let path = url.appendingPathComponent("metadata.json")
        guard FileManager.default.fileExists(atPath: path.path), let data = try? Data(contentsOf: path) else { return nil }
        return try? JSONDecoder().decode(TraceMetadata.self, from: data)
    }

    private var statusBadge: some View {
        Group {
            if hasModel(in: captureFolderURL) {
                Text("3D").font(.caption2).padding(6).background(Capsule().fill(Color.green.opacity(0.2))).overlay(Capsule().stroke(Color.green.opacity(0.4))).padding(6)
            } else {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).padding(8)
            }
        }
    }

    private func hasModel(in url: URL) -> Bool {
        let modelsFolder = url.appendingPathComponent("Models")
        guard FileManager.default.fileExists(atPath: modelsFolder.path) else { return false }
        return (try? FileManager.default.contentsOfDirectory(at: modelsFolder, includingPropertiesForKeys: nil))?.contains { $0.pathExtension.lowercased() == "usdz" } ?? false
    }
}
