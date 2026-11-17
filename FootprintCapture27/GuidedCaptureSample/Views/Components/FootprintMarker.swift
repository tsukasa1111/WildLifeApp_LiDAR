import SwiftUI

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
    
    private var scaledIconSize: CGFloat {
        return annotation.size.iconSize * annotation.scaleMultiplier
    }
    
    private var touchAreaSize: CGFloat {
        let baseSize = scaledIconSize + 16
        return max(44, min(80, baseSize))
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.clear)
                .frame(width: touchAreaSize, height: touchAreaSize)
            
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
            
            ZStack {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: scaledIconSize, weight: .bold))
                    .foregroundColor(.black.opacity(0.2))
                    .offset(x: 1, y: 1)
                
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
        }
        .onTapGesture { onTap() }
        .onLongPressGesture { onRemove() }
    }
}

