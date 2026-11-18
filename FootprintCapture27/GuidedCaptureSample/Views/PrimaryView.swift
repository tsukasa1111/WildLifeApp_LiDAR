/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view that includes both the image capture and reconstruction.
*/

import SwiftUI
import UIKit
import RealityKit
import AVFoundation
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "PrimaryView")

struct PrimaryView: View {
    @EnvironmentObject var appModel: AppDataModel

    @State private var showReconstructionView: Bool = false
    private var showProgressView: Bool {
        appModel.state == .restart || appModel.state == .ready
    }

    var body: some View {
        VStack { stateContent() }
        .alert("カメラが利用できません", isPresented: $appModel.showCameraUnavailableAlert) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("ギャラリーを見る") { appModel.showReadOnlyGallery = true }
            Button("OK", role: .cancel) { }
        } message: {
            Text(appModel.cameraUnavailableMessage)
        }
        .sheet(isPresented: $appModel.showReadOnlyGallery) {
            GalleryStandaloneView()
        }
        .onChange(of: appModel.state) { _, newState in
            showReconstructionView = newState == .reconstructing || newState == .viewing
        }
        .sheet(isPresented: $showReconstructionView) {
            if let folderManager = appModel.captureFolderManager {
                ReconstructionPrimaryView(outputFile: folderManager.modelsFolder.appendingPathComponent("model-mobile.usdz"))
                    .interactiveDismissDisabled()
            }
        }
    }

    // Break the state-driven view into a smaller builder to help type-checker
    @ViewBuilder
    private func stateContent() -> some View {
        if appModel.state == .capturing {
            if let session = appModel.objectCaptureSession {
                CapturePrimaryView(session: session)
            }
        } else if appModel.state == .metadataInput {
            MetadataInputView()
        } else if appModel.state == .actionSelection {
            if let session = appModel.objectCaptureSession {
                ActionSelectionView(session: session)
            }
        } else if appModel.state == .metadataCompleted {
            MetadataCompletionView()
                .onAppear { logger.log("PrimaryView showing MetadataCompletionView") }
        } else if appModel.state == .completed {
            CircularProgressView()
        } else if appModel.state == .draftSaved {
            DraftSavedView()
        } else if appModel.state == .failed {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text("処理を続けられませんでした")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(appModel.error?.localizedDescription ?? "原因を確認できませんでした。")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("撮影へ戻る") { appModel.state = .restart }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if showProgressView {
            if isCameraUnavailable() || !appModel.cameraUnavailableMessage.isEmpty {
                ReadOnlyGalleryContainer()
                    .environmentObject(appModel)
            } else {
                CircularProgressView()
            }
        }
    }
}

@MainActor
private func isCameraUnavailable() -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    if status == .denied || status == .restricted { return true }
    if !ObjectCaptureSession.isSupported { return true }
    return false
}

private struct ReadOnlyGalleryContainer: View {
    @EnvironmentObject var appModel: AppDataModel

    @State private var showPreview = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !appModel.cameraUnavailableMessage.isEmpty {
                    Label(appModel.cameraUnavailableMessage, systemImage: "camera.fill")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
                GC_GalleryView()
            }
            .navigationTitle("キャプチャ一覧")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPreview) { CaptureScreenPreview() }
            .toolbar {
                if !ObjectCaptureSession.isSupported {
                    ToolbarItem(placement: .primaryAction) {
                        Button("撮影画面の見本") { showPreview = true }
                    }
                }
                if ObjectCaptureSession.isSupported {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("撮影を開始") { appModel.createNewCaptureSession() }
                    }
                }
            }
        }
    }
}

private struct DraftSavedView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var appModel: AppDataModel

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text("保存完了")
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                
                Text("痕跡データが下書きとして保存されました")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Text("後でキャプチャ一覧から3Dモデルを生成できます")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .light ? Color.white : Color.black)
    }
}

private struct CircularProgressView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .light ? .black : .white))
                Spacer()
            }
            Spacer()
        }
    }
}
