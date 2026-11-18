/*
Action Selection View
メタデータ入力後の3Dモデル生成 or 下書き保存選択画面
*/

import SwiftUI
import RealityKit
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "ActionSelectionView")

struct ActionSelectionView: View {
    @EnvironmentObject var appModel: AppDataModel
    @Environment(\.colorScheme) private var colorScheme
    
    var session: ObjectCaptureSession
    
    var body: some View {
        VStack(spacing: 20) {
            // Navigation header
            HStack {
                Button(action: {
                    appModel.state = .completed
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("撮影を終了")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            // 簡略化されたヘッダー
            VStack(spacing: 15) {
                Text("痕跡情報が保存されました")
                    .font(.title2)
                    .bold()
                
                Text("次の操作を選択してください")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Action Buttons
            VStack(spacing: 16) {
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
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(session.numberOfShotsTaken < AppDataModel.minNumImages)
                
                // Save Draft Button  
                Button(action: {
                    logger.log("Saving as draft")
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
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(session.numberOfShotsTaken < AppDataModel.minNumImages)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .light ? Color.white : Color.black)
        .onAppear {
            logger.log("ActionSelectionView appeared - session state: \(String(describing: session.state))")
        }
    }
}

struct ActionSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ActionSelectionView(session: ObjectCaptureSession())
            .environmentObject(AppDataModel())
    }
}
