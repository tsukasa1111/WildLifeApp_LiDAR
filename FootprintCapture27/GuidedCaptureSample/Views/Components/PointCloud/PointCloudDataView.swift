import SwiftUI

struct PointCloudDataView: View {
    let data: String
    let type: PointCloudType
    let pointCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(type.displayName).font(.title2).fontWeight(.bold)
                    Spacer()
                    Text("\(pointCount) points").font(.headline).foregroundColor(.blue)
                }
                Text(type.description).font(.subheadline).foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 8) {
                Text("📄 PLYファイルヘッダー").font(.headline).fontWeight(.semibold)
                let headerLines = data.components(separatedBy: "end_header").first?
                    .components(separatedBy: .newlines) ?? []
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(headerLines.enumerated()), id: \.0) { _, line in
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(line.hasPrefix("comment") ? .green : .primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding(12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("🔢 点群データサンプル（最初の10点）").font(.headline).fontWeight(.semibold)
                let dataLines = data.components(separatedBy: "end_header").dropFirst().first?
                    .components(separatedBy: .newlines).filter { !$0.isEmpty }.prefix(10) ?? []
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(dataLines.enumerated()), id: \.0) { index, line in
                            Text("\(index + 1): \(line)").font(.system(.caption2, design: .monospaced))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 150)
                .padding(12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}
