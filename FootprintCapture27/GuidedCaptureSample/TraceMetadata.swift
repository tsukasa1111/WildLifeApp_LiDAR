/*
Trace Metadata
動物痕跡のメタデータ構造体
*/

import Foundation
import CoreLocation

struct TraceMetadata: Codable, Identifiable {
    let id: UUID
    let hasFootprint: Bool
    let animalType: String
    let traceType: String
    let weather: String?
    let substrate: String?
    let notes: String?
    let location: CLLocation?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, hasFootprint, animalType, traceType, weather, substrate, notes, timestamp
        case latitude, longitude, altitude, horizontalAccuracy, verticalAccuracy
    }
    
    init(hasFootprint: Bool, animalType: String, traceType: String, weather: String? = nil, substrate: String? = nil, notes: String? = nil, location: CLLocation? = nil, timestamp: Date = Date(), id: UUID = UUID()) {
        self.id = id
        self.hasFootprint = hasFootprint
        self.animalType = animalType
        self.traceType = traceType
        self.weather = weather
        self.substrate = substrate
        self.notes = notes
        self.location = location
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        hasFootprint = try container.decodeIfPresent(Bool.self, forKey: .hasFootprint) ?? true
        animalType = try container.decode(String.self, forKey: .animalType)
        traceType = try container.decode(String.self, forKey: .traceType)
        weather = try container.decodeIfPresent(String.self, forKey: .weather)
        substrate = try container.decodeIfPresent(String.self, forKey: .substrate)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        // Flexible timestamp decoding to handle various formats
        do {
            // Try standard Date decoding first (works with ISO8601 when decoder strategy is set)
            timestamp = try container.decode(Date.self, forKey: .timestamp)
        } catch {
            // Fallback: try Double (Unix timestamp)
            if let timestampDouble = try? container.decode(Double.self, forKey: .timestamp) {
                timestamp = Date(timeIntervalSince1970: timestampDouble)
            } else if let timestampString = try? container.decode(String.self, forKey: .timestamp) {
                // Fallback: try ISO8601 string format manually
                let formatter = ISO8601DateFormatter()
                timestamp = formatter.date(from: timestampString) ?? Date()
            } else {
                // Ultimate fallback
                timestamp = Date()
            }
        }
        
        // Decode location if present
        if let latitude = try container.decodeIfPresent(Double.self, forKey: .latitude),
           let longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) {
            let altitude = try container.decodeIfPresent(Double.self, forKey: .altitude) ?? 0
            let horizontalAccuracy = try container.decodeIfPresent(Double.self, forKey: .horizontalAccuracy) ?? 0
            let verticalAccuracy = try container.decodeIfPresent(Double.self, forKey: .verticalAccuracy) ?? 0
            
            location = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                altitude: altitude,
                horizontalAccuracy: horizontalAccuracy,
                verticalAccuracy: verticalAccuracy,
                timestamp: timestamp
            )
        } else {
            location = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(hasFootprint, forKey: .hasFootprint)
        try container.encode(animalType, forKey: .animalType)
        try container.encode(traceType, forKey: .traceType)
        try container.encodeIfPresent(weather, forKey: .weather)
        try container.encodeIfPresent(substrate, forKey: .substrate)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(timestamp, forKey: .timestamp)
        
        // Encode location if present
        if let location = location {
            try container.encode(location.coordinate.latitude, forKey: .latitude)
            try container.encode(location.coordinate.longitude, forKey: .longitude)
            try container.encode(location.altitude, forKey: .altitude)
            try container.encode(location.horizontalAccuracy, forKey: .horizontalAccuracy)
            try container.encode(location.verticalAccuracy, forKey: .verticalAccuracy)
        }
    }
}
