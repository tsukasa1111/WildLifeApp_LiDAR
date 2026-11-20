/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Bottom overlay button implementation for capture overlay view.
*/

import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "BottomOverlayButtons")

struct BottomOverlayButtons: View, OverlayButtons {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession
    @Binding var hasDetectionFailed: Bool
    @Binding var showCaptureModeGuidance: Bool
    @Binding var showTutorialView: Bool
    var rotationAngle: Angle

    var body: some View {
        HStack(alignment: .center) {
            HStack {
                switch session.state {
                    case .ready:
                        HelpButton()
                            .frame(width: 30)
                    case .detecting:
                        ResetBoundingBoxButton(session: session)
                    default:
                        NumOfImagesButton(session: session)
                            .rotationEffect(rotationAngle)
                        Spacer()
                }
            }
            .frame(maxWidth: .infinity)

            if !isCapturingStarted(state: session.state) {
                CaptureButton(session: session,
                              hasDetectionFailed: $hasDetectionFailed,
                              showTutorialView: $showTutorialView)
                    .frame(width: 200)
            }

            HStack {
                switch session.state {
                    case .ready:
                    // モード切り替えボタンを無効化（エリアモード限定）
                    /*
                    if appModel.orbit == .orbit1 {
                        CaptureModeButton(session: session,
                                          showCaptureModeGuidance: $showCaptureModeGuidance)
                            .frame(width: 30)
                    }
                    */
                    EmptyView() // プレースホルダー
                    case .detecting:
                        AutoDetectionStateView(session: session)
                    default:
                        HStack {
                            Spacer()
                            ManualShotButton(isEnabled: session.canRequestImageCapture) {
                                session.requestImageCapture()
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .transition(.opacity)
    }
}

@MainActor
private struct CaptureButton: View {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession
    @Binding var hasDetectionFailed: Bool
    @Binding var showTutorialView: Bool

    var body: some View {
        Button(
            action: {
                performAction()
            },
            label: {
                CaptureStartLabel(title: buttonLabel)
            })
    }

    private var buttonLabel: String {
        if session.state == .ready {
            switch appModel.captureMode {
                case .object:
                    return LocalizedString.continue
                case .area:
                    return LocalizedString.startCapture
            }
        } else {
            if !appModel.isObjectFlipped {
                return LocalizedString.startCapture
            } else {
                return LocalizedString.continue
            }
        }
    }

    private func performAction() {
        if session.state == .ready {
            // 撮影開始時に位置情報を保存
            appModel.captureScanStartLocation()
            
            switch appModel.captureMode {
            case .object:
                hasDetectionFailed = !(session.startDetecting())
            case .area:
                session.startCapturing()
            }
        } else if case .detecting = session.state {
            session.startCapturing()
        }
    }

    struct LocalizedString {
        static let startCapture = NSLocalizedString(
            "Start Capture (Object Capture)",
            bundle: Bundle.main,
            value: "撮影開始",
            comment: "Title for the Start Capture button on the object capture screen.")
        static let `continue` = NSLocalizedString(
            "Continue (Object Capture, Capture)",
            bundle: Bundle.main,
            value: "続ける",
            comment: "Title for the Continue button on the object capture screen.")
    }
}

struct CaptureStartLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.body)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
            .background(
                Capsule()
                    .fill(.thinMaterial.opacity(0.7))
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.9),
                                        Color.blue.opacity(0.6),
                                        Color.blue.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    )
                    .overlay(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.4),
                                        Color.blue.opacity(0.2)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
            .environment(\.colorScheme, .dark)
            .shadow(color: .blue.opacity(0.6), radius: 15, x: 0, y: 8)
    }
}

private struct AutoDetectionStateView: View {
    var session: ObjectCaptureSession

    var body: some View {
        VStack(spacing: 6) {
            let imageName = session.feedback.contains(.objectNotDetected) ? "eye.slash.circle" : "eye.circle"
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(5)
                .frame(width: 30)
            if UIDevice.current.userInterfaceIdiom == .pad {
                let text = session.feedback.contains(.objectNotDetected) ? "未検出" : "検出済み"
                Text(text)
                    .frame(width: 90)
                    .font(.footnote)
                    .opacity(0.7)
                    .fontWeight(.semibold)
            }
        }
        .foregroundColor(.white)
        .fontWeight(.semibold)
        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 0 : 15)
    }
}

private struct ResetBoundingBoxButton: View {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession

    var body: some View {
        Button(
            action: {
                session.resetDetection()
            },
            label: {
                VStack(spacing: 6) {
                    Image("ResetBbox")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30)

                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Text(LocalizedString.resetBox)
                            .font(.footnote)
                            .opacity(0.7)
                    }
                }
                .foregroundColor(.white)
                .fontWeight(.semibold)
            })
        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 0 : 15)
    }

    struct LocalizedString {
        static let resetBox = NSLocalizedString(
            "Reset Box (Object Capture)",
            bundle: Bundle.main,
            value: "ボックスをリセット",
            comment: "Title for the Reset Box button on the object capture screen."
        )
    }
}

struct ManualShotButton: View {
    let isEnabled: Bool
    let takeShot: () -> Void

    var body: some View {
        Button(action: takeShot) {
            Image(systemName: "camera.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(isEnabled ? Color.white : Color.gray)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("写真を1枚撮影")
        .disabled(!isEnabled)
    }
}

private struct HelpButton: View {
    @EnvironmentObject var appModel: AppDataModel
    @State private var showHelpPageView: Bool = false

    var body: some View {
        Button(action: {
            logger.log("\(LocalizedString.help) button clicked!")
            withAnimation {
                showHelpPageView = true
            }
        }, label: {
            ZStack {
                // Glass background effect
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial.opacity(0.6))
                    .environment(\.colorScheme, .dark)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        })
        .sheet(isPresented: $showHelpPageView) {
            HelpPageView(showHelpPageView: $showHelpPageView)
                .padding()
        }
        .onChange(of: showHelpPageView) {
            appModel.setShowOverlaySheets(to: showHelpPageView)
        }
    }

    struct LocalizedString {
        static let help = NSLocalizedString(
            "Help (Object Capture)",
            bundle: Bundle.main,
            value: "ヘルプ",
            comment: "Title for the Help button on the object capture screen to show the tutorial pages.")
    }
}

// モード切り替えボタンをコメントアウト（エリアモード限定のため）
/*
private struct CaptureModeButton: View {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession
    @Binding var showCaptureModeGuidance: Bool
    @State private var captureModeGuidanceTimer: Timer? = nil
    
    private var modeColors: [Color] {
        switch appModel.captureMode {
        case .area:
            return [Color.green.opacity(0.8), Color.green.opacity(0.4), Color.green.opacity(0.2)]
        case .object:
            return [Color.orange.opacity(0.8), Color.orange.opacity(0.4), Color.orange.opacity(0.2)]
        }
    }

    var body: some View {
        Button(action: {
            switch appModel.captureMode {
                case .object:
                    DispatchQueue.main.async {
                        logger.log("Area mode selected!")
                        appModel.captureMode = .area
                    }
                case .area:
                    DispatchQueue.main.async {
                        logger.log("Object mode selected!")
                        appModel.captureMode = .object
                    }
            }
            logger.log("Setting showCaptureModeGuidance to true")
            withAnimation {
                showCaptureModeGuidance = true
            }
            // Cancel the previous scheduled timer.
            if captureModeGuidanceTimer != nil {
                captureModeGuidanceTimer?.invalidate()
                captureModeGuidanceTimer = nil
            }
            captureModeGuidanceTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) {_ in
                logger.log("Setting showCaptureModeGuidance to false")
                withAnimation {
                    showCaptureModeGuidance = false
                }
            }
        }, label: {
            ZStack {
                // Glass background effect with mode-specific color
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial.opacity(0.6))
                    .environment(\.colorScheme, .dark)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: modeColors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: modeColors[0].opacity(0.5), radius: 12, x: 0, y: 6)
                
                VStack {
                    switch appModel.captureMode {
                        case .area:
                            Image(systemName: "circle.dashed")
                                .font(.system(size: 16, weight: .semibold))
                        case .object:
                            Image(systemName: "cube")
                                .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
            }
        })
    }
}
*/

private struct NumOfImagesButton: View {
    var session: ObjectCaptureSession

    @State private var showInfo: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            showInfo = true
        },
               label: {
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .padding([.horizontal, .top], 4)
                    .overlay(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
                        if session.feedback.contains(.overCapturing) {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.orange)
                                .font(.caption2)
                        }
                    }
                Text(String(format: LocalizedString.numOfImages,
                            session.numberOfShotsTaken,
                            session.maximumNumberOfInputImages))
                .font(.footnote)
                .fontWidth(.condensed)
                .fontDesign(.rounded)
                .bold()
            }
            .foregroundColor(.white)
        })
        .popover(isPresented: $showInfo) {
            VStack(alignment: .leading, spacing: 20) {
                Label(LocalizedString.photoLimit, systemImage: "photo")
                    .font(.headline)
                Text(String(format: LocalizedString.createModelLimits,
                            AppDataModel.minNumImages,
                            session.maximumNumberOfInputImages))
                Text(String(format: LocalizedString.captureMore,
                            session.maximumNumberOfInputImages))
            }
            .foregroundStyle(colorScheme == .light ? .black : .white)
            .padding()
            .frame(idealWidth: UIDevice.current.userInterfaceIdiom == .pad ? 300 : .infinity)
            .presentationDetents([.fraction(0.3)])
        }
    }

    struct LocalizedString {
        static let numOfImages = NSLocalizedString(
            "%d/%d (Format, # of Images)",
            bundle: Bundle.main,
            value: "%d/%d",
            comment: "Images taken over maximum number of images.")
        static let photoLimit = NSLocalizedString(
            "Photo limit (Object Capture)",
            bundle: Bundle.main,
            value: "写真制限",
            comment: "Title for photo limit popover.")
        static let createModelLimits = NSLocalizedString(
            "To create a model on device you need a minimum of %d images and a maximum of %d images. (Object Capture)",
            bundle: Bundle.main,
            value: "デバイスでモデルを作成するには最低%d枚、最大%d枚の写真が必要です。",
            comment: "Text to explain the photo limits in object capture.")
        static let captureMore = NSLocalizedString(
            "You can capture more than %d images and process them on your Mac. (Object Capture)",
            bundle: Bundle.main,
            value: "%d枚以上の写真を撮影してMacで処理することもできます。",
            comment: "Text to explain the photo limit in object capture.")
    }
}
