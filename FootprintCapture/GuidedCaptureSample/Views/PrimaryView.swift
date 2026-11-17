/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view that includes both the image capture and reconstruction.
*/

import SwiftUI
import RealityKit
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "PrimaryView")

struct PrimaryView: View {
    @EnvironmentObject var appModel: AppDataModel

    @State private var showReconstructionView: Bool = false
    private var showProgressView: Bool {
        appModel.state == .restart || appModel.state == .ready
    }

    var body: some View {
        VStack {
            if appModel.state == .capturing {
                if let session = appModel.objectCaptureSession {
                    // 📸 従来のObjectCaptureのみ（安定性重視）
                    CapturePrimaryView(session: session)
                    
                    // TODO: 将来的にiOS 18機能を追加する場合
                    // if #available(iOS 18.0, *) {
                    //     HybridCapturePrimaryView(session: session)
                    // } else {
                    //     CapturePrimaryView(session: session)
                    // }
                }
            } else if appModel.state == .metadataInput {
                MetadataInputView()
            } else if appModel.state == .actionSelection {
                if let session = appModel.objectCaptureSession {
                    ScanCompletedView(session: session)
                }
            } else if appModel.state == .metadataCompleted {
                MetadataCompletionView()
                    .onAppear {
                        logger.log("PrimaryView showing MetadataCompletionView")
                    }
            } else if appModel.state == .completed {
                // ObjectCaptureSession completion - handled by onStateChanged
                CircularProgressView()
            } else if appModel.state == .draftSaved {
                DraftSavedView()
            } else if showProgressView {
                CircularProgressView()
            }
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



