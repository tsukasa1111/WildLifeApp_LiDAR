/*
Editable Annotated Image Viewer
アノテーション画像の表示・編集機能
*/

import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "EditableAnnotatedImageViewer")

struct EditableAnnotatedImageViewer: View {
    @Environment(\.dismiss) private var dismiss
    let captureFolderURL: URL
    
    @State private var annotatedImage: UIImage?
    @State private var originalImage: UIImage?
    @State private var isLoading = true
    @State private var showFootprintEditor = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    loadingView
                } else if let annotatedImage = annotatedImage {
                    imageDisplayView(image: annotatedImage)
                } else {
                    errorView
                }
            }
            .navigationTitle("足跡画像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if annotatedImage != nil {
                        Button("編集") {
                            showFootprintEditor = true
                        }
                    }
                }
            }
        }
        .onAppear {
            loadAnnotatedImage()
        }
        .sheet(isPresented: $showFootprintEditor) {
            if let originalImage = originalImage {
                if let captureFolderManager = try? CaptureFolderManager(existingFolder: captureFolderURL) {
                    FootprintAnnotationView(
                        captureImage: originalImage,
                        captureFolderManager: captureFolderManager
                    )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("キャプチャフォルダーの作成に失敗しました")
                            .font(.headline)
                        
                        Button("閉じる") {
                            showFootprintEditor = false
                        }
                        .padding()
                    }
                    .padding()
                }
                .onDisappear {
                    // 編集後に画像を再読み込み
                    loadAnnotatedImage()
                }
            } else {
                // 元画像が読み込めない場合のエラー表示
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("編集用の元画像が見つかりません")
                        .font(.headline)
                    
                    Text("画像ファイルが破損しているか、削除されている可能性があります。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("閉じる") {
                        showFootprintEditor = false
                    }
                    .padding()
                }
                .padding()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("画像を読み込んでいます...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("画像の読み込みに失敗しました")
                .font(.headline)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("再試行") {
                loadAnnotatedImage()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func imageDisplayView(image: UIImage) -> some View {
        ScrollView([.horizontal, .vertical]) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()
        }
        .background(Color.black)
    }
    
    private func loadAnnotatedImage() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // アノテーション画像を読み込み
                let annotatedImageURL = captureFolderURL.appendingPathComponent("annotated_footprints.jpg")
                guard FileManager.default.fileExists(atPath: annotatedImageURL.path) else {
                    await MainActor.run {
                        errorMessage = "アノテーション画像が見つかりません"
                        isLoading = false
                    }
                    return
                }
                
                let imageData = try Data(contentsOf: annotatedImageURL)
                guard let image = UIImage(data: imageData) else {
                    await MainActor.run {
                        errorMessage = "画像形式が不正です"
                        isLoading = false
                    }
                    return
                }
                
                // 元画像も読み込み（編集用）- 選択された画像を使用
                let originalImageURL = getSelectedImage()
                var originalImg: UIImage?
                if let originalURL = originalImageURL {
                    let originalData = try Data(contentsOf: originalURL)
                    originalImg = UIImage(data: originalData)
                }
                
                await MainActor.run {
                    annotatedImage = image
                    originalImage = originalImg
                    isLoading = false
                }
                
                logger.log("Successfully loaded annotated image")
                
            } catch {
                await MainActor.run {
                    errorMessage = "読み込みエラー: \(error.localizedDescription)"
                    isLoading = false
                }
                logger.error("Failed to load annotated image: \(error)")
            }
        }
    }
    
    private func getSelectedImage() -> URL? {
        let imagesFolder = captureFolderURL.appendingPathComponent("Images")
        
        do {
            let images = try FileManager.default.contentsOfDirectory(
                at: imagesFolder,
                includingPropertiesForKeys: nil,
                options: []
            )
            .filter { !$0.hasDirectoryPath }
            .sorted { $0.path < $1.path }
            
            // メタデータから選択されたインデックスを取得（デフォルトは3枚目）
            let selectedIndex = getSelectedImageIndexFromMetadata() ?? 2
            
            if selectedIndex < images.count {
                logger.log("Using selected image \(selectedIndex + 1) for editing: \(images[selectedIndex].lastPathComponent)")
                return images[selectedIndex]
            } else if !images.isEmpty {
                logger.log("Selected index out of range, using last image: \(images.last!.lastPathComponent)")
                return images.last
            } else {
                return nil
            }
        } catch {
            logger.error("Failed to get selected image: \(error)")
            return nil
        }
    }
    
    private func getSelectedImageIndexFromMetadata() -> Int? {
        // 簡易的な実装：設定ファイルまたはメタデータから取得
        // 今回は3枚目（インデックス2）をデフォルトとして返す
        return 2
    }
    
}

// MARK: - Simple Footprint Editor

struct SimpleFootprintEditor: View {
    @Environment(\.dismiss) private var dismiss
    let captureImage: UIImage
    let captureFolderURL: URL
    
    @State private var annotations: [FootprintAnnotation] = []
    @State private var showingSaveConfirmation = false
    @State private var dragOffset: CGSize = .zero
    @State private var dragAnnotation: FootprintAnnotation?
    @State private var scaleAnnotation: FootprintAnnotation?
    @State private var currentScale: CGFloat = 1.0
    @State private var selectedFootprintSize: FootprintScaleSize = .medium
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background image
                    Image(uiImage: captureImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .onTapGesture { location in
                            addAnnotation(at: location, in: geometry)
                        }
                    
                    // Annotation markers
                    ForEach(Array(annotations.enumerated()), id: \.element.id) { index, annotation in
                        FootprintMarker(
                            annotation: annotation,
                            annotationIndex: index,
                            isSelected: scaleAnnotation?.id == annotation.id,
                            onRemove: {
                                removeAnnotation(annotation)
                            },
                            onDoubleTap: {
                                cycleAnnotationSize(annotation)
                            }
                        )
                        .position(
                            x: annotation.position.x * geometry.size.width,
                            y: annotation.position.y * geometry.size.height
                        )
                        .offset(dragAnnotation?.id == annotation.id ? dragOffset : .zero)
                        .scaleEffect(scaleAnnotation?.id == annotation.id ? currentScale * annotation.scaleMultiplier : annotation.scaleMultiplier)
                        .gesture(createCombinedGesture(for: annotation, geometry: geometry))
                    }
                }
            }
            .navigationTitle("足跡編集")
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
                                .fill(Color.blue)
                        )
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                AnnotationControlPanel(
                    annotationCount: annotations.count,
                    onClearAll: {
                        annotations.removeAll()
                    },
                    selectedSize: $selectedFootprintSize,
                    onSizeChanged: { _ in }
                )
            }
        }
        .onAppear {
            loadExistingAnnotations()
        }
        .alert("保存完了", isPresented: $showingSaveConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("\(annotations.count)個の足跡マーカーと共に画像が保存されました。")
        }
    }
    
    private func addAnnotation(at location: CGPoint, in geometry: GeometryProxy) {
        guard annotations.count < 10 else { return }
        
        let relativePosition = CGPoint(
            x: location.x / geometry.size.width,
            y: location.y / geometry.size.height
        )
        
        let annotation = FootprintAnnotation(
            position: relativePosition,
            size: .medium,
            scaleMultiplier: selectedFootprintSize.scale
        )
        
        annotations.append(annotation)
        logger.log("Added footprint annotation at (\(relativePosition.x), \(relativePosition.y))")
    }
    
    private func removeAnnotation(_ annotation: FootprintAnnotation) {
        annotations.removeAll { $0.id == annotation.id }
    }
    
    private func cycleAnnotationSize(_ annotation: FootprintAnnotation) {
        if let index = annotations.firstIndex(where: { $0.id == annotation.id }) {
            let currentScale = annotations[index].scaleMultiplier
            let newScale: CGFloat
            
            if currentScale < 0.8 {
                newScale = 1.0
            } else if currentScale < 1.5 {
                newScale = 2.0
            } else if currentScale < 2.5 {
                newScale = 3.0
            } else {
                newScale = 0.5
            }
            
            annotations[index].scaleMultiplier = newScale
        }
    }
    
    private func createCombinedGesture(for annotation: FootprintAnnotation, geometry: GeometryProxy) -> some Gesture {
        let dragGesture = DragGesture(coordinateSpace: .local)
            .onChanged { value in
                if dragAnnotation == nil {
                    dragAnnotation = annotation
                    scaleAnnotation = nil
                }
                dragOffset = value.translation
            }
            .onEnded { value in
                if let dragAnnotation = dragAnnotation {
                    updateAnnotationPosition(dragAnnotation, offset: value.translation, in: geometry)
                }
                dragAnnotation = nil
                dragOffset = .zero
            }
        
        let scaleGesture = MagnificationGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                if scaleAnnotation == nil {
                    scaleAnnotation = annotation
                    dragAnnotation = nil
                }
                currentScale = value
            }
            .onEnded { value in
                if let scaleAnnotation = scaleAnnotation {
                    updateAnnotationScale(scaleAnnotation, scale: value)
                }
                scaleAnnotation = nil
                currentScale = 1.0
            }
        
        return dragGesture.simultaneously(with: scaleGesture)
    }
    
    private func updateAnnotationPosition(_ annotation: FootprintAnnotation, offset: CGSize, in geometry: GeometryProxy) {
        if let index = annotations.firstIndex(where: { $0.id == annotation.id }) {
            let currentPosition = annotations[index].position
            let offsetX = offset.width / geometry.size.width
            let offsetY = offset.height / geometry.size.height
            
            let newX = max(0, min(1, currentPosition.x + offsetX))
            let newY = max(0, min(1, currentPosition.y + offsetY))
            
            annotations[index].position = CGPoint(x: newX, y: newY)
        }
    }
    
    private func updateAnnotationScale(_ annotation: FootprintAnnotation, scale: CGFloat) {
        if let index = annotations.firstIndex(where: { $0.id == annotation.id }) {
            let currentScale = annotations[index].scaleMultiplier
            let newScale = currentScale * scale
            let clampedScale = max(0.3, min(5.0, newScale))
            annotations[index].scaleMultiplier = clampedScale
        }
    }
    
    private func loadExistingAnnotations() {
        let metadataURL = captureFolderURL.appendingPathComponent("footprint_annotations.json")
        
        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            logger.log("No existing annotations found")
            return
        }
        
        do {
            let data = try Data(contentsOf: metadataURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let metadata = try decoder.decode(AnnotationMetadata.self, from: data)
            annotations = metadata.annotations
            logger.log("Loaded \(annotations.count) existing annotations")
        } catch {
            logger.error("Failed to load existing annotations: \(error)")
        }
    }
    
    private func saveAnnotatedImage() {
        let renderer = ImageRenderer(content: createAnnotatedImageView())
        renderer.scale = UIScreen.main.scale
        
        if let annotatedImage = renderer.uiImage {
            saveImageToFolder(annotatedImage)
        }
    }
    
    private func createAnnotatedImageView() -> some View {
        ZStack {
            Image(uiImage: captureImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            ForEach(Array(annotations.enumerated()), id: \.element.id) { index, annotation in
                FootprintMarker(
                    annotation: annotation,
                    annotationIndex: index,
                    isSelected: false,
                    onRemove: {},
                    onDoubleTap: {}
                )
                .position(
                    x: annotation.position.x * captureImage.size.width,
                    y: annotation.position.y * captureImage.size.height
                )
                .scaleEffect(annotation.scaleMultiplier)
            }
        }
        .frame(width: captureImage.size.width, height: captureImage.size.height)
    }
    
    private func saveImageToFolder(_ image: UIImage) {
        let annotatedImageURL = captureFolderURL.appendingPathComponent("annotated_footprints.jpg")
        
        if let imageData = image.jpegData(compressionQuality: 0.9) {
            do {
                try imageData.write(to: annotatedImageURL)
                
                // Save annotation metadata
                let annotationData = AnnotationMetadata(
                    annotations: annotations,
                    imageSize: CGSize(width: captureImage.size.width, height: captureImage.size.height),
                    timestamp: Date()
                )
                saveAnnotationMetadata(annotationData)
                
                logger.log("Saved annotated image with \(annotations.count) footprints")
            } catch {
                logger.error("Failed to save annotated image: \(error)")
            }
        }
    }
    
    private func saveAnnotationMetadata(_ metadata: AnnotationMetadata) {
        let metadataURL = captureFolderURL.appendingPathComponent("footprint_annotations.json")
        
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
}

struct EditableAnnotatedImageViewer_Previews: PreviewProvider {
    static var previews: some View {
        EditableAnnotatedImageViewer(captureFolderURL: URL(fileURLWithPath: "/tmp"))
    }
}