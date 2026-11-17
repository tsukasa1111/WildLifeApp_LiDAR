/*
Scan Completed View
点群プレビュー付きの3Dモデル生成 or 下書き保存選択画面
*/

import SwiftUI
import RealityKit
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "ScanCompletedView")

struct ScanCompletedView: View {
    @EnvironmentObject var appModel: AppDataModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showMetadataAlert = false
    @State private var showAnnotatedImage = false
    
    var session: ObjectCaptureSession
    
    var body: some View {
        VStack(spacing: 20) {
            // Point Cloud Preview Section
            VStack(spacing: 15) {
                Text("スキャンが完了しました")
                    .font(.title2)
                    .bold()
                
                // Background Processing Status Card
                BackgroundProcessingStatusCard()
                
                // Point cloud preview area - プレースホルダーを表示
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "cube.transparent")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            Text("点群プレビュー")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                    .padding(.horizontal, 20)
                
                // Data info
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.blue)
                        Text("\(session.numberOfShotsTaken)枚の写真を撮影")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    if let folderManager = appModel.captureFolderManager,
                       folderManager.hasPointCloud() {
                        HStack {
                            Image(systemName: "cube.transparent.fill")
                                .foregroundColor(.green)
                            Text("点群データ保存済み")
                                .font(.body)
                                .foregroundColor(.secondary)
                            if let fileSize = folderManager.getPointCloudFileSize() {
                                Text("(\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        Image(systemName: "pawprint.fill")
                            .foregroundColor(.green)
                        Text("詳細情報保存済み")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        if let folderManager = appModel.captureFolderManager,
                           folderManager.hasAnnotatedImage() {
                            Spacer()
                            Button("足跡画像を確認") {
                                showAnnotatedImage = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            }
            
            // Action Buttons
            VStack(spacing: 16) {
                    // Metadata Input Button  
                    Button(action: {
                        logger.log("Showing metadata warning alert")
                        showMetadataAlert = true
                    }) {
                        HStack {
                            Image(systemName: "pawprint.fill")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("詳細情報を入力")
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                Text("動物痕跡の詳細情報を記録します")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .background(Color.green)
                    .cornerRadius(12)
                    
                    // Generate 3D Model Button
                    Button(action: {
                        logger.log("Starting 3D model generation")
                        appModel.state = .prepareToReconstruct
                    }) {
                        HStack {
                            Image(systemName: "cube.fill")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("3Dモデルを生成")
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                Text("すぐに3Dモデルを作成します")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .background(Color.blue)
                    .cornerRadius(12)
                    .disabled(session.numberOfShotsTaken < AppDataModel.minNumImages)
                    
                    // Save Draft Button  
                    Button(action: {
                        logger.log("Saving as draft")
                        appModel.saveDraft()
                        appModel.state = .draftSaved
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("下書きとして保存")
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                Text("後で3Dモデルを生成できます")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .background(Color.orange)
                    .cornerRadius(12)
                    .disabled(session.numberOfShotsTaken < AppDataModel.minNumImages)
                    
                    // Background Processing Button
                    Button(action: {
                        logger.log("Starting background processing")
                        appModel.startBackgroundProcessing()
                    }) {
                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("夜間処理キューに追加")
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                Text("バックグラウンドで3Dモデルを生成")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .background(Color.purple)
                    .cornerRadius(12)
                    .disabled(session.numberOfShotsTaken < AppDataModel.minNumImages || 
                             appModel.backgroundProcessingStatus != .idle)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .light ? Color.white : Color.black)
        .onAppear {
            // バックグラウンド処理は自動では開始せず、ユーザーが明示的に選択
            // 昼間の現地作業では写真撮影のみに集中し、
            // 夜間など時間がある時に一括で3Dモデル生成を行う想定
        }
        .alert("詳細情報入力について", isPresented: $showMetadataAlert) {
            Button("続ける") {
                logger.log("Going to metadata input")
                appModel.state = .metadataInput
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("詳細情報入力画面では戻ることができません。入力を完了するか、下書き保存または3Dモデル生成を行う必要があります。")
        }
        .sheet(isPresented: $showAnnotatedImage) {
            if let folderManager = appModel.captureFolderManager,
               folderManager.hasAnnotatedImage() {
                AnnotatedImageViewer(captureFolderManager: folderManager)
            } else {
                VStack {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    Text("足跡画像が見つかりません")
                        .font(.headline)
                        .padding(.top)
                }
            }
        }
    }
}

// MARK: - Background Processing Status Card
private struct BackgroundProcessingStatusCard: View {
    @EnvironmentObject var appModel: AppDataModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: backgroundStatusIcon)
                    .font(.title2)
                    .foregroundColor(backgroundStatusColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(backgroundStatusTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(backgroundStatusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if case .processing(_) = appModel.backgroundProcessingStatus {
                    Button("キャンセル") {
                        appModel.cancelBackgroundProcessing()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            
            // Progress bar for processing state
            if case .processing(let progress) = appModel.backgroundProcessingStatus {
                VStack(spacing: 6) {
                    HStack {
                        Text("進捗")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 0.5)
                }
            }
            
            // Action button for completed state
            if case .completed(let modelURL) = appModel.backgroundProcessingStatus {
                Button(action: {
                    // Open the generated model
                    openModel(url: modelURL)
                }) {
                    HStack {
                        Image(systemName: "eye.fill")
                        Text("3Dモデルを確認")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundCardColor)
                .stroke(backgroundStatusColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
    
    private var backgroundStatusIcon: String {
        switch appModel.backgroundProcessingStatus {
        case .idle:
            return "clock"
        case .processing(_):
            return "gearshape.2.fill"
        case .completed(_):
            return "checkmark.circle.fill"
        case .failed(_):
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var backgroundStatusColor: Color {
        switch appModel.backgroundProcessingStatus {
        case .idle:
            return .gray
        case .processing(_):
            return .blue
        case .completed(_):
            return .green
        case .failed(_):
            return .red
        }
    }
    
    private var backgroundStatusTitle: String {
        switch appModel.backgroundProcessingStatus {
        case .idle:
            return "バックグラウンド処理待機中"
        case .processing(_):
            return "3Dモデルを生成中..."
        case .completed(_):
            return "3Dモデル生成完了"
        case .failed(_):
            return "処理エラー"
        }
    }
    
    private var backgroundStatusMessage: String {
        switch appModel.backgroundProcessingStatus {
        case .idle:
            return "他の操作を実行中でも、バックグラウンドで3Dモデルを生成します"
        case .processing(_):
            return "バックグラウンドで高品質3Dモデルを生成しています。他の操作も続行できます"
        case .completed(_):
            return "バックグラウンドで3Dモデルの生成が完了しました"
        case .failed(let error):
            return "処理に失敗しました: \(error.localizedDescription)"
        }
    }
    
    private var backgroundCardColor: Color {
        switch appModel.backgroundProcessingStatus {
        case .idle:
            return Color(UIColor.systemGray6)
        case .processing(_):
            return Color.blue.opacity(0.1)
        case .completed(_):
            return Color.green.opacity(0.1)
        case .failed(_):
            return Color.red.opacity(0.1)
        }
    }
    
    private func openModel(url: URL) {
        // TODO: Implement model viewer
        logger.log("Opening background generated model: \(url.path)")
    }
}

struct ScanCompletedView_Previews: PreviewProvider {
    static var previews: some View {
        ScanCompletedView(session: ObjectCaptureSession())
            .environmentObject(AppDataModel())
    }
}