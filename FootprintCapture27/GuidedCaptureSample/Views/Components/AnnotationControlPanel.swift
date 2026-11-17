import SwiftUI

struct AnnotationControlPanel: View {
    let annotationCount: Int
    let onClearAll: () -> Void
    @Binding var selectedSize: FootprintScaleSize
    let onSizeChanged: (FootprintScaleSize) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
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

