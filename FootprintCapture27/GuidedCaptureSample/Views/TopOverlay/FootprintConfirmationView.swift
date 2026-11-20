import SwiftUI

struct GC_FootprintConfirmationView: View {
    let availableImages: [URL]
    let captureFolderManager: CaptureFolderManager
    let onDismiss: () -> Void

    private let initialImageName: String?
    @State private var selectedImageIndex: Int
    @State private var loadedURL: URL?
    @State private var originalImage: UIImage?
    @State private var markedImage: UIImage?
    @State private var markedSourceName: String?
    @State private var showImageSelector = false
    @State private var showFootprintEditor = false

    init(availableImages: [URL], initialSelectedIndex: Int, captureFolderManager: CaptureFolderManager, onDismiss: @escaping () -> Void) {
        self.availableImages = availableImages
        self.captureFolderManager = captureFolderManager
        self.onDismiss = onDismiss
        let savedName = captureFolderManager.loadAnnotationMetadata()?.sourceImageName
        let index = availableImages.firstIndex { $0.lastPathComponent == savedName }
            ?? max(0, min(initialSelectedIndex, availableImages.count - 1))
        _selectedImageIndex = State(initialValue: index)
        initialImageName = availableImages.indices.contains(index) ? availableImages[index].lastPathComponent : nil
    }

    private var selectedURL: URL? {
        availableImages.indices.contains(selectedImageIndex) ? availableImages[selectedImageIndex] : nil
    }

    private var showsMarkedImage: Bool {
        markedImage != nil && selectedURL?.lastPathComponent == markedSourceName
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ZStack {
                    Color.black
                    if let image = showsMarkedImage ? markedImage : (loadedURL == selectedURL ? originalImage : nil) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .accessibilityLabel(showsMarkedImage ? "印を保存した写真" : "撮影した写真")
                    } else if loadedURL != selectedURL {
                        ProgressView().tint(.white)
                    } else {
                        ContentUnavailableView("写真を開けませんでした", systemImage: "photo")
                            .environment(\.colorScheme, .dark)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("写真 \(availableImages.isEmpty ? 0 : selectedImageIndex + 1) / \(availableImages.count)")
                            .font(.headline.monospacedDigit())
                        Spacer()
                        Text(showsMarkedImage ? "マーキング済み" : "元の写真")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Button("画像を選択") { showImageSelector = true }
                            .buttonStyle(.bordered)
                            .disabled(availableImages.isEmpty)
                        Spacer()
                        Button("足跡を編集") { showFootprintEditor = true }
                            .buttonStyle(.borderedProminent)
                            .disabled(originalImage == nil || loadedURL != selectedURL)
                    }
                    .controlSize(.large)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("足跡画像確認")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: onDismiss)
                }
            }
            .sheet(isPresented: $showImageSelector) {
                ImageSelectorView(availableImages: availableImages, selectedIndex: $selectedImageIndex)
            }
            .sheet(isPresented: $showFootprintEditor) {
                if let originalImage, let selectedURL, loadedURL == selectedURL {
                    FootprintAnnotationView(captureImage: originalImage, captureFolderManager: captureFolderManager,
                                           sourceImageName: selectedURL.lastPathComponent,
                                           legacySourceImageName: initialImageName, onSaveComplete: reloadMarkup)
                }
            }
        }
        .onAppear { reloadMarkup() }
        .task(id: selectedURL) {
            guard let url = selectedURL else { return }
            let image = await Self.readImage(url)
            guard !Task.isCancelled && selectedURL == url else { return }
            originalImage = image
            loadedURL = url
        }
    }

    private nonisolated static func readImage(_ url: URL) async -> UIImage? {
        UIImage(contentsOfFile: url.path)
    }

    private func reloadMarkup() {
        let url = captureFolderManager.captureFolder.appendingPathComponent(CaptureFolderManager.annotatedImageFileName)
        markedImage = UIImage(contentsOfFile: url.path)
        // Earlier recordings didn't store a source name. Keep their existing initial preview.
        let metadata = captureFolderManager.loadAnnotationMetadata()
        markedSourceName = metadata?.sourceImageName ?? initialImageName
        if metadata?.annotations.isEmpty == true { markedImage = nil }
    }
}
