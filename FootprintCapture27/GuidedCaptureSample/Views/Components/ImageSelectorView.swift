import SwiftUI
import ImageIO

struct LocalImageThumbnail: View {
    let url: URL
    let size: CGFloat
    @State private var thumbnail: CGImage?
    @State private var finishedLoading = false

    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            if let thumbnail {
                Image(decorative: thumbnail, scale: 1.0)
                    .resizable()
                    .scaledToFill()
            } else if finishedLoading {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            } else {
                ProgressView()
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .task(id: url) {
            thumbnail = nil
            finishedLoading = false
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: Int(size * 2)
            ]
            if let source = CGImageSourceCreateWithURL(url as CFURL, nil) {
                thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
            }
            finishedLoading = true
        }
    }
}

struct ImageSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    let availableImages: [URL]
    @Binding var selectedIndex: Int
    var onSelectionChanged: ((Int) -> Void)? = nil

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 160 : 96))], spacing: 16) {
                        ForEach(Array(availableImages.enumerated()), id: \.element) { index, url in
                            Button {
                                selectedIndex = index
                                onSelectionChanged?(index)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    LocalImageThumbnail(url: url, size: 92)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(alignment: .topTrailing) {
                                            if index == selectedIndex {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .symbolRenderingMode(.palette)
                                                    .foregroundStyle(.white, .blue)
                                                    .padding(4)
                                            }
                                        }
                                    Text("写真 \(index + 1)").font(.subheadline)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("写真 \(index + 1)")
                            .accessibilityAddTraits(index == selectedIndex ? .isSelected : [])
                            .id(url)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    if availableImages.indices.contains(selectedIndex) {
                        proxy.scrollTo(availableImages[selectedIndex], anchor: .center)
                    }
                }
            }
            .navigationTitle("画像を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}
