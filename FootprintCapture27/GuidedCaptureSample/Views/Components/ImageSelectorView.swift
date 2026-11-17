import SwiftUI

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
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(8)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.7)
                                )
                        }
                        
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

