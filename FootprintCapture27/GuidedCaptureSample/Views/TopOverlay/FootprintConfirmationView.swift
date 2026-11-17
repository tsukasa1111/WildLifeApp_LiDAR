import SwiftUI

struct GC_FootprintConfirmationView: View {
    let availableImages: [URL]
    @State private var selectedImageIndex: Int
    let captureFolderManager: CaptureFolderManager
    let onDismiss: () -> Void
    
    @State private var currentImage: UIImage?
    @State private var annotatedImage: UIImage?
    @State private var isLoadingImage = false
    @State private var showImageSelector = false
    @State private var showFootprintEditor = false
    @State private var userHasSelectedImage = false
    
    init(availableImages: [URL], initialSelectedIndex: Int, captureFolderManager: CaptureFolderManager, onDismiss: @escaping () -> Void) {
        self.availableImages = availableImages
        self.captureFolderManager = captureFolderManager
        self.onDismiss = onDismiss
        self._selectedImageIndex = State(initialValue: min(initialSelectedIndex, availableImages.count - 1))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
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
                SwiftUI.ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { onDismiss() }
                }
                SwiftUI.ToolbarItem(placement: .navigationBarTrailing) {
                    Button("更新") { checkForAnnotatedImage() }
                }
            }
        }
        .onAppear {
            checkForAnnotatedImage()
            loadSelectedImage()
        }
        .onChange(of: selectedImageIndex) { _, _ in
            loadSelectedImage()
        }
        .sheet(isPresented: $showImageSelector) {
            GC_CustomImageSelectorView(
                availableImages: availableImages,
                selectedIndex: $selectedImageIndex,
                onSelectionChanged: { index in
                    selectedImageIndex = index
                    userHasSelectedImage = true
                    showImageSelector = false
                },
                onConfirm: { index in
                    selectedImageIndex = index
                    userHasSelectedImage = true
                    showImageSelector = false
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
                    onSaveComplete: { checkForAnnotatedImage() }
                )
                .onDisappear { checkForAnnotatedImage() }
            }
        }
    }
    
    private func loadSelectedImage() {
        guard selectedImageIndex < availableImages.count else { return }
        isLoadingImage = true
        let imageURL = availableImages[selectedImageIndex]
        Task {
            let image = await loadImage(from: imageURL)
            await MainActor.run {
                self.currentImage = image
                self.isLoadingImage = false
            }
        }
    }
    
    private func loadImage(from url: URL) async -> UIImage? {
        do {
            let data = try Data(contentsOf: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
    
    private func checkForAnnotatedImage() {
        let annotatedImageURL = captureFolderManager.captureFolder.appendingPathComponent("annotated_footprints.jpg")
        annotatedImage = nil
        if FileManager.default.fileExists(atPath: annotatedImageURL.path) {
            if let imageData = try? Data(contentsOf: annotatedImageURL),
               let image = UIImage(data: imageData) {
                annotatedImage = image
            }
        }
    }
}
