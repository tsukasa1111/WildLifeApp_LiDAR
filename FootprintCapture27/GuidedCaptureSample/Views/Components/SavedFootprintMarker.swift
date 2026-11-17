import SwiftUI

struct SavedFootprintMarker: View {
    let annotation: FootprintAnnotation
    let annotationIndex: Int
    let showBoundingBox: Bool
    
    init(annotation: FootprintAnnotation, annotationIndex: Int, showBoundingBox: Bool = false) {
        self.annotation = annotation
        self.annotationIndex = annotationIndex
        self.showBoundingBox = showBoundingBox
    }
    
    static func calculateSaveSize(for annotation: FootprintAnnotation) -> CGFloat {
        let baseSize = annotation.size.iconSize * annotation.scaleMultiplier
        let sizeBoost: CGFloat
        
        switch annotation.size {
        case .small: sizeBoost = 12.0
        case .medium: sizeBoost = 10.0
        case .large: sizeBoost = 8.0
        }
        
        let minSavedSize: CGFloat = 50
        let maxSavedSize: CGFloat = 1200
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
    
    private var displaySize: CGFloat {
        return SavedFootprintMarker.calculateSaveSize(for: annotation)
    }
    
    var body: some View {
        ZStack {
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
                    .background(Rectangle().fill(annotationColor.opacity(0.05)))
                    .frame(width: bounds.width, height: bounds.height)
            }
            
            footprintIconContent
                .frame(width: displaySize, height: displaySize)
        }
        .frame(
            width: annotation.saveBoundingSize.width,
            height: annotation.saveBoundingSize.height
        )
    }
    
    private var footprintIconContent: some View {
        ZStack {
            Image(systemName: "pawprint.fill")
                .font(.system(size: displaySize, weight: .bold))
                .foregroundColor(.black.opacity(0.2))
                .offset(x: 2, y: 2)
            
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

