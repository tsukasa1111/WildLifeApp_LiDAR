/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Top-level View for the Object Capture portion where shots are taken.
*/

import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "CapturePrimaryView")

struct CapturePrimaryView: View {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession
    
    // 50枚達成自動完了用の状態
    @State private var hasShown50Alert = false
    @State private var showCompletionMessage = false

    var body: some View {
        ZStack {
            ObjectCaptureView(session: session,
                              cameraFeedOverlay: { GradientBackground() })
            .hideObjectReticle(appModel.captureMode == .area)
            .blur(radius: appModel.showOverlaySheets ? 45 : 0)
            .transition(.opacity)

            CaptureOverlayView(session: session)
            
            // 50枚達成時の完了メッセージ
            if showCompletionMessage {
                CompletionMessageView()
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(1000)
            }
        }
        .onAppear(perform: {
            UIApplication.shared.isIdleTimerDisabled = true
        })
        .onDisappear(perform: {
            UIApplication.shared.isIdleTimerDisabled = false
        })
        .id(session.id)
        // 50枚達成監視 - 完了メッセージ表示後に自動完了処理
        .onChange(of: session.numberOfShotsTaken) { _, newCount in
            if newCount == 50 && !hasShown50Alert {
                logger.log("🎉 50枚達成！完了メッセージ表示")
                hasShown50Alert = true
                
                // 完了メッセージを表示
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showCompletionMessage = true
                }
                
                // 1.5秒後に自動完了処理を実行
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCompletionMessage = false
                    }
                    
                    // 0.2秒後に完了処理を実行
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        logger.log("🎉 50枚達成！自動完了処理実行")
                        session.finish()
                    }
                }
            }
        }
    }
    
}

// MARK: - 50枚達成時の完了メッセージ
private struct CompletionMessageView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // 完了アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: true)
            
            VStack(spacing: 12) {
                Text("🎉 撮影完了！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("50枚の撮影が完了しました")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 40)
    }
}

private struct GradientBackground: View {
    private let gradient = LinearGradient(
        colors: [.black.opacity(0.4), .clear],
        startPoint: .top,
        endPoint: .bottom
    )
    private let frameHeight: CGFloat = 300

    var body: some View {
        VStack {
            gradient
                .frame(height: frameHeight)

            Spacer()

            gradient
                .rotation3DEffect(Angle(degrees: 180), axis: (x: 1, y: 0, z: 0))
                .frame(height: frameHeight)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

