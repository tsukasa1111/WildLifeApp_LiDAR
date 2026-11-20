/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Top overlay button implementation for the capture overlay view.
*/

import RealityKit
import SwiftUI
import Combine
import os
import QuickLook
import CoreLocation
import MapKit

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "TopOverlayButtons")

// 🔬 点群タイプ定義
enum PointCloudType: String, CaseIterable {
    case standard = "standard_pointcloud.ply"
    case enhanced = "ultra_high_density_pointcloud.ply"
    case research = "research_grade_pointcloud.ply"
    case traditional = "traditional_pointcloud.ply"
    
    var displayName: String {
        switch self {
        case .standard:
            return "旧形式: 標準"
        case .enhanced:
            return "写真から再構成した点群"
        case .research:
            return "旧形式: 詳細"
        case .traditional:
            return "旧形式: 従来"
        }
    }
    
    var description: String {
        switch self {
        case .standard:
            return "過去版で保存した位置・色情報"
        case .enhanced:
            return "PhotogrammetrySessionが出力した点群"
        case .research:
            return "過去版で保存した追加属性付きデータ"
        case .traditional:
            return "過去版で保存した点群"
        }
    }
    
    var color: Color {
        switch self {
        case .standard:
            return .green
        case .enhanced:
            return .blue
        case .research:
            return .purple
        case .traditional:
            return .orange
        }
    }
}

struct TopOverlayButtons: View, OverlayButtons {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession
    var showCaptureModeGuidance: Bool
    @State private var showCaptureFolders: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TopOverlayActionBarLeft(
                session: session,
                showCaptureFolders: $showCaptureFolders,
                showCaptureFolderButton: !isCapturingStarted(state: session.state)
            )
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .top)

            if session.state == .ready, showCaptureModeGuidance {
                CaptureModeGuidanceView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showCaptureFolders) {
            GalleryStandaloneView()
                .environmentObject(appModel)
        }
        .onChange(of: showCaptureFolders) { _, showing in
            appModel.setShowOverlaySheets(to: showing)
        }
    }
}

/* private struct CaptureCancelButton: View {
    @EnvironmentObject var appModel: AppDataModel

    var body: some View {
        Button(action: {
            logger.log("\(LocalizedString.cancel) button clicked!")
            if let session = appModel.objectCaptureSession,
               session.state != .completed {
                switch session.state {
                case .failed(_):
                    break // Already failed, don't cancel
                default:
                    session.cancel()
                }
            }
            appModel.removeCaptureFolder()
        }, label: {
            Text(LocalizedString.cancel)
                .modifier(VisualEffectRoundedCorner())
        })
    }

    struct LocalizedString {
        static let cancel = NSLocalizedString(
            "Cancel (Object Capture)",
            bundle: Bundle.main,
            value: "キャンセル",
            comment: "Title for the Cancel button on the object capture screen.")
    }
} */

/* private struct NextButton: View {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession
    @State private var showOnboardingView: Bool = false

    var body: some View {
        Button(action: {
            logger.log("\(LocalizedString.next) button clicked!")
            showOnboardingView = true
        },
               label: {
            Text(appModel.captureMode == .object ? LocalizedString.next : LocalizedString.done)
                .modifier(VisualEffectRoundedCorner())
        })
        .sheet(isPresented: $showOnboardingView) {
            if let onboardingState = appModel.determineCurrentOnboardingState() {
                OnboardingView(state: onboardingState,
                               showOnboardingView: $showOnboardingView)
                .interactiveDismissDisabled()
            }
        }
        .onChange(of: showOnboardingView) {
            appModel.setShowOverlaySheets(to: showOnboardingView)
        }
        .task {
            for await userCompletedScanPass in session.userCompletedScanPassUpdates where userCompletedScanPass {
                logger.log("The scan pass is completed!")
                showOnboardingView = true
            }
        }
    }

    struct LocalizedString {
        static let next = NSLocalizedString(
            "Next (Object Capture)",
            bundle: Bundle.main,
            value: "次へ",
            comment: "Title for the Next button on the object capture screen."
        )

        static let done = NSLocalizedString(
            "Done (Object Capture)",
            bundle: Bundle.main,
            value: "完了",
            comment: "Title for the Done button on the object capture screen."
        )
    }
} */

/* private struct CaptureFolderButton: View {
    @EnvironmentObject var appModel: AppDataModel
    @State private var showCaptureFolders: Bool = false

    var body: some View {
        Button(action: {
            logger.log("Capture folder button clicked!")
            showCaptureFolders = true
        }, label: {
            ZStack {
                // Glass background effect
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial.opacity(0.6))
                    .environment(\.colorScheme, .dark)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                
                Image(systemName: "folder")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        })
        .sheet(isPresented: $showCaptureFolders) {
            GC_GalleryView(showCaptureFolders: $showCaptureFolders)
        }
        .onChange(of: showCaptureFolders) {
            appModel.setShowOverlaySheets(to: showCaptureFolders)
        }
    }
} */

// Moved to Views/Components/CaptureModeGuidanceView.swift

// Removed unused VisualEffectRoundedCorner (was used by removed buttons)

/* Moved to Views/Components/Gallery/GalleryView.swift
private struct GalleryView: View {
    @EnvironmentObject var appModel: AppDataModel
    @Binding var showCaptureFolders: Bool
    @State private var gridLayout: GridLayout = .three
    
    // フィルタとソート用の状態
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
        
        var icon: String {
            switch self {
            case .all: return "🔍"
            case .withFootprint: return "🐾"
            case .withoutFootprint: return "❌"
            }
        }
    }
    
    enum SortOrder: String, CaseIterable {
        case newest = "新しい順"
        case oldest = "古い順"
        case animalType = "動物種別"
        case hasModel = "3Dモデル有無"
        
        var systemImage: String {
            switch self {
            case .newest: return "arrow.down"
            case .oldest: return "arrow.up"
            case .animalType: return "leaf"
            case .hasModel: return "cube"
            }
        }
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
    
    @ViewBuilder
    var mainContent: some View {
        VStack(spacing: 0) {
            // Batch Processing Status Banner
            if appModel.batchProcessingStatus != .idle {
                BatchProcessingStatusBanner()
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            
            if let filteredURLs = filteredAndSortedURLs, !filteredURLs.isEmpty {
                galleryGridView(for: filteredURLs)
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
                        .id(url.path) // 安定したIDでビューの再利用を改善
                }
            }
            .padding(.horizontal, 16)
            .animation(.easeInOut(duration: 0.2), value: gridLayout)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        leadingToolbarContent
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        trailingToolbarContent
                    }
                }
        }
        .onAppear {
            // ギャラリー表示時はカメラを停止してパフォーマンス向上
            appModel.pauseCameraSession()
        }
        .onDisappear {
            // ギャラリーを閉じる時はカメラを再開
            appModel.resumeCameraSession()
        }
    }
    
    @ViewBuilder
    var leadingToolbarContent: some View {
        HStack {
            gridLayoutMenu
            filterMenu
        }
    }
    
    @ViewBuilder
    var gridLayoutMenu: some View {
        Menu(content: {
            ForEach(GridLayout.allCases, id: \.self) { layout in
                Button(layout.displayName) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        gridLayout = layout
                    }
                }
            }
        }, label: {
            Image(systemName: "rectangle.grid.2x2")
                .foregroundColor(.accentColor)
        })
    }
    
    @ViewBuilder
    var filterMenu: some View {
        Menu {
            // フィルタクリアボタン
            if hasActiveFilters {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        animalFilter = .all
                        footprintFilter = .all
                        sortOrder = .newest
                    }
                }) {
                    HStack {
                        Image(systemName: "clear")
                        Text("フィルタをクリア")
                    }
                }
                .foregroundColor(.red)
                
                Divider()
            }
            
            // 動物の種類
            ForEach(AnimalFilter.allCases, id: \.self) { filter in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        animalFilter = filter
                    }
                }) {
                    HStack {
                        Text(filter.icon)
                        Text(filter.rawValue)
                        if animalFilter == filter {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            Divider()
            
            // 足跡フィルタ
            ForEach(FootprintFilter.allCases, id: \.self) { filter in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        footprintFilter = filter
                    }
                }) {
                    HStack {
                        Text(filter.icon)
                        Text(filter.rawValue)
                        if footprintFilter == filter {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            Divider()
            
            // 並べ替え
            ForEach(SortOrder.allCases, id: \.self) { order in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        sortOrder = order
                    }
                }) {
                    HStack {
                        Image(systemName: order.systemImage)
                        Text(order.rawValue)
                        if sortOrder == order {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundColor(hasActiveFilters ? .blue : .accentColor)
        }
    }
    
    @ViewBuilder
    var trailingToolbarContent: some View {
        HStack {
            // Batch Processing Button
            Button(action: {
                if appModel.batchProcessingStatus != .idle {
                    cancelBatchProcessing()
                } else {
                    startBatchProcessing()
                }
            }) {
                Group {
                    switch appModel.batchProcessingStatus {
                    case .idle:
                        Image(systemName: "moon.stars.fill")
                            .foregroundColor(.purple)
                    case .processing(_, _, _):
                        Image(systemName: "stop.circle.fill")
                            .foregroundColor(.red)
                    case .completed(_):
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    case .failed(_):
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Button(LocalizedString.cancel) {
                logger.log("The cancel button in gallery view clicked!")
                withAnimation(.easeInOut(duration: 0.3)) {
                    showCaptureFolders = false
                }
            }
            .foregroundColor(.accentColor)
        }
    }
    
    // MARK: - Computed Properties
    var columns: [GridItem] {
        let count = gridLayout.columnCount
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }
    
    var hasActiveFilters: Bool {
        animalFilter != .all || footprintFilter != .all || sortOrder != .newest
    }
    
    var filteredAndSortedURLs: [URL]? {
        guard let urls = captureFoldersWithImages else { return nil }
        
        // フィルタリング
        let filtered = urls.filter { url in
            guard let metadata = loadMetadata(from: url) else {
                // メタデータがない場合は表示する（後方互換性）
                return animalFilter == .all && footprintFilter == .all
            }
            
            // 動物種別でフィルタ
            switch animalFilter {
            case .all:
                break
            case .wildBoar:
                if !metadata.animalType.contains("イノシシ") { return false }
            case .deer:
                if !metadata.animalType.contains("シカ") { return false }
            case .other:
                if metadata.animalType.contains("イノシシ") || metadata.animalType.contains("シカ") { return false }
            }
            
            // 足跡でフィルタ
            switch footprintFilter {
            case .all:
                break
            case .withFootprint:
                if !metadata.hasFootprint { return false }
            case .withoutFootprint:
                if metadata.hasFootprint { return false }
            }
            
            return true
        }
        
        // ソート
        return filtered.sorted { url1, url2 in
            switch sortOrder {
            case .newest:
                return url1.path > url2.path // ファイル名ベースの新しい順
            case .oldest:
                return url1.path < url2.path // ファイル名ベースの古い順
            case .animalType:
                let type1 = loadMetadata(from: url1)?.animalType ?? ""
                let type2 = loadMetadata(from: url2)?.animalType ?? ""
                return type1 < type2
            case .hasModel:
                let hasModel1 = hasModel(in: url1)
                let hasModel2 = hasModel(in: url2)
                if hasModel1 != hasModel2 {
                    return hasModel1 && !hasModel2 // モデルありを先に
                }
                return url1.path > url2.path // 同じ場合は新しい順
            }
        }
    }
    
    var itemSize: CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let padding: CGFloat = 40 // Total horizontal padding
        let spacing: CGFloat = 12 // Spacing between items
        let columnsCount = gridLayout.columnCount
        
        let availableWidth = screenWidth - padding - (spacing * CGFloat(columnsCount - 1))
        let itemWidth = availableWidth / CGFloat(columnsCount)
        
        return CGSize(width: itemWidth, height: itemWidth + 70)
    }
    
    var navigationTitle: String {
        guard let totalCount = captureFoldersWithImages?.count else {
            print("DEBUG: navigationTitle - No captureFoldersWithImages")
            return LocalizedString.captures
        }
        
        let filteredCount = filteredAndSortedURLs?.count ?? 0
        print("DEBUG: navigationTitle - totalCount: \(totalCount), filteredCount: \(filteredCount), hasActiveFilters: \(hasActiveFilters)")
        
        if hasActiveFilters && filteredCount != totalCount {
            return "\(LocalizedString.captures) (\(filteredCount)/\(totalCount))"
        } else {
            return "\(LocalizedString.captures) (\(totalCount)件)"
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
            ) else {
                return false
            }
            
            let imageFiles = imageURLs.filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "heic"
            }
            
            return !imageFiles.isEmpty
        }
    }

    var captureFolderURLs: [URL]? {
        guard let topLevelFolder = appModel.captureFolderManager?.appDocumentsFolder else { 
            print("DEBUG: No app documents folder")
            return nil 
        }
        print("DEBUG: App documents folder: \(topLevelFolder.path)")
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: topLevelFolder,
                includingPropertiesForKeys: nil,
                options: [])
            print("DEBUG: Documents folder contents: \(contents.map { $0.lastPathComponent })")
            
            let folderURLs = contents
                .filter { $0.hasDirectoryPath }
                .sorted(by: { $0.path > $1.path })
            print("DEBUG: Filtered capture folders: \(folderURLs.map { $0.lastPathComponent })")
            return folderURLs
        } catch {
            print("DEBUG: Error reading documents folder: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadMetadata(from url: URL) -> TraceMetadata? {
        let metadataURL = url.appendingPathComponent("metadata.json")
        guard FileManager.default.fileExists(atPath: metadataURL.path),
              let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode(TraceMetadata.self, from: data) else {
            return nil
        }
        return metadata
    }
    
    private func hasModel(in url: URL) -> Bool {
        let modelsFolder = url.appendingPathComponent("Models")
        guard FileManager.default.fileExists(atPath: modelsFolder.path) else {
            return false
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: modelsFolder, includingPropertiesForKeys: nil)
            return contents.contains { $0.pathExtension.lowercased() == "usdz" }
        } catch {
            return false
        }
    }
    
    // MARK: - Batch Processing
    func startBatchProcessing() {
        logger.log("🌙 Starting batch processing for captures without 3D models")
        
        guard let captureFolderURLs = captureFolderURLs else {
            logger.warning("No capture folders found for batch processing")
            return
        }
        
        // AppDataModelの一括処理メソッドを使用
        appModel.startBatchProcessing(captureFolders: captureFolderURLs)
    }
    
    func cancelBatchProcessing() {
        logger.log("🛑 Cancelling batch processing")
        appModel.cancelBatchProcessing()
    }
}
*/

// MARK: - Batch Processing Status Banner
// Moved to Views/Components/BatchProcessingStatusBanner.swift

// MARK: - Localized Strings
// Removed unused LocalizedString (moved into components where needed)

/* Moved to Views/Components/Gallery/GalleryView.swift
private struct EmptyGalleryView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Enhanced Empty State Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.green.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                VStack(spacing: 8) {
                    Image(systemName: "camera.circle")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .green],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.orange.opacity(0.7))
                        .offset(x: 20, y: -10)
                }
            }
            
            VStack(spacing: 12) {
                Text("まだキャプチャがありません")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    Text("動物の痕跡をスキャンして")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("記録を開始しましょう")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
            }
            
            // Suggestion Card
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.yellow)
                    
                    Text("ヒント")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                Text("撮影ボタンをタップして最初の痕跡をスキャンしてみましょう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
}
*/

/* Moved to Views/Components/Gallery/GalleryView.swift
private struct ThumbnailView: View {
    let captureFolderURL: URL
    let frameSize: CGSize
    @EnvironmentObject var appModel: AppDataModel
    @State private var image: CGImage?
    @State private var showSessionDetail: Bool = false
    @State private var hasModel: Bool = false
    @State private var imageCount: Int = 0
    @State private var footprintMetadata: TraceMetadata?
    
    init(captureFolderURL: URL, frameSize: CGSize) {
        self.captureFolderURL = captureFolderURL
        self.frameSize = frameSize
        
        // Check if any model exists (both model.usdz and model-mobile.usdz)
        let modelsFolder = captureFolderURL.appendingPathComponent("Models")
        let modelExists = hasAnyModel(in: modelsFolder)
        
        self._hasModel = State(initialValue: modelExists)
    }

    var body: some View {
        if let imageURL = getFirstImage(from: captureFolderURL) {
            Button {
                showSessionDetail = true
            } label: {
                VStack(spacing: 0) {
                    // 軽量化された画像コンテナ
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemGray6))
                            .frame(width: frameSize.width, height: frameSize.width)
                        
                        if let image {
                            Image(decorative: image, scale: 1.0)
                                .resizable()
                                .scaledToFill()
                                .frame(width: frameSize.width, height: frameSize.width)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        
                        // Status indicators
                        VStack {
                            HStack {
                                // Footprint indicator (left) - 常に表示
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.secondarySystemBackground))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                                        )
                                    
                                    if let metadata = footprintMetadata, metadata.hasFootprint {
                                        // 足跡あり
                                        Image(systemName: "pawprint.fill")
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color.orange, Color.red],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .font(.system(size: 12, weight: .bold))
                                            .shadow(color: Color.orange.opacity(0.3), radius: 2, x: 0, y: 1)
                                    } else if footprintMetadata != nil {
                                        // 足跡なし（メタデータはある）
                                        Image(systemName: "pawprint")
                                            .foregroundColor(Color(UIColor.systemGray2))
                                            .font(.system(size: 12, weight: .regular))
                                            .opacity(0.6)
                                    } else {
                                        // メタデータなし
                                        Image(systemName: "questionmark")
                                            .foregroundColor(Color(UIColor.systemGray3))
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                }
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                
                                Spacer()
                                
                                // Model/Photo indicator (right)
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.secondarySystemBackground))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                                        )
                                    
                                    ZStack {
                                        if hasModel {
                                            // 3D Model icon with gradient
                                            Image(systemName: "cube.fill")
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [Color.green, Color.mint],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .font(.system(size: 12, weight: .bold))
                                                .shadow(color: Color.green.opacity(0.3), radius: 2, x: 0, y: 1)
                                        } else {
                                            // Photo icon with gradient
                                            Image(systemName: "camera.fill")
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [Color.blue, Color.cyan],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .font(.system(size: 12, weight: .bold))
                                                .shadow(color: Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)
                                        }
                                    }
                                }
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(UIColor.systemGray4), lineWidth: 0.5)
                    )

                    // Enhanced Info section
                    VStack(spacing: 6) {
                        let folderName = captureFolderURL.lastPathComponent
                        
                        // Date/Time
                        Text(formatTimestamp(folderName))
                            .foregroundColor(.primary)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Simplified Stats
                        HStack(spacing: 6) {
                            // Photo count - minimal
                            Text("\(imageCount)")
                                .foregroundColor(.primary)
                                .font(.caption2)
                                .fontWeight(.medium)
                            
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                                .font(.system(size: 10))
                            
                            Spacer()
                            
                            // Enhanced status indicator
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: hasModel ? [Color.green, Color.mint] : [Color.blue, Color.cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 8, height: 8)
                                    .shadow(color: (hasModel ? Color.green : Color.blue).opacity(0.4), radius: 2, x: 0, y: 1)
                                
                                Circle()
                                    .fill(.white.opacity(0.6))
                                    .frame(width: 3, height: 3)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 4)
                }
                .frame(width: frameSize.width, height: frameSize.height)
            }
            .buttonStyle(PlainButtonStyle())
            .task {
                image = await createThumbnail(url: imageURL)
                await MainActor.run {
                    checkModelExists()
                    countImages()
                }
            }
            .onAppear {
                // 足跡表示のため最小限のメタデータ読み込み
                loadFootprintMetadata()
            }
            .sheet(isPresented: $showSessionDetail) {
                SessionDetailView(
                    captureFolderURL: captureFolderURL, 
                    hasModel: hasModel, 
                    imageCount: imageCount,
                    onModelGenerated: {
                        // Update the thumbnail view when model is generated
                        checkModelExists()
                    }
                )
            }
            .onChange(of: showSessionDetail) { _, isShowing in
                if !isShowing {
                    // When　is dismissed, re-check model existence
                    checkModelExists()
                }
            }
            .onChange(of: appModel.lastModelGeneratedURL) { _, newURL in
                // When a model is generated in batch processing, check if it's for this capture
                if let newURL = newURL, newURL == captureFolderURL {
                    logger.log("🔄 Updating UI for generated model: \(captureFolderURL.lastPathComponent)")
                    checkModelExists()
                }
            }
        }
    }

    private nonisolated func createThumbnail(url: URL) async -> CGImage? {
        // サムネイルサイズを最適化（メモリ使用量削減）
        let options = [
            kCGImageSourceThumbnailMaxPixelSize: min(frameSize.width * 1.5, 200),
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary
        
        // 優先度を下げてバックグラウンド処理
        return await Task(priority: .utility) {
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else {
                return nil
            }
            return thumbnail
        }.value
    }

    private func getFirstImage(from url: URL) -> URL? {
        let imageFolderURL = url.appendingPathComponent(CaptureFolderManager.imagesFolderName)
        let imagesURL: URL? = try? FileManager.default.contentsOfDirectory(
            at: imageFolderURL,
            includingPropertiesForKeys: nil,
            options: [])
            .filter { !$0.hasDirectoryPath }
            .sorted(by: { $0.path < $1.path })
            .first
        return imagesURL
    }
    
    private func checkModelExists() {
        let modelsFolder = captureFolderURL.appendingPathComponent("Models")
        hasModel = hasAnyModel(in: modelsFolder)
    }
    
    private func hasAnyModel(in modelsFolder: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: modelsFolder.path) else {
            return false
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: modelsFolder, includingPropertiesForKeys: nil)
            // Look for any .usdz file (model.usdz, model-mobile.usdz, etc.)
            let hasUSDZ = contents.contains { $0.pathExtension.lowercased() == "usdz" }
            return hasUSDZ
        } catch {
            return false
        }
    }
    
    private func loadFootprintMetadata() {
        let metadataURL = captureFolderURL.appendingPathComponent("metadata.json")
        guard let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode(TraceMetadata.self, from: data) else {
            footprintMetadata = nil
            return
        }
        footprintMetadata = metadata
    }
    
    private func countImages() {
        let imageFolderURL = captureFolderURL.appendingPathComponent(CaptureFolderManager.imagesFolderName)
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: imageFolderURL,
                includingPropertiesForKeys: nil,
                options: [])
            imageCount = contents.filter { !$0.hasDirectoryPath }.count
        } catch {
            imageCount = 0
        }
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return timestamp
    }
    
}
*/

struct SessionDetailView: View {
    @EnvironmentObject var appModel: AppDataModel
    @Environment(\.dismiss) private var dismiss
    let captureFolderURL: URL
    @State private var hasModel: Bool
    let imageCount: Int
    let onModelGenerated: (() -> Void)?
    
    @State private var isReconstructing = false
    @State private var reconstructionProgress: Double = 0.0
    @State private var reconstructionError: String?
    @State private var editDraft: TraceMetadata?
    @State private var showModel = false
    @State private var modelURL: URL?
    @State private var thumbnailImage: CGImage?
    @State private var traceMetadata: TraceMetadata?
    @State private var showEditMetadata = false
    @State private var isEditingTitle = false
    @State private var editableTitle = ""
    @State private var hasAnnotatedImage = false
    @State private var showFootprintAnnotation = false
    @State private var selectedImageIndex: Int = 2  // 3枚目をデフォルト（0ベース）
    @State private var availableImages: [URL] = []
    
    init(captureFolderURL: URL, imageCount: Int, onModelGenerated: (() -> Void)? = nil) {
        self.captureFolderURL = captureFolderURL
        self.onModelGenerated = onModelGenerated
        
        // Re-check model existence to ensure accuracy
        let modelsFolder = captureFolderURL.appendingPathComponent("Models")
        let actualHasModel = Self.hasAnyModel(in: modelsFolder)
        
        self._hasModel = State(initialValue: actualHasModel)
        self.imageCount = imageCount
    }
    
    static func hasAnyModel(in modelsFolder: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: modelsFolder.path) else {
            return false
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: modelsFolder, includingPropertiesForKeys: nil)
            let hasUSDZ = contents.contains { $0.pathExtension.lowercased() == "usdz" }
            return hasUSDZ
        } catch {
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    contentSections
                }
            }
            .navigationTitle("キャプチャ詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("編集") { beginEditing() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .sheet(item: $editDraft) { draft in
                MetadataEditor(metadata: draft, onSave: { updated in
                    try saveMetadata(updated)
                    editDraft = nil
                }, onCancel: { editDraft = nil })
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(UIColor.systemBackground),
                Color(UIColor.systemGray6).opacity(0.3)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var heroSection: some View {
        SessionHeroSection(
            thumbnailImage: thumbnailImage,
            hasModel: hasModel,
            isReconstructing: isReconstructing
        )
    }
    
    private var contentSections: some View {
        VStack(spacing: 24) {
            if let metadata = traceMetadata {
                MetadataCard(metadata: metadata)
                    .padding(.horizontal)
                if metadata.hasFootprint && !availableImages.isEmpty {
                    Button("足跡画像を確認") { showFootprintAnnotation = true }
                        .buttonStyle(.bordered)
                }
            } else {
                Button("詳細情報を追加") { beginEditing() }
                    .buttonStyle(.bordered)
            }
            if isReconstructing || reconstructionError != nil {
                StatusCard(
                    hasModel: hasModel,
                    isReconstructing: isReconstructing,
                    reconstructionProgress: reconstructionProgress,
                    reconstructionError: reconstructionError
                )
                .padding(.horizontal)
            }

            ActionButtonsSection(
                hasModel: hasModel,
                isReconstructing: isReconstructing,
                modelURL: modelURL,
                captureFolderURL: captureFolderURL,
                showModel: $showModel,
                onGenerateModel: {
                    startReconstruction()
                }
            )
            .padding(.horizontal)
            
            // 3. Location Information (位置情報 - 最下部)
            locationInfoSection
                .padding(.horizontal)
            
            Spacer(minLength: 20)
        }
        .onAppear {
            loadThumbnail()
            loadMetadata()
            checkForExistingModel()
            checkForAnnotatedImage()
            loadAvailableImages()
        }
        .sheet(isPresented: $showFootprintAnnotation) {
            if let manager = try? CaptureFolderManager(existingFolder: captureFolderURL) {
                GC_FootprintConfirmationView(
                    availableImages: availableImages,
                    initialSelectedIndex: selectedImageIndex,
                    captureFolderManager: manager,
                    onDismiss: {
                        showFootprintAnnotation = false
                        checkForAnnotatedImage()
                    }
                )
            } else {
                Text("キャプチャフォルダを開けませんでした")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadThumbnail() {
        guard let imageURL = getFirstImage(from: captureFolderURL) else { return }
        
        Task {
            if let thumbnail = await createThumbnail(url: imageURL) {
                await MainActor.run {
                    self.thumbnailImage = thumbnail
                }
            }
        }
    }
    
    private func loadAvailableImages() {
        let imageFolderURL = captureFolderURL.appendingPathComponent(CaptureFolderManager.imagesFolderName)
        
        do {
            let imageFiles = try FileManager.default.contentsOfDirectory(
                at: imageFolderURL,
                includingPropertiesForKeys: nil,
                options: []
            )
            .filter { !$0.hasDirectoryPath }
            .filter { ["jpg", "jpeg", "heic", "png"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            
            availableImages = imageFiles
            if selectedImageIndex >= imageFiles.count {
                selectedImageIndex = max(0, imageFiles.count - 1)
            }
        } catch {
            logger.error("Failed to load available images: \(error)")
            availableImages = []
        }
    }
    
    private func getSelectedImage() -> UIImage? {
        guard selectedImageIndex < availableImages.count else {
            logger.error("Selected image index out of bounds")
            return nil
        }
        
        let imageURL = availableImages[selectedImageIndex]
        
        guard let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            logger.error("Failed to load image at index \(selectedImageIndex)")
            return nil
        }
        
        return image
    }
    
    private func checkForExistingModel() {
        let modelsFolder = captureFolderURL.appendingPathComponent("Models")
        
        guard FileManager.default.fileExists(atPath: modelsFolder.path) else {
            return
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: modelsFolder, includingPropertiesForKeys: nil)
            
            // Look for USDZ files
            for file in contents {
                if file.pathExtension.lowercased() == "usdz" {
                    modelURL = file
                    break
                }
            }
        } catch {
            logger.error("Error checking for existing models: \(error)")
        }
    }
    
    private func checkForAnnotatedImage() {
        let annotatedImageURL = captureFolderURL.appendingPathComponent("annotated_footprints.jpg")
        hasAnnotatedImage = FileManager.default.fileExists(atPath: annotatedImageURL.path)
        logger.log("Annotated image exists: \(hasAnnotatedImage)")
    }
    
    private func getAnnotatedImageURL() -> URL? {
        return captureFolderURL.appendingPathComponent("annotated_footprints.jpg")
    }
    
    private func startReconstruction() {
        isReconstructing = true
        reconstructionProgress = 0.0
        reconstructionError = nil
        
        Task {
            do {
                // 🚀 研究グレード超高密度点群生成設定 - 最高品質モード
                var configuration = PhotogrammetrySession.Configuration()
                
                // 🎯 動作確認済みの安定設定（キャプチャ一覧から）
                configuration.isObjectMaskingEnabled = false
                configuration.sampleOrdering = .unordered
                configuration.featureSensitivity = .high
                // Note: sampleOverlap not available in current iOS version
                
                // 🔬 詳細レベル設定 - 最大密度
                configuration.checkpointDirectory = captureFolderURL.appendingPathComponent("Checkpoint")
                
                print("🚀 STABLE Configuration:")
                print("  - Feature Sensitivity: HIGH")
                print("  - Sample Ordering: UNORDERED (proven stable)")
                print("  - Object Masking: DISABLED")
                print("  - Checkpoint: ENABLED")
                
                logger.log("🚀 MAXIMUM QUALITY MODE: Ultra-high density point cloud generation (from capture list)")
                logger.log("📊 Target: 100K+ points for exceptional detail")
                
                let photogrammetrySession = try PhotogrammetrySession(
                    input: captureFolderURL.appendingPathComponent(CaptureFolderManager.imagesFolderName),
                    configuration: configuration
                )
                
                // Create models directory
                let modelsFolder = captureFolderURL.appendingPathComponent("Models")
                try FileManager.default.createDirectory(at: modelsFolder, withIntermediateDirectories: true)
                
                // Set up output files - 撮影後と同じファイル名
                let modelFile = modelsFolder.appendingPathComponent("model-mobile.usdz")
                
                // 撮影後と同じリクエスト作成
                let pointCloudRequest = PhotogrammetrySession.Request.pointCloud
                let modelRequest = PhotogrammetrySession.Request.modelFile(url: modelFile)
                
                // 撮影後と同じ順序で処理
                try photogrammetrySession.process(requests: [pointCloudRequest, modelRequest])
                
                // Handle outputs - 撮影後と同じ処理
                var hasReconstructionError = false
                let outputs = UntilProcessingCompleteFilter(input: photogrammetrySession.outputs)
                for await output in outputs {
                    switch output {
                        case .inputComplete:
                            break
                        case .requestProgress(let request, fractionComplete: let fractionComplete):
                            if case .modelFile = request {
                                await MainActor.run {
                                    self.reconstructionProgress = fractionComplete
                                }
                            }
                        case .requestProgressInfo(_, _):
                            // プログレス詳細情報は無視（シンプルに）
                            break
                        case .requestComplete(let request, let result):
                            switch request {
                                case .modelFile:
                                    logger.log("RequestComplete: .modelFile")
                                    await MainActor.run {
                                        self.modelURL = modelFile
                                        self.hasModel = true
                                        logger.log("Model generated at: \(modelFile.path)")
                                    }
                                case .pointCloud:
                                    logger.log("RequestComplete: .pointCloud")
                                    if case .pointCloud(let pointCloud) = result {
                                        try PointCloudStorage.save(
                                            pointCloud,
                                            to: captureFolderURL.appendingPathComponent(CaptureFolderManager.pointCloudFileName)
                                        )
                                        logger.log("Saved \(pointCloud.points.count) reconstructed points")
                                    }
                                case .modelEntity(_, _), .bounds, .poses:
                                    // Not supported yet
                                    break
                                @unknown default:
                                    logger.warning("Received an output for an unknown request: \(String(describing: request))")
                            }
                        case .requestError(_, let requestError):
                            hasReconstructionError = true
                            await MainActor.run {
                                self.isReconstructing = false
                                let detailedError = "3Dモデル生成エラー: \(requestError.localizedDescription)\n\n考えられる原因:\n• 画像品質が不十分\n• 画像数が少ない(推奨: 50+枚)\n• 重複度が低い\n• 照明条件が悪い"
                                self.reconstructionError = detailedError
                                logger.error("Request failed: \(requestError)")
                                logger.error("Detailed error info: \(requestError)")
                            }
                        case .processingComplete:
                            await MainActor.run {
                                self.isReconstructing = false
                                if !hasReconstructionError && FileManager.default.fileExists(atPath: modelFile.path) {
                                    self.reconstructionProgress = 1.0
                                    onModelGenerated?()
                                } else if !hasReconstructionError {
                                    self.reconstructionError = "3Dモデルの出力ファイルが見つかりません"
                                }
                            }
                        case .processingCancelled:
                            await MainActor.run {
                                self.isReconstructing = false
                                self.reconstructionError = "処理がキャンセルされました"
                            }
                        case .invalidSample(id: _, reason: _), .skippedSample(id: _), .automaticDownsampling:
                            continue
                        case .stitchingIncomplete:
                            logger.log("stitchingIncomplete")
                        @unknown default:
                            logger.warning("Received an unknown output: \(String(describing: output))")
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.isReconstructing = false
                    self.reconstructionError = error.localizedDescription
                    logger.error("Reconstruction failed: \(error)")
                }
            }
        }
    }
    
    private func beginEditing() {
        if let traceMetadata {
            editDraft = traceMetadata
        } else {
            let (timestamp, location) = getBasicInfo()
            editDraft = TraceMetadata(hasFootprint: true, animalType: "", traceType: "足跡",
                                      location: location, timestamp: timestamp ?? Date())
        }
    }

    private func saveMetadata(_ metadata: TraceMetadata) throws {
        let url = captureFolderURL.appendingPathComponent("metadata.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        try encoder.encode(metadata).write(to: url, options: .atomic)
        traceMetadata = metadata
    }

    private func getFirstImage(from url: URL) -> URL? {
        let imageFolderURL = url.appendingPathComponent(CaptureFolderManager.imagesFolderName)
        let imagesURL: URL? = try? FileManager.default.contentsOfDirectory(
            at: imageFolderURL,
            includingPropertiesForKeys: nil,
            options: []
        )
        .filter { ["jpg", "jpeg", "png", "heic"].contains($0.pathExtension.lowercased()) }
        .sorted(by: { $0.path < $1.path })
        .first
        return imagesURL
    }
    
    private nonisolated func createThumbnail(url: URL) async -> CGImage? {
        let options = [
            kCGImageSourceThumbnailMaxPixelSize: 1200,
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else {
            return nil
        }
        return thumbnail
    }
    
    private func loadMetadata() {
        let metadataFile = captureFolderURL.appendingPathComponent("metadata.json")
        
        guard FileManager.default.fileExists(atPath: metadataFile.path) else {
            logger.log("No metadata file found at: \(metadataFile.path)")
            return
        }
        
        do {
            let data = try Data(contentsOf: metadataFile)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder -> Date in
                let c = try decoder.singleValueContainer()
                // 1) ISO-8601 文字列
                if let str = try? c.decode(String.self),
                   let d  = ISO8601DateFormatter().date(from: str) {
                   return d
                 }
                 // 2) Unix 秒(Double)
                 if let secs = try? c.decode(Double.self) {
                     return Date(timeIntervalSince1970: secs)
                 }
                 throw DecodingError.dataCorruptedError(
                     in: c, debugDescription: "Unsupported date format")
            }
            let metadata = try decoder.decode(TraceMetadata.self, from: data)
            self.traceMetadata = metadata
            logger.log("Loaded metadata: \(metadata.animalType) - \(metadata.traceType)")
        } catch {
            logger.error("Failed to load metadata: \(error)")
        }
    }
    
    private func getBasicInfo() -> (timestamp: Date?, location: CLLocation?) {
        // Try to get info from metadata first
        if let metadata = traceMetadata {
            return (metadata.timestamp, metadata.location)
        }
        
        // Fallback to folder creation date and check for location
        let timestamp = getFolderCreationDate()
        let location = getLocationFromFolder()
        
        return (timestamp, location)
    }
    
    private func getFolderCreationDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: String(captureFolderURL.lastPathComponent.prefix(20)))
    }
    
    private func getLocationFromFolder() -> CLLocation? {
        // Check if there's location info saved separately
        let locationFile = captureFolderURL.appendingPathComponent("scan_location.json")
        guard FileManager.default.fileExists(atPath: locationFile.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: locationFile)
            guard let locationData = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let latitude = locationData["latitude"] as? Double,
                  let longitude = locationData["longitude"] as? Double else {
                return nil
            }
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let altitude = locationData["altitude"] as? Double ?? 0
            let horizontalAccuracy = locationData["horizontalAccuracy"] as? Double ?? 0
            let verticalAccuracy = locationData["verticalAccuracy"] as? Double ?? 0
            let timestamp = locationData["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970
            
            return CLLocation(
                coordinate: coordinate,
                altitude: altitude,
                horizontalAccuracy: horizontalAccuracy,
                verticalAccuracy: verticalAccuracy,
                timestamp: Date(timeIntervalSince1970: timestamp)
            )
        } catch {
            return nil
        }
    }
    
    private enum CaptureMode {
        case object
        case area
    }
    
    private func readSavedCaptureMode() -> CaptureMode {
        let captureModeFile = captureFolderURL.appendingPathComponent("capture_mode.txt")
        
        if let savedModeString = try? String(contentsOf: captureModeFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) {
            if savedModeString == "area" {
                return .area
            }
        }
        
        // Default to object mode if no file exists or can't be read
        return .object
    }
    
    // MARK: - Location Info Section
    
    private var locationInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("位置情報", systemImage: "location.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                Text("(自動取得)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // Try to get location from metadata first, then from saved location
            let (_, location) = getBasicInfo()
            if let location = location {
                VStack(alignment: .leading, spacing: 12) {
                    // Coordinates Info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("緯度:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .leading)
                            Text("\(location.coordinate.latitude, specifier: "%.6f")")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        HStack {
                            Text("経度:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .leading)
                            Text("\(location.coordinate.longitude, specifier: "%.6f")")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        if location.horizontalAccuracy >= 0 {
                            HStack {
                                Text("精度:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .leading)
                                Text("±\(Int(location.horizontalAccuracy))m")
                                    .font(.caption)
                                    .foregroundColor(location.horizontalAccuracy < 10 ? .green : location.horizontalAccuracy < 50 ? .orange : .red)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                    }
                    
                    // Embedded Map
                    LocationMapView(location: location)
                        .frame(height: 150)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(UIColor.separator), lineWidth: 1)
                        )
                }
                .padding(12)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "location.slash.fill")
                            .foregroundColor(.orange)
                        Text("位置情報が取得できませんでした")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    Text("スキャン開始時に位置情報サービスをONにしてください")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Supporting Components

/* private struct StatusBadge: View {
    let hasModel: Bool
    let isReconstructing: Bool
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(backgroundColor)
                .frame(width: 100, height: 32)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
    }
    
    private var backgroundColor: Color {
        if isReconstructing {
            return Color.orange.opacity(0.9)
        } else if hasModel {
            return Color.green.opacity(0.85)
        } else {
            return Color.blue.opacity(0.85)
        }
    }
    
    private var iconName: String {
        if isReconstructing {
            return "gear"
        } else if hasModel {
            return "cube.fill"
        } else {
            return "camera.fill"
        }
    }
    
    private var statusText: String {
        if isReconstructing {
            return "処理中"
        } else if hasModel {
            return "3Dモデル"
        } else {
            return "写真"
        }
    }
} */

/* private struct StatusCard: View {
    let hasModel: Bool
    let isReconstructing: Bool
    let reconstructionProgress: Double
    let reconstructionError: String?
    
    var body: some View {
        VStack(spacing: 16) {
            // Status header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(UIColor.label))
                    
                    Text(statusSubtitle)
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.systemGray))
                }
                
                Spacer()
            }
            
            // Progress or error
            if isReconstructing {
                VStack(spacing: 12) {
                    ProgressView(value: reconstructionProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .scaleEffect(y: 2)
                    
                    Text("\(Int(reconstructionProgress * 100))% 完了")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(UIColor.systemGray))
                }
            }
            
            if let error = reconstructionError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var statusColor: Color {
        if isReconstructing {
            return Color.orange
        } else if hasModel {
            return Color.green
        } else {
            return Color.blue
        }
    }
    
    private var statusIcon: String {
        if isReconstructing {
            return "gear.circle.fill"
        } else if hasModel {
            return "cube.fill"
        } else {
            return "camera.fill"
        }
    }
    
    private var statusTitle: String {
        if isReconstructing {
            return "3Dモデル処理中"
        } else if hasModel {
            return "3Dモデル準備完了"
        } else {
            return "写真キャプチャ完了"
        }
    }
    
    private var statusSubtitle: String {
        if isReconstructing {
            return "3Dモデルを作成中"
        } else if hasModel {
            return "表示・共有可能"
        } else {
            return "3Dモデル生成準備完了"
        }
    }
} */

/* private struct ActionButtonsSection: View {
    let hasModel: Bool
    let isReconstructing: Bool
    let modelURL: URL?
    let captureFolderURL: URL
    @Binding var showModel: Bool
    let onGenerateModel: () -> Void
    @EnvironmentObject var appModel: AppDataModel
    @State private var showPointCloud = false
    @State private var selectedPointCloudType: PointCloudType = .enhanced
    @State private var showAnnotatedImage = false
    
    private var objectCaptureSession: ObjectCaptureSession? {
        return appModel.objectCaptureSession
    }
    
    private func showPointCloudComparison(type: PointCloudType) {
        selectedPointCloudType = type
        showPointCloud = true
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if hasModel && !isReconstructing {
                // Primary action - View Model
                Button {
                    if modelURL != nil {
                        showModel = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "cube.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("3Dモデルを表示")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .background(Color.blue)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .disabled(modelURL == nil)
                
                // Point Cloud action
                if hasPointCloud() {
                    let bestType = getBestAvailablePointCloudType()
                    
                    Button {
                        showPointCloudComparison(type: bestType)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "cube.transparent.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("点群データを表示")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .background(Color.orange)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }

                
                // Secondary action - Share All
                ShareLink(item: captureFolderURL) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("すべてのファイルを共有")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .background(Color.green)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
            } else if !isReconstructing {
                // Primary action - Generate Model
                Button {
                    onGenerateModel()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("3Dモデルを生成")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .background(Color.blue)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Secondary action - Share
                ShareLink(item: captureFolderURL) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("キャプチャを共有")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .background(Color.green)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                // Processing state - disabled buttons
                VStack(spacing: 12) {
                    Button(action: {}) {
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            
                            Text("処理中...")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .background(Color.gray)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .disabled(true)
                }
            }
        }
        .sheet(isPresented: $showModel) {
            if let modelURL = modelURL {
                ModelView(modelFile: modelURL, endCaptureCallback: {
                    // キャプチャ詳細画面から呼び出された場合は、シートを閉じるだけ
                    showModel = false
                })
            }
        }
        .sheet(isPresented: $showPointCloud) {
            if hasPointCloud() {
                NavigationView {
                    SimplePointCloudView(
                        captureFolderURL: captureFolderURL,
                        pointCloudType: selectedPointCloudType
                    )
                    .navigationTitle("点群データ")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("閉じる") {
                                showPointCloud = false
                            }
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAnnotatedImage) {
            if hasAnnotatedImage() {
                AnnotatedImageViewer(captureFolderManager: createCaptureFolderManager())
            }
        }
    }
    
    // MARK: - Helper functions
    private func hasPointCloud() -> Bool {
        let allTypes = PointCloudType.allCases
        
        for type in allTypes {
            let url = captureFolderURL.appendingPathComponent(type.rawValue)
            if FileManager.default.fileExists(atPath: url.path) {
                print("DEBUG hasPointCloud: Found \(type.rawValue)")
                return true
            }
        }
        
        print("DEBUG hasPointCloud: No point cloud files found")
        return false
    }
    
    private func getAvailablePointCloudTypes() -> [PointCloudType] {
        var types: [PointCloudType] = []
        
        for type in PointCloudType.allCases {
            let url = captureFolderURL.appendingPathComponent(type.rawValue)
            if FileManager.default.fileExists(atPath: url.path) {
                types.append(type)
                print("DEBUG getAvailablePointCloudTypes: Found \(type.rawValue)")
            }
        }
        
        print("DEBUG getAvailablePointCloudTypes: Found \(types.count) types total")
        return types
    }
    
    private func getBestAvailablePointCloudType() -> PointCloudType {
        let availableTypes = getAvailablePointCloudTypes()
        
        // Priority order: Research > Enhanced > Standard > Traditional
        let priorityOrder: [PointCloudType] = [.research, .enhanced, .standard, .traditional]
        
        for type in priorityOrder {
            if availableTypes.contains(type) {
                return type
            }
        }
        
        // Fallback to first available type
        return availableTypes.first ?? .enhanced
    }
    
    
    private func getPointCloudURL(type: PointCloudType = .enhanced) -> URL {
        return captureFolderURL.appendingPathComponent(type.rawValue)
    }
    
    private func hasAnnotatedImage() -> Bool {
        let annotatedImageURL = captureFolderURL.appendingPathComponent(CaptureFolderManager.annotatedImageFileName)
        return FileManager.default.fileExists(atPath: annotatedImageURL.path)
    }
    
    private func createCaptureFolderManager() -> CaptureFolderManager {
        do {
            return try CaptureFolderManager(existingFolder: captureFolderURL)
        } catch {
            // Fallback - this shouldn't happen in normal use
            logger.error("Failed to create CaptureFolderManager: \(error)")
            return try! CaptureFolderManager()
        }
    }
} */

// MARK: - ActionButtonsSection End

// 📊 シンプル点群ビュー
/* private struct SimplePointCloudView: View {
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
                // Stats info
                VStack(spacing: 12) {
                    Text("総点数: \(formatNumber(pointCount))点")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("ファイルサイズ: \(formatFileSize(fileSize))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // 3D viewer
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
        .task {
            await loadSimplePointCloudData()
        }
    }
    
    // Helper functions
    private func loadSimplePointCloudData() async {
        let url = captureFolderURL.appendingPathComponent(pointCloudType.rawValue)
        
        do {
            let data = try String(contentsOf: url)
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
            print("Failed to load premium point cloud: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func parsePointCloudData(_ data: String) -> ([SIMD3<Float>], [SIMD3<Float>]) {
        let lines = data.components(separatedBy: .newlines)
        var points: [SIMD3<Float>] = []
        var colors: [SIMD3<Float>] = []
        var isDataSection = false
        
        for line in lines {
            if line == "end_header" {
                isDataSection = true
                continue
            }
            
            if isDataSection && !line.isEmpty {
                let components = line.components(separatedBy: " ")
                if components.count >= 6 {
                    if let x = Float(components[0]),
                       let y = Float(components[1]),
                       let z = Float(components[2]),
                       let r = Int(components[3]),
                       let g = Int(components[4]),
                       let b = Int(components[5]) {
                        
                        points.append(SIMD3<Float>(x, y, z))
                        colors.append(SIMD3<Float>(
                            Float(r) / 255.0,
                            Float(g) / 255.0,
                            Float(b) / 255.0
                        ))
                    }
                }
            }
        }
        
        return (points, colors)
    }
    
    private func getDensityLevel() -> String {
        if pointCount >= 2000000 { return "Research" }
        else if pointCount >= 1000000 { return "Professional" }
        else if pointCount >= 500000 { return "High" }
        else if pointCount >= 100000 { return "Standard" }
        else { return "Basic" }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000.0)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000.0)
        } else {
            return "\(number)"
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
} */


// 🔬 点群比較ビュー
/* private struct PointCloudComparisonView: View {
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
                // 🎯 タイプ選択セグメント
                if availableTypes.count > 1 {
                    VStack(spacing: 12) {
                        Text("🔬 点群データ比較")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Picker("点群タイプ", selection: $selectedType) {
                            ForEach(availableTypes, id: \.rawValue) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // 比較統計
                        if pointCounts.count > 1 {
                            HStack(spacing: 20) {
                                ForEach(availableTypes, id: \.rawValue) { type in
                                    VStack(spacing: 4) {
                                        Text(type == .standard ? "📊" : "🚀")
                                            .font(.title2)
                                        Text("\(pointCounts[type] ?? 0)")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        Text("points")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        if let size = fileSizes[type] {
                                            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
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
                
                // 🎯 点群データ表示
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isLoading {
                            ProgressView("読み込み中...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let data = pointCloudData[selectedType] {
                            PointCloudDataView(
                                data: data,
                                type: selectedType,
                                pointCount: pointCounts[selectedType] ?? 0
                            )
                        } else {
                            Text("データが読み込めませんでした")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("点群データ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadAllPointCloudData()
        }
        .onChange(of: selectedType) { _, _ in
            Task {
                if pointCloudData[selectedType] == nil {
                    await loadPointCloudData(for: selectedType)
                }
            }
        }
    }
    
    private func loadAllPointCloudData() async {
        isLoading = true
        for type in availableTypes {
            await loadPointCloudData(for: type)
        }
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
} */

// 🎯 点群データ詳細表示
/* private struct PointCloudDataView: View {
    let data: String
    let type: PointCloudType
    let pointCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー情報
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(type.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(pointCount) points")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                Text(type.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            // PLYヘッダー表示
            VStack(alignment: .leading, spacing: 8) {
                Text("📄 PLYファイルヘッダー")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                let headerLines = data.components(separatedBy: "end_header").first?
                    .components(separatedBy: .newlines) ?? []
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(headerLines.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(line.hasPrefix("comment") ? .green : .primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding(12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
            
            // サンプルデータ表示
            VStack(alignment: .leading, spacing: 8) {
                Text("🔢 点群データサンプル（最初の10点）")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                let dataLines = data.components(separatedBy: "end_header")
                    .dropFirst().first?
                    .components(separatedBy: .newlines)
                    .filter { !$0.isEmpty }
                    .prefix(10) ?? []
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(dataLines.enumerated()), id: \.offset) { index, line in
                            Text("\(index + 1): \(line)")
                                .font(.system(.caption2, design: .monospaced))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 150)
                .padding(12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
        }
    }
} */

/* private struct PointCloudViewerView: View {
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
                        // Data view (existing text view)
                        dataView
                    } else {
                        // 3D visualization view
                        visualizationView
                    }
                    
                    // Toggle button
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
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Share button
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
                        
                        Text("読み込みエラー")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("点群データを読み込み中...")
                            .font(.headline)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("キャプチャプレビュー")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                }
            }
        }
        .task {
            await loadPointCloudData()
        }
    }
    
    private var visualizationView: some View {
        VStack(spacing: 12) {
            // Point cloud info - よりコンパクトに
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("総点数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(pointCount)点")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .center) {
                    Text("品質")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(getDensityEvaluation())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(getDensityColor())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(getDensityColor().opacity(0.2))
                        .cornerRadius(4)
                }
                
                VStack(alignment: .trailing) {
                    Text("ファイル形式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("PLY")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                if let fileSize = getFileSize() {
                    VStack(alignment: .trailing) {
                        Text("サイズ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(fileSize)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            
            // 3D SceneKit view - 画面いっぱいに拡張 + ズーム可能
            ZStack {
                PointCloud3DView(points: pointCloudPoints, colors: pointCloudColors)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(12)
                    .clipped()
                
                // ズーム操作のヒント
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("ピンチでズーム・ドラッグで回転")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .padding()
                    }
                }
            }
            .frame(minHeight: 400, maxHeight: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
        }
    }
    
    private var dataView: some View {
        VStack(spacing: 16) {
            // Point cloud info
            VStack(spacing: 16) {
                Image(systemName: "cube.transparent.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("点群データ")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 8) {
                    Text("総点数: \(pointCount)点")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("ファイル形式: PLY")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let fileSize = getFileSize() {
                        Text("ファイルサイズ: \(fileSize)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // Data preview
            VStack(alignment: .leading, spacing: 12) {
                Text("点群データプレビュー:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ScrollView {
                    Text(String(pointCloudData.prefix(1000)) + (pointCloudData.count > 1000 ? "\n\n... (省略)" : ""))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private func loadPointCloudData() async {
        do {
            let data = try String(contentsOf: pointCloudURL, encoding: .utf8)
            let (points, colors) = parsePointCloudData(data)
            
            // 超詳細デバッグ情報を出力
            print("🎯 ULTRA HIGH DENSITY POINT CLOUD LOADED")
            print("📊 File size: \(data.count) characters")
            print("📊 Total points: \(points.count)")
            print("📊 Density evaluation: \(points.count >= 500000 ? "ULTRA HIGH (500K+)" : points.count >= 100000 ? "EXCELLENT (100K+)" : points.count >= 50000 ? "GOOD (50K+)" : points.count >= 10000 ? "FAIR (10K+)" : "LOW (<10K)")")
            print("📊 Sample coordinates: \(Array(points.prefix(3)))")
            
            await MainActor.run {
                pointCloudData = data
                pointCount = points.count
                pointCloudPoints = points
                pointCloudColors = colors
                
                print("DEBUG: UI updated with \(pointCount) points")
            }
        } catch {
            print("DEBUG: Failed to load point cloud: \(error)")
            await MainActor.run {
                loadingError = "点群ファイルの読み込みに失敗しました: \(error.localizedDescription)"
            }
        }
    }
    
    private func parsePointCloudData(_ data: String) -> ([SIMD3<Float>], [SIMD3<Float>]) {
        let lines = data.components(separatedBy: .newlines)
        var isDataSection = false
        var points: [SIMD3<Float>] = []
        var colors: [SIMD3<Float>] = []
        
        for line in lines {
            if line.hasPrefix("end_header") {
                isDataSection = true
                continue
            }
            
            if isDataSection && !line.trimmingCharacters(in: .whitespaces).isEmpty {
                let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)
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
        
        return (points, colors)
    }
    
    private func countPoints(in data: String) -> Int {
        let lines = data.components(separatedBy: .newlines)
        var isDataSection = false
        var count = 0
        
        for line in lines {
            if line.hasPrefix("end_header") {
                isDataSection = true
                continue
            }
            
            if isDataSection && !line.trimmingCharacters(in: .whitespaces).isEmpty {
                let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)
                if components.count >= 6 { // x, y, z, r, g, b
                    count += 1
                }
            }
        }
        
        return count
    }
    
    private func getFileSize() -> String? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: pointCloudURL.path)
            if let size = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
        } catch {
            print("Failed to get file size: \(error)")
        }
        return nil
    }
} */

// MARK: - Metadata Components

/* private struct InlineEditableMetadataCard: View {
    @Binding var traceMetadata: TraceMetadata?
    let onSave: (TraceMetadata) -> Void
    let onCancel: () -> Void
    
    @State private var hasFootprint: Bool
    @State private var animalType: String
    @State private var otherAnimal: String = ""
    @State private var traceType: String
    @State private var weather: String
    @State private var softness: Int
    @State private var notes: String
    
    let animalTypes = ["イノシシ", "シカ", "その他"]
    let traceTypes = ["足跡", "糞", "食痕", "爪痕", "その他"]
    let weatherOptions = ["晴れ", "曇り", "雨", "雪", "霧"]
    let softnessOptions = [
        (1, "非常に硬い"),
        (2, "硬い"),
        (3, "普通"),
        (4, "柔らかい"),
        (5, "非常に柔らかい")
    ]
    
    init(metadata: Binding<TraceMetadata?>, onSave: @escaping (TraceMetadata) -> Void, onCancel: @escaping () -> Void) {
        self._traceMetadata = metadata
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize with current metadata or defaults
        if let currentMetadata = metadata.wrappedValue {
            self._hasFootprint = State(initialValue: currentMetadata.hasFootprint)
            self._animalType = State(initialValue: currentMetadata.animalType)
            self._traceType = State(initialValue: currentMetadata.traceType)
            self._weather = State(initialValue: currentMetadata.weather ?? "晴れ")
            
            // Parse softness from substrate
            if let substrate = currentMetadata.substrate, let level = Int(substrate) {
                self._softness = State(initialValue: level)
            } else {
                self._softness = State(initialValue: 3)
            }
            
            self._notes = State(initialValue: currentMetadata.notes ?? "")
        } else {
            self._hasFootprint = State(initialValue: true)
            self._animalType = State(initialValue: "イノシシ")
            self._traceType = State(initialValue: "足跡")
            self._weather = State(initialValue: "晴れ")
            self._softness = State(initialValue: 3)
            self._notes = State(initialValue: "")
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("痕跡の詳細情報を入力")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                Text("発見した動物痕跡の詳細を記録してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(spacing: 16) {
                // Footprint Presence Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("足跡の有無", systemImage: "pawprint.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                        Text("*")
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            hasFootprint = true
                        }) {
                            HStack {
                                Image(systemName: hasFootprint ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(hasFootprint ? .green : .gray)
                                Text("🐾 足跡あり")
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            hasFootprint = false
                        }) {
                            HStack {
                                Image(systemName: !hasFootprint ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(!hasFootprint ? .green : .gray)
                                Text("❌ 足跡なし")
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                }
                
                // Animal Type Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("動物の種類", systemImage: "hare.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        Text("*")
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    
                    Picker("動物の種類", selection: $animalType) {
                        ForEach(animalTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if animalType == "その他" {
                        TextField("動物名を入力してください", text: $otherAnimal)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Trace Type Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("痕跡の種類", systemImage: "pawprint.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        Text("*")
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    
                    Picker("痕跡の種類", selection: $traceType) {
                        ForEach(traceTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Weather Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("天候", systemImage: "cloud.sun.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                        Text("(任意)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Picker("天候", selection: $weather) {
                        ForEach(weatherOptions, id: \.self) { weather in
                            Text(weather).tag(weather)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Ground Softness Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("地面の柔らかさ", systemImage: "hand.point.down.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.brown)
                        Text("(任意)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Picker("地面の柔らかさ", selection: $softness) {
                        ForEach(softnessOptions, id: \.0) { option in
                            Text("\(option.0). \(option.1)").tag(option.0)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Location Information
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("位置情報", systemImage: "location.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        Text("(自動取得)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    if let location = traceMetadata?.location {
                        VStack(alignment: .leading, spacing: 12) {
                            // Coordinates Info
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("緯度:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .leading)
                                    Text("\(location.coordinate.latitude, specifier: "%.6f")")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("経度:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .leading)
                                    Text("\(location.coordinate.longitude, specifier: "%.6f")")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                
                                if location.horizontalAccuracy >= 0 {
                                    HStack {
                                        Text("精度:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(width: 40, alignment: .leading)
                                        Text("±\(Int(location.horizontalAccuracy))m")
                                            .font(.caption)
                                            .foregroundColor(location.horizontalAccuracy < 10 ? .green : location.horizontalAccuracy < 50 ? .orange : .red)
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                }
                            }
                            
                            // Embedded Map
                            LocationMapView(location: location)
                                .frame(height: 150)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(UIColor.separator), lineWidth: 1)
                                )
                        }
                        .padding(12)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "location.slash.fill")
                                    .foregroundColor(.orange)
                                Text("位置情報が取得できませんでした")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            Text("スキャン開始時に位置情報サービスをONにしてください")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("備考", systemImage: "note.text")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        Text("(任意)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(UIColor.separator), lineWidth: 1)
                        )
                    
                    if notes.isEmpty {
                        Text("特記事項があれば記入してください（任意）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // Validation Message
            if !isValidInput {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(validationMessage)
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("キャンセル") {
                    onCancel()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(10)
                
                Button("保存") {
                    let finalAnimalType = animalType == "その他" ? otherAnimal : animalType
                    let updatedMetadata = TraceMetadata(
                        hasFootprint: hasFootprint,
                        animalType: finalAnimalType,
                        traceType: traceType,
                        weather: weather,
                        substrate: String(softness),
                        notes: notes.isEmpty ? nil : notes,
                        location: traceMetadata?.location,
                        timestamp: traceMetadata?.timestamp ?? Date()
                    )
                    print("DEBUG: Saving metadata: \(updatedMetadata)")
                    onSave(updatedMetadata)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidInput ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!isValidInput)
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var isValidInput: Bool {
        if animalType == "その他" {
            return !otherAnimal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !traceType.isEmpty
        }
        return !animalType.isEmpty && !traceType.isEmpty
    }
    
    private var validationMessage: String {
        if animalType == "その他" && otherAnimal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "動物名を入力してください"
        }
        if animalType.isEmpty {
            return "動物の種類を選択してください"
        }
        if traceType.isEmpty {
            return "痕跡の種類を選択してください"
        }
        return ""
    }
} */

// MARK: - Location Map View

/* private struct LocationMapView: UIViewRepresentable {
    let location: CLLocation
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = true
        mapView.showsUserLocation = false
        mapView.mapType = .standard
        
        // Add annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = "スキャン地点"
        annotation.subtitle = "動物痕跡の発見場所"
        mapView.addAnnotation(annotation)
        
        // Set region
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 200,
            longitudinalMeters: 200
        )
        mapView.setRegion(region, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update the map if location changes
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = "スキャン地点"
        annotation.subtitle = "動物痕跡の発見場所"
        
        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotation(annotation)
        
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 200,
            longitudinalMeters: 200
        )
        uiView.setRegion(region, animated: true)
    }
} */

/* private struct MetadataCard: View {
    let metadata: TraceMetadata
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("痕跡の詳細情報")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(UIColor.label))
                    
                    Text("記録された動物痕跡の情報")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.systemGray))
                }
                
                Spacer()
            }
            
            // Metadata Details
            VStack(spacing: 12) {
                // 痕跡情報（上部）
                MetadataRow(icon: "hare.fill", title: "動物の種類", value: metadata.animalType, color: .blue)
                MetadataRow(icon: "pawprint.fill", title: "痕跡の種類", value: metadata.traceType, color: .green)
                
                if let weather = metadata.weather {
                    MetadataRow(icon: "cloud.sun.fill", title: "天候", value: weather, color: .orange)
                }
                
                if let substrate = metadata.substrate {
                    let softnessText = getSoftnessText(from: substrate)
                    MetadataRow(icon: "hand.point.down.fill", title: "地面の柔らかさ", value: softnessText, color: .brown)
                }
                
                MetadataRow(icon: "clock.fill", title: "記録日時", value: formatTimestamp(metadata.timestamp), color: .purple)
                
                if let notes = metadata.notes, !notes.isEmpty {
                    MetadataRow(icon: "note.text", title: "備考", value: notes, color: .gray)
                }
                
                // 位置情報（下部）
                if let location = metadata.location {
                    Divider()
                        .padding(.vertical, 4)
                    
                    let locationText = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
                    MetadataRow(icon: "location.fill", title: "位置情報", value: locationText, color: .red)
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func getSoftnessText(from value: String) -> String {
        if let level = Int(value) {
            switch level {
            case 1: return "非常に硬い"
            case 2: return "硬い"
            case 3: return "普通"
            case 4: return "柔らかい"
            case 5: return "非常に柔らかい"
            default: return value
            }
        }
        return value
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
} */

/* private struct MetadataRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
} */

/* private struct MetadataEditRow<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    let content: Content
    
    init(icon: String, title: String, color: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                content
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
} */


// MARK: - Point Cloud Density Evaluation Extensions

// Moved to Views/Components/PointCloud/PointCloudViewerView+Density.swift


// MARK: - FootprintConfirmationView

private struct FootprintConfirmationView: View {
    let availableImages: [URL]
    @State private var selectedImageIndex: Int
    let captureFolderManager: CaptureFolderManager
    let onDismiss: () -> Void
    
    @State private var currentImage: UIImage?
    @State private var annotatedImage: UIImage?
    @State private var isLoadingImage = false
    @State private var showImageSelector = false
    @State private var showFootprintEditor = false
    @State private var userHasSelectedImage = false  // ユーザーが画像を選択したかどうか
    
    init(availableImages: [URL], initialSelectedIndex: Int, captureFolderManager: CaptureFolderManager, onDismiss: @escaping () -> Void) {
        self.availableImages = availableImages
        self.captureFolderManager = captureFolderManager
        self.onDismiss = onDismiss
        self._selectedImageIndex = State(initialValue: min(initialSelectedIndex, availableImages.count - 1))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // ユーザーが画像を選択した場合は選択画像を優先、そうでなければアノテーション画像を優先
                if let displayImage = userHasSelectedImage ? (currentImage ?? annotatedImage) : (annotatedImage ?? currentImage) {
                    GeometryReader { geometry in
                        ScrollView([.horizontal, .vertical]) {
                            Image(uiImage: displayImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: geometry.size.width - 32, maxHeight: geometry.size.height - 32)
                                .padding(16)
                        }
                        .background(Color.black)
                    }
                } else if isLoadingImage {
                    VStack {
                        ProgressView()
                        Text("画像を読み込み中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("画像の読み込みに失敗しました")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // 画像選択と編集ボタン
                VStack(spacing: 12) {
                    HStack {
                        Text("使用する画像:")
                            .font(.headline)
                        Spacer()
                        Text("\(selectedImageIndex + 1)枚目")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        Button("画像を選択") {
                            showImageSelector = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        Spacer()
                        
                        Button("足跡を編集") {
                            showFootprintEditor = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("足跡画像確認")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        onDismiss()
                    }
                }
            }
        }
        .onAppear {
            loadSelectedImage()
            checkForAnnotatedImage()
        }
        .onChange(of: selectedImageIndex) { _, _ in
            print("DEBUG: Selected image index changed to: \(selectedImageIndex)")
            loadSelectedImage()
            // 画像選択時はアノテーション画像チェックを再実行しない（選択画像を優先表示）
        }
        .sheet(isPresented: $showImageSelector) {
            GC_CustomImageSelectorView(
                availableImages: availableImages,
                selectedIndex: $selectedImageIndex,
                onSelectionChanged: { index in
                    selectedImageIndex = index
                    userHasSelectedImage = true  // ユーザーが画像を選択したことを記録
                    showImageSelector = false
                },
                onConfirm: { index in
                    selectedImageIndex = index
                    userHasSelectedImage = true  // ユーザーが画像を選択したことを記録
                    showImageSelector = false
                    // 少し遅延を入れて確認画面を更新してから編集画面を開く
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showFootprintEditor = true
                    }
                }
            )
        }
        .sheet(isPresented: $showFootprintEditor) {
            if let currentImage = currentImage {
                FootprintAnnotationView(
                    captureImage: currentImage,
                    captureFolderManager: captureFolderManager,
                    onSaveComplete: {
                        // 保存完了時に画像を再読み込み
                        checkForAnnotatedImage()
                    }
                )
                .onDisappear {
                    // 編集画面から戻った時にアノテーション画像を再読み込み
                    checkForAnnotatedImage()
                }
            }
        }
    }
    
    private func loadSelectedImage() {
        guard selectedImageIndex < availableImages.count else { return }
        
        isLoadingImage = true
        let imageURL = availableImages[selectedImageIndex]
        print("DEBUG: Loading selected image at index \(selectedImageIndex): \(imageURL.lastPathComponent)")
        
        Task {
            let image = await loadImage(from: imageURL)
            await MainActor.run {
                self.currentImage = image
                self.isLoadingImage = false
                print("DEBUG: Selected image loaded successfully. UserHasSelectedImage: \(self.userHasSelectedImage)")
            }
        }
    }
    
    private func loadImage(from url: URL) async -> UIImage? {
        do {
            let data = try Data(contentsOf: url)
            return UIImage(data: data)
        } catch {
            print("Failed to load image: \(error)")
            return nil
        }
    }
    
    private func checkForAnnotatedImage() {
        let annotatedImageURL = captureFolderManager.captureFolder.appendingPathComponent("annotated_footprints.jpg")
        
        // 画像キャッシュを強制的にクリア
        annotatedImage = nil
        
        if FileManager.default.fileExists(atPath: annotatedImageURL.path) {
            // ファイルから直接読み込み（キャッシュを避けるため）
            if let imageData = try? Data(contentsOf: annotatedImageURL),
               let image = UIImage(data: imageData) {
                annotatedImage = image
                print("DEBUG: Annotated image reloaded successfully")
            } else {
                print("DEBUG: Failed to load annotated image data")
            }
        } else {
            print("DEBUG: Annotated image file does not exist")
        }
    }
}

// MARK: - Custom Image Selector View

private struct CustomImageSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let availableImages: [URL]
    @Binding var selectedIndex: Int
    let onSelectionChanged: (Int) -> Void
    let onConfirm: (Int) -> Void
    
    @State private var showConfirmationAlert = false
    @State private var showCustomConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 20) {
                    ForEach(Array(availableImages.enumerated()), id: \.offset) { index, imageURL in
                        VStack(spacing: 8) {
                            AsyncImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(
                                        ProgressView()
                                            .tint(.blue)
                                    )
                            }
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedIndex == index ? Color.blue : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                            .shadow(
                                color: selectedIndex == index ? Color.blue.opacity(0.3) : Color.black.opacity(0.1),
                                radius: selectedIndex == index ? 8 : 4,
                                x: 0,
                                y: 2
                            )
                            
                            VStack(spacing: 2) {
                                Text("画像 \(index + 1)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                
                                if selectedIndex == index {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.blue)
                                        Text("選択中")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.blue)
                                    }
                                } else {
                                    Text("タップして選択")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onTapGesture {
                            selectedIndex = index
                            onSelectionChanged(index)
                        }
                        .scaleEffect(selectedIndex == index ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedIndex)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
            .navigationTitle("画像を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        print("DEBUG: 完了ボタンが押されました - selectedIndex: \(selectedIndex)")
                        showCustomConfirmation = true
                        print("DEBUG: showCustomConfirmation set to true")
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("足跡スタンプを編集", isPresented: $showConfirmationAlert) {
            Button("キャンセル", role: .cancel) {
                print("DEBUG: キャンセルが押されました")
                dismiss()
            }
            Button("編集する") {
                print("DEBUG: 編集するが押されました - selectedIndex: \(selectedIndex)")
                onConfirm(selectedIndex)
            }
        } message: {
            Text("画像 \(selectedIndex + 1) に足跡スタンプを追加しますか？")
        }
        .onChange(of: showConfirmationAlert) { _, newValue in
            print("DEBUG: showConfirmationAlert changed to: \(newValue)")
        }
        .sheet(isPresented: $showCustomConfirmation) {
            GC_CustomConfirmationDialog(
                selectedIndex: selectedIndex,
                onConfirm: { index in
                    print("DEBUG: Custom confirmation - onConfirm called with index: \(index)")
                    onConfirm(index)
                },
                onCancel: {
                    print("DEBUG: Custom confirmation - onCancel called")
                    showCustomConfirmation = false
                }
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
    }
}



// MARK: - Custom Confirmation Dialog

private struct CustomConfirmationDialog: View {
    let selectedIndex: Int
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            // アイコンとタイトル
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 8) {
                    Text("足跡スタンプを編集")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("画像 \(selectedIndex + 1) に足跡スタンプを追加しますか？")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // ボタン
            HStack(spacing: 12) {
                Button("キャンセル") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("編集する") {
                    onConfirm(selectedIndex)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}



// Density helpers moved into the extracted PointCloudViewerView component
