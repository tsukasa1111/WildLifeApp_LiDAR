import SwiftUI
import CoreLocation

// MARK: - LocationInfoRow Component

struct LocationInfoRow: View {
    let location: CLLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("座標", systemImage: "location")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(location.coordinate.latitude, specifier: "%.6f"), \(location.coordinate.longitude, specifier: "%.6f")")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            HStack {
                Label("標高", systemImage: "mountain.2")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(location.altitude, specifier: "%.1f") m")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            HStack {
                Label("精度", systemImage: "target")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("± \(location.horizontalAccuracy, specifier: "%.1f") m")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 8)
    }
}

