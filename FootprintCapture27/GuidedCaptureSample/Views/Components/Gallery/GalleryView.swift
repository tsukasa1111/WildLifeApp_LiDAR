import SwiftUI
import ImageIO

struct GC_GalleryView: View {
    @EnvironmentObject var appModel: AppDataModel
    @Binding var showCaptureFolders: Bool
    var showsCloseButton = true
    @State private var gridLayout: GridLayout = UIDevice.current.userInterfaceIdiom == .pad ? .three : .two

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
                EmptyGalleryView(
                    hasCaptures: !(captureFoldersWithImages?.isEmpty ?? true),
                    canCapture: appModel.cameraUnavailableMessage.isEmpty
                )
            }

            if showsCloseButton {
                Button("閉じる") {
                    withAnimation(.easeInOut(duration: 0.3)) { showCaptureFolders = false }
                }
                .padding(12)
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

    private struct LocalizedString {
        static let captures = NSLocalizedString(
            "Captures (Object Capture)",
            bundle: Bundle.main,
            value: "キャプチャ一覧",
            comment: "Title for the folder view.")
    }
}

private struct EmptyGalleryView: View {
    let hasCaptures: Bool
    let canCapture: Bool

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
                Text(hasCaptures ? "条件に合うキャプチャはありません" : "まだキャプチャがありません")
                    .font(.title2).fontWeight(.semibold)
                VStack(spacing: 8) {
                    if hasCaptures {
                        Text("表示設定を変更して確認してください")
                    } else if canCapture {
                        Text("動物の痕跡を撮影して記録を開始しましょう")
                    } else {
                        Text("対応する実機で撮影すると、ここに記録が表示されます")
                    }
                }
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            if canCapture && !hasCaptures {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill").font(.system(size: 16, weight: .medium)).foregroundColor(.yellow)
                    Text("明るい環境で撮影すると質が上がります").font(.subheadline)
                    Spacer()
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.1)))
                .padding(.horizontal)
            }
            Spacer()
        }
        .padding(.bottom, 24)
    }
}

private struct ThumbnailView: View {
    @EnvironmentObject var appModel: AppDataModel
    let captureFolderURL: URL
    let frameSize: CGSize
    @State private var thumbnail: CGImage?
    @State private var showSessionDetail = false
    @State private var refreshID = 0

    var body: some View {
        Button {
            showSessionDetail = true
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    thumbnailImage
                    statusBadge.id(refreshID)
                }
                .frame(width: frameSize.width, height: frameSize.width)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayDate)
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
        .buttonStyle(.plain)
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
                Text("写真").font(.caption2).padding(6).background(Capsule().fill(Color.blue.opacity(0.2))).padding(6)
            }
        }
    }

    private func hasModel(in url: URL) -> Bool {
        let modelsFolder = url.appendingPathComponent("Models")
        guard FileManager.default.fileExists(atPath: modelsFolder.path) else { return false }
        return (try? FileManager.default.contentsOfDirectory(at: modelsFolder, includingPropertiesForKeys: nil))?.contains { $0.pathExtension.lowercased() == "usdz" } ?? false
    }
}
