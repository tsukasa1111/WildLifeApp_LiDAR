import SwiftUI

struct AnnotationMarkersOverlay<G: Gesture>: View {
    let annotations: [FootprintAnnotation]
    let selectedId: UUID?
    let scalingId: UUID?
    let draggingId: UUID?
    let dragOffset: CGSize
    let currentScale: CGFloat
    let positionFor: (FootprintAnnotation) -> CGPoint
    let gestureFor: (FootprintAnnotation) -> G
    let onRemove: (FootprintAnnotation) -> Void
    let onDoubleTap: (FootprintAnnotation) -> Void
    let onTap: (FootprintAnnotation) -> Void

    var body: some View {
        ForEach(Array(annotations.enumerated()), id: \.element.id) { index, annotation in
            FootprintMarker(
                annotation: annotation,
                annotationIndex: index,
                isSelected: scalingId == annotation.id || selectedId == annotation.id,
                onRemove: { onRemove(annotation) },
                onDoubleTap: { onDoubleTap(annotation) },
                onTap: { onTap(annotation) }
            )
            .scaleEffect(scalingId == annotation.id ? currentScale : 1)
            .simultaneousGesture(gestureFor(annotation))
            .position(positionFor(annotation))
            .offset(draggingId == annotation.id ? dragOffset : .zero)
        }
    }
}
