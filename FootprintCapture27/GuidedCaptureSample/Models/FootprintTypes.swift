import SwiftUI

// MARK: - Footprint Size Types

enum FootprintScaleSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var scale: CGFloat {
        switch self {
        case .small: return 0.7
        case .medium: return 1.0
        case .large: return 1.4
        }
    }
    
    var label: String {
        switch self {
        case .small: return "小"
        case .medium: return "中"
        case .large: return "大"
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 18
        case .large: return 22
        }
    }
}

enum FootprintSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var label: String {
        switch self {
        case .small: return "小"
        case .medium: return "中"
        case .large: return "大"
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 24
        case .medium: return 32
        case .large: return 40
        }
    }
}

// MARK: - Footprint Model

struct FootprintAnnotation: Identifiable, Codable {
    let id: UUID
    var position: CGPoint // 正規化座標 (0..1)
    var size: FootprintSize
    var scaleMultiplier: CGFloat

    enum CodingKeys: String, CodingKey {
        case id, position, size, scaleMultiplier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        position = try container.decode(CGPoint.self, forKey: .position)
        size = try container.decode(FootprintSize.self, forKey: .size)
        scaleMultiplier = try container.decodeIfPresent(CGFloat.self, forKey: .scaleMultiplier) ?? 1.0
    }
    
    var actualSizeInPixels: CGFloat {
        return size.iconSize * scaleMultiplier
    }
    
    // 足跡の境界情報（表示・保存時の範囲）
    var boundingSize: FootprintBounds {
        let actualSize = actualSizeInPixels
        let padding: CGFloat = 8
        return FootprintBounds(
            width: actualSize + padding * 2,
            height: actualSize + padding * 2,
            iconSize: actualSize
        )
    }
    
    // 保存時の境界情報（大きめサイズ）
    var saveBoundingSize: FootprintBounds {
        let saveSize = SavedFootprintMarker.calculateSaveSize(for: self)
        let padding: CGFloat = 16
        return FootprintBounds(
            width: saveSize + padding * 2,
            height: saveSize + padding * 2,
            iconSize: saveSize
        )
    }
    
    init(position: CGPoint, size: FootprintSize, scaleMultiplier: CGFloat = 1.0, id: UUID = UUID()) {
        self.id = id
        self.position = position
        self.size = size
        self.scaleMultiplier = scaleMultiplier
    }
}

// MARK: - Metadata and Helpers

struct AnnotationMetadata: Codable {
    let annotations: [FootprintAnnotation]
    let imageSize: CGSize
    let timestamp: Date
    let sourceImageName: String?
    
    var sizeStatistics: FootprintSizeStatistics {
        let sizes = annotations.map { $0.actualSizeInPixels }
        return FootprintSizeStatistics(
            totalCount: annotations.count,
            averageSize: sizes.isEmpty ? 0 : sizes.reduce(0, +) / Double(sizes.count),
            minSize: sizes.min() ?? 0,
            maxSize: sizes.max() ?? 0,
            sizeDistribution: Dictionary(grouping: annotations) { annotation in
                annotation.size
            }.mapValues { $0.count }
        )
    }
    
    var totalFootprintArea: Double {
        let imageArea = imageSize.width * imageSize.height
        guard imageArea > 0 else { return 0 }
        let footprintArea = annotations.reduce(0.0) { total, annotation in
            let bounds = annotation.boundingSize
            return total + Double(bounds.width * bounds.height)
        }
        return footprintArea / Double(imageArea)
    }
}

struct FootprintBounds: Codable {
    let width: CGFloat
    let height: CGFloat
    let iconSize: CGFloat
    
    func rect(centeredAt center: CGPoint) -> CGRect {
        return CGRect(
            x: center.x - width / 2,
            y: center.y - height / 2,
            width: width,
            height: height
        )
    }
}

struct FootprintSizeStatistics: Codable {
    let totalCount: Int
    let averageSize: Double
    let minSize: CGFloat
    let maxSize: CGFloat
    let sizeDistribution: [FootprintSize: Int]
    
    var mostCommonSize: FootprintSize? {
        return sizeDistribution.max(by: { $0.value < $1.value })?.key
    }
    
    var sizeVariety: Double {
        let uniqueSizes = Set(sizeDistribution.keys).count
        return Double(uniqueSizes) / max(1.0, Double(totalCount))
    }
}

