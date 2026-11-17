import SwiftUI
import UIKit

enum OrientationTransform {
    static func correctImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    static func transform(location: CGPoint, for image: UIImage, in size: CGSize) -> CGPoint {
        switch image.imageOrientation {
        case .up:
            return location
        case .down:
            return CGPoint(x: size.width - location.x, y: size.height - location.y)
        case .left:
            return CGPoint(x: location.y, y: size.width - location.x)
        case .right:
            return CGPoint(x: size.height - location.y, y: location.x)
        case .upMirrored:
            return CGPoint(x: size.width - location.x, y: location.y)
        case .downMirrored:
            return CGPoint(x: location.x, y: size.height - location.y)
        case .leftMirrored:
            return CGPoint(x: size.height - location.y, y: size.width - location.x)
        case .rightMirrored:
            return CGPoint(x: location.y, y: location.x)
        @unknown default:
            return location
        }
    }

    static func reverse(position: CGPoint, for image: UIImage, in size: CGSize) -> CGPoint {
        switch image.imageOrientation {
        case .up:
            return position
        case .down:
            return CGPoint(x: size.width - position.x, y: size.height - position.y)
        case .left:
            return CGPoint(x: size.width - position.y, y: position.x)
        case .right:
            return CGPoint(x: position.y, y: size.height - position.x)
        case .upMirrored:
            return CGPoint(x: size.width - position.x, y: position.y)
        case .downMirrored:
            return CGPoint(x: position.x, y: size.height - position.y)
        case .leftMirrored:
            return CGPoint(x: size.width - position.y, y: size.height - position.x)
        case .rightMirrored:
            return CGPoint(x: position.y, y: position.x)
        @unknown default:
            return position
        }
    }
}

