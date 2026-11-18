import SwiftUI

struct MetadataCard: View {
    let metadata: TraceMetadata

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.green.opacity(0.2)).frame(width: 44, height: 44)
                    Image(systemName: "pawprint.fill").font(.system(size: 20, weight: .semibold)).foregroundColor(.green)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(metadata.hasFootprint ? (metadata.animalType.isEmpty ? "動物未記録" : metadata.animalType) : "調査地点").font(.headline).fontWeight(.semibold).foregroundColor(Color(UIColor.label))
                    Text(formatTimestamp(metadata.timestamp)).font(.subheadline).foregroundColor(Color(UIColor.systemGray))
                }
                Spacer()
            }

            VStack(spacing: 12) {
                MetadataRow(icon: "pawprint.fill", title: "痕跡の種類", value: metadata.traceType, color: .green)

                if let weather = metadata.weather {
                    MetadataRow(icon: "cloud.sun.fill", title: "天候", value: weather, color: .orange)
                }

                if let substrate = metadata.substrate {
                    let softnessText = getSoftnessText(from: substrate)
                    MetadataRow(icon: "hand.point.down.fill", title: "地面の柔らかさ", value: softnessText, color: .brown)
                }


                if let notes = metadata.notes, !notes.isEmpty {
                    MetadataRow(icon: "note.text", title: "備考", value: notes, color: .gray)
                }

                if let location = metadata.location {
                    Divider().padding(.vertical, 4)
                    let locationText = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
                    MetadataRow(icon: "location.fill", title: "位置情報", value: locationText, color: .red)
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func getSoftnessText(from value: String) -> String {
        if let level = Int(value) {
            switch level {
            case 1: return "非常に硬い"
            case 2: return "硬い"
            case 3: return "普通"
            case 4: return "柔らかい"
            case 5: return "非常に柔らかい"
            default: return value
            }
        }
        return value
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

