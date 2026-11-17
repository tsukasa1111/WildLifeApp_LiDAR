import SwiftUI

struct MetadataRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(UIColor.secondaryLabel))

                Text(value)
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.label))
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

