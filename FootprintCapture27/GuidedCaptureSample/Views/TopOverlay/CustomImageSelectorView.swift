import SwiftUI

struct GC_CustomImageSelectorView: View {
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
                                    .overlay(ProgressView().tint(.blue))
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
                    Button("キャンセル") { dismiss() }
                        .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") { showCustomConfirmation = true }
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showCustomConfirmation) {
            GC_CustomConfirmationDialog(
                selectedIndex: selectedIndex,
                onConfirm: { index in onConfirm(index) },
                onCancel: { showCustomConfirmation = false }
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
    }
}
