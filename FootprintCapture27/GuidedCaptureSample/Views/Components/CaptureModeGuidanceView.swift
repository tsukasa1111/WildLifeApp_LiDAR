import SwiftUI

struct CaptureModeGuidanceView: View {
    @EnvironmentObject var appModel: AppDataModel

    var body: some View {
        Text(guidanceText)
            .font(.subheadline)
            .bold()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
    }

    private var guidanceText: String {
        switch appModel.captureMode {
        case .object:
            return LocalizedString.objectMode
        case .area:
            return LocalizedString.areaMode
        }
    }

    private struct LocalizedString {
        static let areaMode = NSLocalizedString(
            "Area mode (Object Capture)",
            bundle: Bundle.main,
            value: "エリアモード",
            comment: "Title for the Area Mode guidance text.")

        static let objectMode = NSLocalizedString(
            "Object mode (Object Capture)",
            bundle: Bundle.main,
            value: "オブジェクトモード",
            comment: "Title for the Object Mode guidance text.")
    }
}

