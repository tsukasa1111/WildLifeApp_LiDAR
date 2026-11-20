import SwiftUI
import UIKit

struct AnnotationBackgroundImage: View {
    let image: UIImage?
    let onTapAdd: (CGPoint, CGSize) -> Void

    var body: some View {
        Group {
            if let image {
                GeometryReader { imageGeometry in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .contentShape(Rectangle())
                        .accessibilityLabel("足跡を配置する写真")
                        .accessibilityIdentifier("annotation.canvas")
                        .onTapGesture { location in
                            onTapAdd(location, imageGeometry.size)
                        }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
