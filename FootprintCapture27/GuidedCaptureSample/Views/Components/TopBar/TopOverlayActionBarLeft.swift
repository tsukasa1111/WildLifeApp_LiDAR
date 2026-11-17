import SwiftUI
import RealityKit
import UIKit

struct TopOverlayActionBarLeft: View {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession
    @Binding var showCaptureFolders: Bool
    var showCaptureFolderButton: Bool

    private var buttonHeight: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 42 : 34
    }

    private var buttonBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.6),
                Color.white.opacity(0.25),
                Color.white.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .heavy))
                    Text("キャンセル")
                        .font(.callout.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .frame(minHeight: buttonHeight)
                .background(
                    Capsule()
                        .fill(.thinMaterial.opacity(0.85))
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    Capsule()
                        .stroke(buttonBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()

            if showCaptureFolderButton {
                Button(action: { showCaptureFolders = true }) {
                    Image(systemName: "folder")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: buttonHeight, height: buttonHeight)
                        .background(
                            RoundedRectangle(cornerRadius: buttonHeight / 2)
                                .fill(.thinMaterial.opacity(0.65))
                                .environment(\.colorScheme, .dark)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: buttonHeight / 2)
                                .stroke(buttonBorder, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func onCancel() {
        // Mirror existing behavior in original cancel button
        if let ocSession = appModel.objectCaptureSession, ocSession.state != .completed {
            switch ocSession.state {
            case .failed(_): break
            default: ocSession.cancel()
            }
        } else {
            // Fallback to provided session reference
            if session.state != .completed {
                switch session.state {
                case .failed(_): break
                default: session.cancel()
                }
            }
        }
        appModel.removeCaptureFolder()
    }
}
