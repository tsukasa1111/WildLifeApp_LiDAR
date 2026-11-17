import CoreGraphics

enum ImageDisplayRect {
    // Aspect-Fit rectangle of an image within a container size.
    static func aspectFitRect(imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, containerSize.width > 0, containerSize.height > 0 else {
            return .zero
        }

        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height

        if imageAspect > containerAspect {
            // Fit by width
            let displayHeight = containerSize.width / imageAspect
            let yOffset = (containerSize.height - displayHeight) / 2
            return CGRect(x: 0, y: yOffset, width: containerSize.width, height: displayHeight)
        } else {
            // Fit by height
            let displayWidth = containerSize.height * imageAspect
            let xOffset = (containerSize.width - displayWidth) / 2
            return CGRect(x: xOffset, y: 0, width: displayWidth, height: containerSize.height)
        }
    }
}

