/*
Footprint Annotation View
Allows users to mark footprint locations on captured images
*/

import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "FootprintAnnotationView")

struct FootprintAnnotationView: View {
    @EnvironmentObject var appModel: AppDataModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var annotations: [FootprintAnnotation] = []
    @State private var showingSaveConfirmation = false
    @State private var dragOffset: CGSize = .zero
    @State private var dragAnnotation: FootprintAnnotation?
    @State private var scaleAnnotation: FootprintAnnotation?
    @State private var currentScale: CGFloat = 1.0
    @State private var showScaleIndicator = false
    @State private var scaleIndicatorValue: CGFloat = 1.0
    @State private var isImageLoading = true
    @State private var processedImage: UIImage?
    @State private var selectedFootprintSize: FootprintScaleSize = .medium
    @State private var selectedAnnotation: FootprintAnnotation?
    @State private var showDeleteConfirmation = false
    
    let captureImage: UIImage
    let captureFolderManager: CaptureFolderManager
    let onSaveComplete: (() -> Void)?
    
    init(captureImage: UIImage, captureFolderManager: CaptureFolderManager, onSaveComplete: (() -> Void)? = nil) {
        self.captureImage = captureImage
        self.captureFolderManager = captureFolderManager
        self.onSaveComplete = onSaveComplete
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                annotationView
                
                // スケールインジケーター（中央表示）
                if showScaleIndicator {
                    VStack {
                        Spacer()
                        
                        // 中央に大きく表示
                        VStack(spacing: 12) {
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(scaleIndicatorValue / 1.0)
                                .animation(.easeInOut(duration: 0.1), value: scaleIndicatorValue)
                            
                            VStack(spacing: 4) {
                                Text("足跡サイズ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(String(format: "%.1f×", scaleIndicatorValue))
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.primary, .secondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.3), .clear],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                        )
                        
                        Spacer()
                            .frame(height: 80) // コントロールパネルの高さ分
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showScaleIndicator)
                }
            }
            .navigationTitle("足跡マーキング")
            .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            saveAnnotatedImage()
                            showingSaveConfirmation = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("保存")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(annotations.isEmpty ? Color.gray : Color.blue)
                            )
                        }
                        .disabled(annotations.isEmpty)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    AnnotationControlPanel(
                        annotationCount: annotations.count,
                        onClearAll: clearAllAnnotations,
                        selectedSize: $selectedFootprintSize,
                        onSizeChanged: { newSize in
                            // 新しいサイズで追加される足跡に影響
                        }
                    )
                }
        }
        .alert("保存完了", isPresented: $showingSaveConfirmation) {
            Button("OK") {
                onSaveComplete?()
                dismiss()
            }
        } message: {
            Text("\(annotations.count)個の足跡マーカーと共に画像が保存されました。")
        }
        .alert("足跡を削除", isPresented: $showDeleteConfirmation) {
            Button("削除", role: .destructive) {
                if let annotation = selectedAnnotation {
                    removeAnnotation(annotation)
                    selectedAnnotation = nil
                }
            }
            Button("キャンセル", role: .cancel) {
                selectedAnnotation = nil
            }
        } message: {
            Text("この足跡マーカーを削除しますか？")
        }
    }
    
    private var annotationView: some View {
        GeometryReader { geometry in
            ZStack {
                if isImageLoading {
                    loadingView
                } else {
                    backgroundImageView(geometry: geometry)
                    annotationMarkersView(geometry: geometry)
                }
            }
        }
        .onAppear {
            // captureImageが既に渡されているので、それを使用
            processedImage = captureImage
            isImageLoading = false
            
            // 既存のアノテーションを読み込む
            loadExistingAnnotations()
            
            logger.log("FootprintAnnotationView appeared with image: \(String(describing: captureImage.size)), existing annotations: \(annotations.count)")
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text("画像を読み込んでいます...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private func backgroundImageView(geometry: GeometryProxy) -> some View {
        Group {
            if let image = processedImage {
                GeometryReader { imageGeometry in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .onTapGesture { location in
                            // 詳細なログ出力で座標系を確認
                            logger.log("🔍 TAP DEBUG:")
                            logger.log("  - Tap location: (\(String(format: "%.1f", location.x)), \(String(format: "%.1f", location.y)))")
                            logger.log("  - Image geometry size: (\(String(format: "%.1f", imageGeometry.size.width)), \(String(format: "%.1f", imageGeometry.size.height)))")
                            logger.log("  - Parent geometry size: (\(String(format: "%.1f", geometry.size.width)), \(String(format: "%.1f", geometry.size.height)))")
                            logger.log("  - Image actual size: (\(String(format: "%.1f", image.size.width)), \(String(format: "%.1f", image.size.height)))")
                            
                            addAnnotation(at: location, in: geometry, imageGeometry: imageGeometry)
                        }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func annotationMarkersView(geometry: GeometryProxy) -> some View {
        ForEach(Array(annotations.enumerated()), id: \.element.id) { index, annotation in
            FootprintMarker(
                annotation: annotation,
                annotationIndex: index,
                isSelected: scaleAnnotation?.id == annotation.id || selectedAnnotation?.id == annotation.id,
                onRemove: {
                    selectedAnnotation = annotation
                    showDeleteConfirmation = true
                },
                onDoubleTap: {
                    cycleAnnotationSize(annotation)
                },
                onTap: {
                    selectedAnnotation = selectedAnnotation?.id == annotation.id ? nil : annotation
                }
            )
            .position(
                x: actualImagePosition(for: annotation, in: geometry).x,
                y: actualImagePosition(for: annotation, in: geometry).y
            )
            .offset(dragAnnotation?.id == annotation.id ? dragOffset : .zero)
            .scaleEffect(scaleAnnotation?.id == annotation.id ? currentScale * annotation.scaleMultiplier : annotation.scaleMultiplier)
            .gesture(createCombinedGesture(for: annotation, geometry: geometry))
        }
    }
    
    private func createCombinedGesture(for annotation: FootprintAnnotation, geometry: GeometryProxy) -> some Gesture {
        let dragGesture = DragGesture(coordinateSpace: .local)
            .onChanged { value in
                if dragAnnotation == nil {
                    dragAnnotation = annotation
                    scaleAnnotation = nil // ドラッグ中はスケール無効
                }
                // 指とアノテーションの位置を正確に同期
                dragOffset = value.translation
            }
            .onEnded { value in
                if let dragAnnotation = dragAnnotation {
                    updateAnnotationPosition(
                        dragAnnotation, 
                        offset: value.translation,
                        in: geometry
                    )
                }
                dragAnnotation = nil
                dragOffset = .zero
            }
        
        let scaleGesture = MagnificationGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                if scaleAnnotation == nil {
                    scaleAnnotation = annotation
                    dragAnnotation = nil // スケール中はドラッグ無効
                    showScaleIndicator = true
                }
                currentScale = value
                
                // スケールインジケーターの更新
                if let currentAnnotation = scaleAnnotation {
                    scaleIndicatorValue = currentAnnotation.scaleMultiplier * value
                }
            }
            .onEnded { value in
                if let scaleAnnotation = scaleAnnotation {
                    updateAnnotationScale(scaleAnnotation, scale: value)
                }
                scaleAnnotation = nil
                currentScale = 1.0
                showScaleIndicator = false
            }
        
        return dragGesture.simultaneously(with: scaleGesture)
    }
    
    private func addAnnotation(at location: CGPoint, in geometry: GeometryProxy, imageGeometry: GeometryProxy) {
        // 最大10個の制限
        guard annotations.count < 10 else {
            logger.log("Maximum 10 annotations reached")
            return
        }
        
        // onTapGestureのlocationは既にImage view内の座標（.fitが適用済み）
        // GeometryReaderの座標系に変換する必要がある
        guard let image = processedImage else { return }
        
        // onTapGestureのlocationはGeometryReader内のImage view座標
        // imageGeometryは実際のImage viewのサイズを表す
        
        // 実際の画像表示領域を計算
        let imageAspectRatio = image.size.width / image.size.height
        let viewAspectRatio = imageGeometry.size.width / imageGeometry.size.height
        
        var displayRect: CGRect
        
        if imageAspectRatio > viewAspectRatio {
            // 画像が横長：width基準でfitする
            let displayHeight = imageGeometry.size.width / imageAspectRatio
            let yOffset = (imageGeometry.size.height - displayHeight) / 2
            displayRect = CGRect(
                x: 0,
                y: yOffset,
                width: imageGeometry.size.width,
                height: displayHeight
            )
        } else {
            // 画像が縦長：height基準でfitする
            let displayWidth = imageGeometry.size.height * imageAspectRatio
            let xOffset = (imageGeometry.size.width - displayWidth) / 2
            displayRect = CGRect(
                x: xOffset,
                y: 0,
                width: displayWidth,
                height: imageGeometry.size.height
            )
        }
        
        // タップ位置が実際の画像表示領域内かチェック
        guard displayRect.contains(location) else {
            logger.log("Tap outside image display area - ignored")
            return
        }
        
        // 表示領域内での相対位置を計算
        let relativePosition = CGPoint(
            x: (location.x - displayRect.minX) / displayRect.width,
            y: (location.y - displayRect.minY) / displayRect.height
        )
        
        let annotation = FootprintAnnotation(
            position: relativePosition,
            size: .medium,
            scaleMultiplier: selectedFootprintSize.scale
        )
        
        annotations.append(annotation)
        logger.log("Added footprint annotation \(annotations.count) at (\(String(format: "%.3f", relativePosition.x)), \(String(format: "%.3f", relativePosition.y))) - tap: (\(String(format: "%.1f", location.x)), \(String(format: "%.1f", location.y))) in display rect: (\(String(format: "%.1f", displayRect.origin.x)), \(String(format: "%.1f", displayRect.origin.y)), \(String(format: "%.1f", displayRect.size.width)), \(String(format: "%.1f", displayRect.size.height)))")
    }
    
    // 正規化された座標から実際の画面位置を計算
    private func actualImagePosition(for annotation: FootprintAnnotation, in geometry: GeometryProxy) -> CGPoint {
        guard let image = processedImage else { 
            return CGPoint(x: 0, y: 0)
        }
        
        // 実際の画像表示領域を計算（addAnnotationと同じロジック）
        let imageAspectRatio = image.size.width / image.size.height
        let viewAspectRatio = geometry.size.width / geometry.size.height
        
        var displayRect: CGRect
        
        if imageAspectRatio > viewAspectRatio {
            // 画像が横長：width基準でfitする
            let displayHeight = geometry.size.width / imageAspectRatio
            let yOffset = (geometry.size.height - displayHeight) / 2
            displayRect = CGRect(
                x: 0,
                y: yOffset,
                width: geometry.size.width,
                height: displayHeight
            )
        } else {
            // 画像が縦長：height基準でfitする
            let displayWidth = geometry.size.height * imageAspectRatio
            let xOffset = (geometry.size.width - displayWidth) / 2
            displayRect = CGRect(
                x: xOffset,
                y: 0,
                width: displayWidth,
                height: geometry.size.height
            )
        }
        
        // 相対位置から実際の画面位置を計算
        return CGPoint(
            x: displayRect.minX + annotation.position.x * displayRect.width,
            y: displayRect.minY + annotation.position.y * displayRect.height
        )
    }
    
    private func removeAnnotation(_ annotation: FootprintAnnotation) {
        annotations.removeAll { $0.id == annotation.id }
        logger.log("Removed footprint annotation")
    }
    
    private func updateAnnotationPosition(_ annotation: FootprintAnnotation, offset: CGSize, in geometry: GeometryProxy) {
        if let index = annotations.firstIndex(where: { $0.id == annotation.id }) {
            // 実際の画像領域を取得
            guard let image = processedImage else { return }
            let imageAspectRatio = image.size.width / image.size.height
            let viewAspectRatio = geometry.size.width / geometry.size.height
            
            var actualImageRect: CGRect
            
            if imageAspectRatio > viewAspectRatio {
                let imageHeight = geometry.size.width / imageAspectRatio
                let yOffset = (geometry.size.height - imageHeight) / 2
                actualImageRect = CGRect(x: 0, y: yOffset, width: geometry.size.width, height: imageHeight)
            } else {
                let imageWidth = geometry.size.height * imageAspectRatio
                let xOffset = (geometry.size.width - imageWidth) / 2
                actualImageRect = CGRect(x: xOffset, y: 0, width: imageWidth, height: geometry.size.height)
            }
            
            let currentPosition = annotations[index].position
            
            // オフセットを画像座標系に変換
            let offsetX = offset.width / actualImageRect.width
            let offsetY = offset.height / actualImageRect.height
            
            let newX = max(0, min(1, currentPosition.x + offsetX))
            let newY = max(0, min(1, currentPosition.y + offsetY))
            
            annotations[index].position = CGPoint(x: newX, y: newY)
            logger.log("Updated annotation position to (\(String(format: "%.3f", newX)), \(String(format: "%.3f", newY)))")
        }
    }
    
    private func updateAnnotationScale(_ annotation: FootprintAnnotation, scale: CGFloat) {
        if let index = annotations.firstIndex(where: { $0.id == annotation.id }) {
            let currentScale = annotations[index].scaleMultiplier
            let newScale = currentScale * scale
            let clampedScale = max(0.3, min(5.0, newScale))
            annotations[index].scaleMultiplier = clampedScale
            logger.log("Updated annotation scale from \(String(format: "%.1f", currentScale))x to \(String(format: "%.1f", clampedScale))x")
        }
    }
    
    private func cycleAnnotationSize(_ annotation: FootprintAnnotation) {
        if let index = annotations.firstIndex(where: { $0.id == annotation.id }) {
            let currentScale = annotations[index].scaleMultiplier
            let newScale: CGFloat
            
            if currentScale < 0.8 {
                newScale = 1.0  // 標準サイズ
            } else if currentScale < 1.5 {
                newScale = 2.0  // 大サイズ
            } else if currentScale < 2.5 {
                newScale = 3.0  // 特大サイズ
            } else {
                newScale = 0.5  // 小サイズ
            }
            
            annotations[index].scaleMultiplier = newScale
            logger.log("Cycled annotation size to \(newScale)x")
        }
    }
    
    private func clearAllAnnotations() {
        annotations.removeAll()
        logger.log("Cleared all annotations")
    }
    
    private func saveAnnotatedImage() {
        let originalImage = processedImage ?? captureImage
        let renderer = ImageRenderer(content: createAnnotatedImageView())
        
        // 元画像のサイズを維持し、高解像度でレンダリング
        renderer.proposedSize = ProposedViewSize(originalImage.size)
        renderer.scale = 1.0  // 等倍でレンダリング（サイズブーストを活かす）
        
        if let annotatedImage = renderer.uiImage {
            saveImageToFolder(annotatedImage)
            logger.log("✅ Successfully rendered annotated image at size: \(String(describing: annotatedImage.size)), scale: \(renderer.scale)x")
            
            // 足跡サイズの確認ログ
            for (index, annotation) in annotations.enumerated() {
                let baseSize = annotation.size.iconSize * annotation.scaleMultiplier
                let savedSize = SavedFootprintMarker.calculateSaveSize(for: annotation)
                let ratio = String(format: "%.1f", savedSize / baseSize)
                logger.log("足跡 \(index + 1) 保存サイズ: \(baseSize)pt → \(savedSize)pt (x\(ratio)) - 中心基準配置")
            }
        } else {
            logger.error("❌ Failed to render annotated image")
        }
    }
    
    private func createAnnotatedImageView() -> some View {
        let imageToUse = processedImage ?? captureImage
        
        return ZStack {
            // 背景画像 - アスペクト比を維持して完全表示
            Image(uiImage: imageToUse)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            // アノテーションレイヤー
            ForEach(Array(annotations.enumerated()), id: \.element.id) { index, annotation in
                ZStack {
                    // スケール適用済みの足跡マーカー
                    // 保存用の境界付きマーカー
                    SavedFootprintMarker(
                        annotation: annotation,
                        annotationIndex: index,
                        showBoundingBox: true   // デバッグ: 境界を表示
                    )
                    
                    // デバッグ用境界ボックス（中心基準確認）
                    if true { // デバッグ: 中心位置と境界を確認
                        ZStack {
                            // 保存時の境界矩形を表示
                            let bounds = annotation.saveBoundingSize
                            Rectangle()
                                .stroke(Color.orange, lineWidth: 3)
                                .background(Color.orange.opacity(0.1))
                                .frame(width: bounds.width, height: bounds.height)
                            
                            // 表示時のサイズを青で表示
                            Circle()
                                .stroke(Color.blue, lineWidth: 1)
                                .frame(
                                    width: annotation.size.iconSize * annotation.scaleMultiplier,
                                    height: annotation.size.iconSize * annotation.scaleMultiplier
                                )
                            
                            // 保存時のサイズを赤で表示
                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                                .frame(
                                    width: SavedFootprintMarker.calculateSaveSize(for: annotation),
                                    height: SavedFootprintMarker.calculateSaveSize(for: annotation)
                                )
                            
                            // 中心点
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            
                            // 境界情報ラベル
                            VStack {
                                Spacer()
                                Text("\(Int(bounds.width))x\(Int(bounds.height))")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(4)
                                    .offset(y: bounds.height / 2 + 10)
                            }
                        }
                    }
                }
                .position(
                    x: annotation.position.x * imageToUse.size.width,
                    y: annotation.position.y * imageToUse.size.height
                )
            }
        }
        .frame(width: imageToUse.size.width, height: imageToUse.size.height)
        .clipped()
    }
    
    private func saveImageToFolder(_ image: UIImage) {
        let annotatedImageURL = captureFolderManager.captureFolder
            .appendingPathComponent("annotated_footprints.jpg")
        
        // 画像の向きを縦画面に修正
        let correctedImage = correctImageOrientation(image)
        
        if let imageData = correctedImage.jpegData(compressionQuality: 0.95) {
            do {
                try imageData.write(to: annotatedImageURL)
                
                // 詳細なサイズ情報をログ出力
                let metadata = AnnotationMetadata(
                    annotations: annotations,
                    imageSize: CGSize(width: captureImage.size.width, height: captureImage.size.height),
                    timestamp: Date()
                )
                
                // Save annotation metadata
                saveAnnotationMetadata(metadata)
                let stats = metadata.sizeStatistics
                
                logger.log("=== 保存する足跡情報 (\(annotations.count)個) ===")
                logger.log("サイズ統計: 平均=\(String(format: "%.1f", stats.averageSize))pt, 範囲=\(String(format: "%.1f", stats.minSize))-\(String(format: "%.1f", stats.maxSize))pt")
                logger.log("最频出サイズ: \(stats.mostCommonSize?.label ?? "N/A"), バラエティ: \(String(format: "%.2f", stats.sizeVariety))")
                logger.log("足跡占有率: \(String(format: "%.3f", metadata.totalFootprintArea * 100))%")
                
                for (index, annotation) in annotations.enumerated() {
                    let bounds = annotation.boundingSize
                    logger.log("足跡 \(index + 1): サイズ=\(annotation.size.label)(\(String(format: "%.1f", annotation.actualSizeInPixels))pt), 境界=\(String(format: "%.1f", bounds.width))x\(String(format: "%.1f", bounds.height)), 位置=(\(String(format: "%.3f", annotation.position.x)), \(String(format: "%.3f", annotation.position.y)))")
                }
                logger.log("=== 保存完了: annotated_footprints.jpg ===")
                
                logger.log("✅ Successfully saved annotated image with \(annotations.count) footprints")
            } catch {
                logger.error("Failed to save annotated image: \(error)")
            }
        }
    }
    
    
    private func loadExistingAnnotations() {
        let metadataURL = captureFolderManager.captureFolder.appendingPathComponent("footprint_annotations.json")
        
        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            logger.log("No existing annotations found - starting fresh")
            return
        }
        
        do {
            let data = try Data(contentsOf: metadataURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let existingMetadata = try decoder.decode(AnnotationMetadata.self, from: data)
            annotations = existingMetadata.annotations
            logger.log("Loaded \(annotations.count) existing annotations")
        } catch {
            logger.error("Failed to load existing annotations: \(error)")
            annotations = [] // エラーの場合は空の配列から開始
        }
    }
    
    private func saveAnnotationMetadata(_ metadata: AnnotationMetadata) {
        let metadataURL = captureFolderManager.captureFolder
            .appendingPathComponent("footprint_annotations.json")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(metadata)
            try data.write(to: metadataURL)
            logger.log("Saved annotation metadata")
        } catch {
            logger.error("Failed to save annotation metadata: \(error)")
        }
    }
    
    /// 画像の向きを縦画面（Portrait）に修正
    private func correctImageOrientation(_ image: UIImage) -> UIImage {
        // すでに正しい向きの場合はそのまま返す
        if image.imageOrientation == .up {
            return image
        }
        
        // 画像を正しい向きに修正
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        guard let correctedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return image // 修正に失敗した場合は元の画像を返す
        }
        
        return correctedImage
    }
    
    /// 画像の向きを考慮した座標変換
    private func transformLocationForImageOrientation(_ location: CGPoint, image: UIImage, geometry: GeometryProxy) -> CGPoint {
        // 画像の向きに応じて座標を変換
        switch image.imageOrientation {
        case .up:
            // 正常な向き - 変換不要
            return location
            
        case .down:
            // 180度回転
            return CGPoint(
                x: geometry.size.width - location.x,
                y: geometry.size.height - location.y
            )
            
        case .left:
            // 反時計回りに90度回転（横画面で撮影された画像）
            return CGPoint(
                x: location.y,
                y: geometry.size.width - location.x
            )
            
        case .right:
            // 時計回りに90度回転
            return CGPoint(
                x: geometry.size.height - location.y,
                y: location.x
            )
            
        case .upMirrored:
            // 水平反転
            return CGPoint(
                x: geometry.size.width - location.x,
                y: location.y
            )
            
        case .downMirrored:
            // 180度回転 + 水平反転
            return CGPoint(
                x: location.x,
                y: geometry.size.height - location.y
            )
            
        case .leftMirrored:
            // 反時計回りに90度回転 + 水平反転
            return CGPoint(
                x: geometry.size.height - location.y,
                y: geometry.size.width - location.x
            )
            
        case .rightMirrored:
            // 時計回りに90度回転 + 水平反転
            return CGPoint(
                x: location.y,
                y: location.x
            )
            
        @unknown default:
            return location
        }
    }
    
    /// 画像の向きを考慮した逆座標変換（表示用）
    private func reverseTransformPositionForImageOrientation(_ position: CGPoint, image: UIImage, geometry: GeometryProxy) -> CGPoint {
        // 画像の向きに応じて座標を逆変換
        switch image.imageOrientation {
        case .up:
            // 正常な向き - 変換不要
            return position
            
        case .down:
            // 180度回転の逆変換
            return CGPoint(
                x: geometry.size.width - position.x,
                y: geometry.size.height - position.y
            )
            
        case .left:
            // 反時計回りに90度回転の逆変換
            return CGPoint(
                x: geometry.size.width - position.y,
                y: position.x
            )
            
        case .right:
            // 時計回りに90度回転の逆変換
            return CGPoint(
                x: position.y,
                y: geometry.size.height - position.x
            )
            
        case .upMirrored:
            // 水平反転の逆変換
            return CGPoint(
                x: geometry.size.width - position.x,
                y: position.y
            )
            
        case .downMirrored:
            // 180度回転 + 水平反転の逆変換
            return CGPoint(
                x: position.x,
                y: geometry.size.height - position.y
            )
            
        case .leftMirrored:
            // 反時計回りに90度回転 + 水平反転の逆変換
            return CGPoint(
                x: geometry.size.width - position.y,
                y: geometry.size.height - position.x
            )
            
        case .rightMirrored:
            // 時計回りに90度回転 + 水平反転の逆変換
            return CGPoint(
                x: position.y,
                y: position.x
            )
            
        @unknown default:
            return position
        }
    }
}

struct FootprintMarker: View {
    let annotation: FootprintAnnotation
    let annotationIndex: Int
    let isSelected: Bool
    let onRemove: () -> Void
    let onDoubleTap: () -> Void
    let onTap: () -> Void
    
    private var annotationColor: Color {
        let colors: [Color] = [
            .red, .blue, .green, .orange, .purple,
            .pink, .cyan, .yellow, .indigo, .mint
        ]
        return colors[min(annotationIndex, colors.count - 1)]
    }
    
    private var gradientColors: [Color] {
        let baseColor = annotationColor
        return [baseColor.opacity(0.8), baseColor, baseColor.opacity(0.6)]
    }
    
    // スケールを考慮したアイコンサイズ
    private var scaledIconSize: CGFloat {
        return annotation.size.iconSize * annotation.scaleMultiplier
    }
    
    // 適切なタッチエリアサイズ（アイコンサイズに応じて調整）
    private var touchAreaSize: CGFloat {
        let baseSize = scaledIconSize + 16
        // 最小タッチエリアを44pt、最大を80ptに制限
        return max(44, min(80, baseSize))
    }
    
    var body: some View {
        ZStack {
            // タッチエリア
            Circle()
                .fill(Color.clear)
                .frame(width: touchAreaSize, height: touchAreaSize)
            
            // 選択状態のハイライト背景
            if isSelected {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [annotationColor.opacity(0.3), annotationColor.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: touchAreaSize / 2
                        )
                    )
                    .frame(width: touchAreaSize * 1.5, height: touchAreaSize * 1.5)
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
            }
            
            // メインの足跡アイコン（グラデーション付き）
            ZStack {
                // 影
                Image(systemName: "pawprint.fill")
                    .font(.system(size: scaledIconSize, weight: .bold))
                    .foregroundColor(.black.opacity(0.2))
                    .offset(x: 1, y: 1)
                
                // メインアイコン
                Image(systemName: "pawprint.fill")
                    .font(.system(size: scaledIconSize, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "pawprint")
                            .font(.system(size: scaledIconSize, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    )
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            
            // 選択状態の境界線
            if isSelected {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [annotationColor, annotationColor.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), 
                        lineWidth: 4
                    )
                    .frame(width: touchAreaSize + 8, height: touchAreaSize + 8)
                    .scaleEffect(isSelected ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            
            // アノテーション番号（オプション）
            if false { // 番号表示を無効化
                Text("\(annotationIndex + 1)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(
                        Circle()
                            .fill(annotationColor)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    )
                    .offset(x: touchAreaSize / 2 - 8, y: -touchAreaSize / 2 + 8)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
        }
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onRemove()
        }
    }
}

struct AnnotationControlPanel: View {
    let annotationCount: Int
    let onClearAll: () -> Void
    @Binding var selectedSize: FootprintScaleSize
    let onSizeChanged: (FootprintScaleSize) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 左側：足跡カウント
            HStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("\(annotationCount)/10")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // 中央：サイズ選択（コンパクト）
            VStack(spacing: 4) {
                Text("サイズ")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(FootprintScaleSize.allCases, id: \.self) { size in
                        Button(action: {
                            selectedSize = size
                            onSizeChanged(size)
                        }) {
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: size.iconSize * 0.8))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: selectedSize == size ? [.white, .white.opacity(0.8)] : [.gray, .gray.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: selectedSize == size ? [.blue, .blue.opacity(0.8)] : [Color(.systemGray5), Color(.systemGray6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .scaleEffect(selectedSize == size ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: selectedSize)
                    }
                }
            }
            
            Spacer()
            
            // 右側：削除ボタン
            if annotationCount > 0 {
                Button(action: onClearAll) {
                    Image(systemName: "trash.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.red, .red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.2), value: annotationCount > 0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct SizeSelectionButton: View {
    let size: FootprintScaleSize
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // サイズを視覚的に表現するアイコン
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size.iconSize, weight: .bold))
                    .foregroundColor(isSelected ? .white : .gray)
                
                Text(size.label)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .frame(width: 60, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

enum FootprintScaleSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var scale: CGFloat {
        switch self {
        case .small: return 0.7
        case .medium: return 1.0
        case .large: return 1.4
        }
    }
    
    var label: String {
        switch self {
        case .small: return "小"
        case .medium: return "中"
        case .large: return "大"
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 18
        case .large: return 22
        }
    }
}

// MARK: - Data Models

struct FootprintAnnotation: Identifiable, Codable {
    let id = UUID()
    var position: CGPoint
    let size: FootprintSize
    var scaleMultiplier: CGFloat = 1.0
    
    // 足跡の実際の大きさ情報（保存時のピクセルサイズ）
    var actualSizeInPixels: CGFloat {
        return size.iconSize * scaleMultiplier
    }
    
    // 足跡の境界情報（表示・保存時の範囲）
    var boundingSize: FootprintBounds {
        let actualSize = actualSizeInPixels
        let padding: CGFloat = 8
        return FootprintBounds(
            width: actualSize + padding * 2,
            height: actualSize + padding * 2,
            iconSize: actualSize
        )
    }
    
    // 保存時の境界情報（大きめサイズ）
    var saveBoundingSize: FootprintBounds {
        let saveSize = SavedFootprintMarker.calculateSaveSize(for: self)
        let padding: CGFloat = 16  // 保存時は大きめのパディング
        return FootprintBounds(
            width: saveSize + padding * 2,
            height: saveSize + padding * 2,
            iconSize: saveSize
        )
    }
    
    init(position: CGPoint, size: FootprintSize, scaleMultiplier: CGFloat = 1.0) {
        self.position = position
        self.size = size
        self.scaleMultiplier = scaleMultiplier
    }
}

enum FootprintSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var label: String {
        switch self {
        case .small: return "小"
        case .medium: return "中"
        case .large: return "大"
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 24
        case .medium: return 32
        case .large: return 40
        }
    }
}

struct AnnotationMetadata: Codable {
    let annotations: [FootprintAnnotation]
    let imageSize: CGSize
    let timestamp: Date
    
    // 足跡のサイズ統計情報
    var sizeStatistics: FootprintSizeStatistics {
        let sizes = annotations.map { $0.actualSizeInPixels }
        return FootprintSizeStatistics(
            totalCount: annotations.count,
            averageSize: sizes.isEmpty ? 0 : sizes.reduce(0, +) / Double(sizes.count),
            minSize: sizes.min() ?? 0,
            maxSize: sizes.max() ?? 0,
            sizeDistribution: Dictionary(grouping: annotations) { annotation in
                annotation.size
            }.mapValues { $0.count }
        )
    }
    
    // 足跡の総面積（画像全体に占める割合）
    var totalFootprintArea: Double {
        let imageArea = imageSize.width * imageSize.height
        let footprintArea = annotations.reduce(0.0) { total, annotation in
            let bounds = annotation.boundingSize
            return total + Double(bounds.width * bounds.height)
        }
        return footprintArea / Double(imageArea)
    }
}

// 足跡の境界情報
struct FootprintBounds: Codable {
    let width: CGFloat
    let height: CGFloat
    let iconSize: CGFloat
    
    // 中心からのオフセットで境界を取得
    func rect(centeredAt center: CGPoint) -> CGRect {
        return CGRect(
            x: center.x - width / 2,
            y: center.y - height / 2,
            width: width,
            height: height
        )
    }
}

// 足跡サイズの統計情報
struct FootprintSizeStatistics: Codable {
    let totalCount: Int
    let averageSize: Double
    let minSize: CGFloat
    let maxSize: CGFloat
    let sizeDistribution: [FootprintSize: Int]
    
    // 最も一般的なサイズ
    var mostCommonSize: FootprintSize? {
        return sizeDistribution.max(by: { $0.value < $1.value })?.key
    }
    
    // サイズのバラエティ指数（0＝均一、高い＝バラバラ）
    var sizeVariety: Double {
        let uniqueSizes = Set(sizeDistribution.keys).count
        return Double(uniqueSizes) / max(1.0, Double(totalCount))
    }
}

// 保存用のシンプルな足跡マーカー
// 保存用の境界付き足跡マーカー
struct SavedFootprintMarker: View {
    let annotation: FootprintAnnotation
    let annotationIndex: Int
    let showBoundingBox: Bool
    
    init(annotation: FootprintAnnotation, annotationIndex: Int, showBoundingBox: Bool = false) {
        self.annotation = annotation
        self.annotationIndex = annotationIndex
        self.showBoundingBox = showBoundingBox
    }
    
    // 静的メソッドでサイズ計算を共有
    static func calculateSaveSize(for annotation: FootprintAnnotation) -> CGFloat {
        let baseSize = annotation.size.iconSize * annotation.scaleMultiplier
        let sizeBoost: CGFloat
        
        switch annotation.size {
        case .small: sizeBoost = 12.0  // 10倍超のブースト
        case .medium: sizeBoost = 10.0 // 10倍ブースト
        case .large: sizeBoost = 8.0   // 8倍ブースト（大きいサイズは控えめ）
        }
        
        // クランプ範囲を拡大して表示時のサイズ分散を保持
        let minSavedSize: CGFloat = 50   // 150→50に縮小（小さい足跡もしっかり保存）
        let maxSavedSize: CGFloat = 1200 // 600→1200に拡大（大きい足跡も保存）
        let boostedSize = baseSize * sizeBoost
        
        return max(minSavedSize, min(maxSavedSize, boostedSize))
    }
    
    private var annotationColor: Color {
        let colors: [Color] = [
            .red, .blue, .green, .orange, .purple,
            .pink, .cyan, .yellow, .indigo, .mint
        ]
        return colors[min(annotationIndex, colors.count - 1)]
    }
    
    // 保存用の統一サイズ（静的メソッドを使用）
    private var displaySize: CGFloat {
        return SavedFootprintMarker.calculateSaveSize(for: annotation)
    }
    
    var body: some View {
        ZStack {
            // 境界矩形（保存時の確実な領域確保）
            if showBoundingBox {
                let bounds = annotation.saveBoundingSize
                Rectangle()
                    .stroke(
                        LinearGradient(
                            colors: [annotationColor.opacity(0.4), annotationColor.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .background(
                        Rectangle()
                            .fill(annotationColor.opacity(0.05))
                    )
                    .frame(width: bounds.width, height: bounds.height)
            }
            
            // 足跡アイコン本体
            footprintIconContent
                .frame(width: displaySize, height: displaySize)
        }
        // 重要: 境界矩形のサイズでフレームを設定
        .frame(
            width: annotation.saveBoundingSize.width,
            height: annotation.saveBoundingSize.height
        )
    }
    
    // 足跡アイコンの内容
    private var footprintIconContent: some View {
        ZStack {
            // 影
            Image(systemName: "pawprint.fill")
                .font(.system(size: displaySize, weight: .bold))
                .foregroundColor(.black.opacity(0.2))
                .offset(x: 2, y: 2)
            
            // メインアイコン（グラデーション付き）
            Image(systemName: "pawprint.fill")
                .font(.system(size: displaySize, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [annotationColor, annotationColor.opacity(0.7), annotationColor.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Image(systemName: "pawprint")
                        .font(.system(size: displaySize, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                )
            
            // 境界線（緺麗に）
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [annotationColor.opacity(0.3), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: displaySize + 12, height: displaySize + 12)
        }
    }
}

