/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Full-screen overlay UI with buttons to control the capture, intended to placed in a `ZStack` over the `ObjectCaptureView`.
*/

import AVFoundation
import RealityKit
import SwiftUI
import os
import simd

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "CaptureOverlayView")

struct CaptureOverlayView: View {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession

    // Reads persistently from the System settings where users can toggle it on/off once they
    // no longer feel they need it.
    @AppStorage("show_tutorials") var areTutorialsEnabledInUserSettings: Bool = false
    
    @State private var showCaptureModeGuidance: Bool = false
    @State private var hasDetectionFailed = false
    @State private var showTutorialView = false
    @State private var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
    @State private var captureTimer: Timer?

    var body: some View {
        ZStack {
            if areTutorialsEnabledInUserSettings, showTutorialView, let url = tutorialURL {
                TutorialView(url: url, showTutorialView: $showTutorialView)
            } else {
                VStack(spacing: 20) {
                        // 撮影進捗プログレスバー
                        if session.state == .capturing {
                            CaptureProgressBar(session: session)
                            CaptureStatusIndicator(session: session)
                        }
                        
                        TopOverlayButtons(session: session,
                                          showCaptureModeGuidance: showCaptureModeGuidance)

                        Spacer()

                        BoundingBoxGuidanceView(session: session, hasDetectionFailed: hasDetectionFailed)

                        BottomOverlayButtons(session: session,
                                             hasDetectionFailed: $hasDetectionFailed,
                                             showCaptureModeGuidance: $showCaptureModeGuidance,
                                             showTutorialView: $showTutorialView,
                                             rotationAngle: rotationAngle)
                }
                .padding()
                .padding(.horizontal, 15)
                .background {
                    VStack {
                        Spacer().frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 65 : 25)

                        FeedbackView(messageList: appModel.messageList)
                            .layoutPriority(1)
                    }
                    .rotationEffect(rotationAngle)
                }
                .task {
                    for await _ in NotificationCenter.default.notifications(named: UIDevice.orientationDidChangeNotification) {
                        withAnimation {
                            deviceOrientation = UIDevice.current.orientation
                        }
                    }
                }
                .onAppear {
                    startFrequentCapture()
                }
                .onDisappear {
                    captureTimer?.invalidate()
                    captureTimer = nil
                }
                .onChange(of: session.state) { _, newState in
                    if newState == .capturing {
                        startFrequentCapture()
                        
                        if !appModel.tutorialPlayedOnce {
                            // Start the tutorial video which will pause the capture while visible.
                            withAnimation {
                                logger.log("Setting showTutorialView to true")
                                showTutorialView = true
                            }
                            appModel.tutorialPlayedOnce = true
                        }
                    }
                }
            }
        }
        // When camera tracking isn't normal, display the AR coaching view and hide the overlay view.
        .opacity(shouldShowOverlayView ? 1.0 : 0.0)
    }

    private var shouldShowOverlayView: Bool {
        return showTutorialView || (session.cameraTracking == .normal && !session.isPaused)
    }
    
    private func startFrequentCapture() {
        // 既存のタイマーをクリア
        captureTimer?.invalidate()
        
        // スキャン中のみ頻繁キャプチャを実行
        guard session.state == .capturing else { return }
        
        // TODO: isAutoCaptureEnabled プロパティが利用できないため一時的に無効化
        // session.isAutoCaptureEnabled = true
        
        // さらに手動キャプチャも併用して最大頻度にする
        let captureSession = session
        captureTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            Task { @MainActor in
                guard captureSession.state == .capturing else {
                    timer.invalidate()
                    return
                }
                guard !captureSession.isPaused else { return }
                captureSession.requestImageCapture()
            }
        }
    }
    

    private var tutorialURL: URL? {
        let interfaceIdiom = UIDevice.current.userInterfaceIdiom
        var videoName: String? = nil
        switch appModel.captureMode {
        case .area:
            videoName = interfaceIdiom == .pad ? "ScanTutorial-iPad-Area" : "ScanTutorial-iPhone-Area"
        case .object:
            videoName = interfaceIdiom == .pad ? "ScanPasses-iPad-FixedHeight-1" : "ScanPasses-iPhone-FixedHeight-1"
        }
        guard let videoName = videoName else { return nil }
        return Bundle.main.url(forResource: videoName, withExtension: "mp4")
    }

    private var rotationAngle: Angle {
        switch deviceOrientation {
            case .landscapeLeft:
                return Angle(degrees: 90)
            case .landscapeRight:
                return Angle(degrees: -90)
            case .portraitUpsideDown:
                return Angle(degrees: 180)
            default:
                return Angle(degrees: 0)
        }
    }
}

private struct TutorialView: View {
    @EnvironmentObject var appModel: AppDataModel
    var url: URL
    @Binding var showTutorialView: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isVisible = false
    
    /// How long to delay the animation start once the tutorial view is dimmed.
    private let delay: TimeInterval = 0.3
    
    /// How much of the end of the animation to trim off.
    private let reducedTutorialAnimationTime: TimeInterval = 2.0

    var body: some View {
        VStack {
            Spacer()
            TutorialVideoView(url: url, isInReviewSheet: false)
                .frame(maxHeight: horizontalSizeClass == .regular ? 350 : 280)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.thinMaterial.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 25, x: 0, y: 12)
                )
                .overlay(alignment: .bottom) {
                    if appModel.captureMode == .object {
                        Text(LocalizedString.tutorialText)
                            .font(.headline)
                            .padding(.bottom, appModel.captureMode == .object ? 16 : 0)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                    }
                }
            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .background(.thinMaterial.opacity(0.9))
        .allowsHitTesting(false)
        .onAppear {
            // Let the screen dim before the animation tutorial plays.
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Pause the capture session while the tutorial plays to reduce visual clutter
                // and avoid taking shots while the screen is covered.
                logger.log("Tutorial onAppear() is pausing the session...")
                appModel.objectCaptureSession?.pause()

                withAnimation {
                    isVisible = true
                }
            }
        }
        .onDisappear {
            // Resume the capture session once the tutorial is done.
            logger.log("Tutorial onDisappear() is resuming the session...")
            appModel.objectCaptureSession?.resume()
        }
        .task {
            let animationDuration = try? await AVURLAsset(url: url).load(.duration).seconds - reducedTutorialAnimationTime
            DispatchQueue.main.asyncAfter(deadline: .now() + (animationDuration ?? 0.0)) {
                showTutorialView = false
            }
        }
    }

    private struct LocalizedString {
        static let tutorialText = NSLocalizedString(
            "Move slowly around your object. (Object Capture, Orbit, Tutorial)",
            bundle: Bundle.main,
            value: "Move slowly around your object.",
            comment: "Guided feedback message to move slowly around object to start capturing."
        )
    }
}

private struct BoundingBoxGuidanceView: View {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession
    var hasDetectionFailed: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        HStack {
            if let guidanceText {
                Text(guidanceText)
                    .font(.callout)
                    .bold()
                    .foregroundColor(.white)
                    .transition(.opacity)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: horizontalSizeClass == .regular ? 400 : 360)
            }
        }
    }

    private var guidanceText: String? {
        if case .ready = session.state {
            switch appModel.captureMode {
                case .object:
                    if hasDetectionFailed {
                        return NSLocalizedString(
                            "Can‘t find your object. It should be larger than 3 in (8 cm) in each dimension.",
                            bundle: Bundle.main,
                            value: "対象が見つかりません。各辺が8cm以上のサイズが必要です。",
                            comment: "Feedback message when detection has failed.")
                    } else {
                        return NSLocalizedString(
                            "Move close and center the dot on your object, then tap Continue. (Object Capture, State)",
                            bundle: Bundle.main,
                            value: "対象に近づいて中央の点を合わせ、続けるをタップしてください。",
                            comment: "Feedback message to fill the camera feed with the object.")
                    }
                case .area:
                    return NSLocalizedString(
                        "Look at your subject (Object Capture, State).",
                        bundle: Bundle.main,
                        value: "対象を見てください。",
                        comment: "Feedback message to look at the subject in the area mode.")
                }
        } else if case .detecting = session.state {
            return NSLocalizedString(
                "Move around to ensure that the whole object is inside the box. Drag handles to manually resize. (Object Capture, State)",
                bundle: Bundle.main,
                value: "オブジェクト全体がボックス内に入るように移動してください。ハンドルをドラッグして手動でリサイズできます。",
                comment: "Feedback message to resize the box to the object.")
        } else {
            return nil
        }
    }
}

protocol OverlayButtons {
    func isCapturingStarted(state: ObjectCaptureSession.CaptureState) -> Bool
}

extension OverlayButtons {
    func isCapturingStarted(state: ObjectCaptureSession.CaptureState) -> Bool {
        switch state {
            case .initializing, .ready, .detecting:
                return false
            default:
                return true
        }
    }
}

// MARK: - 撮影進捗プログレスバー
private struct CaptureProgressBar: View {
    var session: ObjectCaptureSession
    
    private var currentCount: Int {
        session.numberOfShotsTaken
    }
    
    private var targetCount: Int {
        50  // 50枚が目標
    }
    
    private var progress: Double {
        min(Double(currentCount) / Double(targetCount), 1.0)
    }
    
    private var progressColor: Color {
        if currentCount >= targetCount {
            return .green
        } else if currentCount >= targetCount * 3 / 4 {
            return .orange
        } else {
            return .blue
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("撮影進捗")
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(currentCount)/\(targetCount)枚")
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .monospaced()
            }
            
            // プログレスバー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 8)
                    
                    // 進捗部分
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.8))
                .environment(\.colorScheme, .dark)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - 撮影状態インジケーター
private struct CaptureStatusIndicator: View {
    var session: ObjectCaptureSession
    
    @State private var isCapturing = false
    @State private var captureCount = 0
    @State private var lastCaptureTime: Date?
    
    private var timeSinceLastCapture: TimeInterval {
        guard let lastTime = lastCaptureTime else { return 0 }
        return Date().timeIntervalSince(lastTime)
    }
    
    private var captureFrequency: String {
        if timeSinceLastCapture < 1.0 {
            return "撮影中..."
        } else if timeSinceLastCapture < 3.0 {
            return "準備中..."
        } else {
            return "位置を調整してください"
        }
    }
    
    private var statusColor: Color {
        if timeSinceLastCapture < 1.0 {
            return .green
        } else if timeSinceLastCapture < 3.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 撮影状態インジケーター
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .scaleEffect(isCapturing ? 1.5 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isCapturing)
            
            Text(captureFrequency)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Spacer()
            
            // 撮影間隔表示
            Text("0.3秒間隔")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.3))
                .cornerRadius(4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial.opacity(0.6))
                .environment(\.colorScheme, .dark)
        )
        .padding(.horizontal, 16)
        .onChange(of: session.numberOfShotsTaken) { _, newCount in
            if newCount > captureCount {
                captureCount = newCount
                lastCaptureTime = Date()
                
                // 撮影フィードバック
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCapturing = true
                }
                
                // ハプティックフィードバック
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                // 0.3秒後にインジケーターをリセット
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCapturing = false
                    }
                }
            }
        }
        .onAppear {
            captureCount = session.numberOfShotsTaken
            lastCaptureTime = Date()
        }
    }
}


