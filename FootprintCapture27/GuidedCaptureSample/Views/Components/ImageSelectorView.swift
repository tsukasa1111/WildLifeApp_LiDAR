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

// MARK: - Image Selector View

struct ImageSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    let availableImages: [URL]
    @Binding var selectedIndex: Int
    let onSelectionChanged: (Int) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(availableImages.enumerated()), id: \.offset) { index, imageURL in
                    HStack {
                        // サムネイル画像
                        LocalImageThumbnail(url: imageURL, size: 60)
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("画像 \(index + 1)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(imageURL.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if index == selectedIndex {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedIndex = index
                        onSelectionChanged(index)
                        dismiss()
                    }
                }
            }
            .navigationTitle("画像を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

