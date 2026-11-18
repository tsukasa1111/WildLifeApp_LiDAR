/*
Metadata Completion View
メタデータ入力完了画面
*/

import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "MetadataCompletionView")

struct MetadataCompletionView: View {
    @EnvironmentObject var appModel: AppDataModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAnnotatedImage = false
    
    var body: some View {
        VStack {
            Spacer()
            
            // Success Animation and Icon
            VStack(spacing: 20) {
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
                    Text("保存完了")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("動物痕跡の詳細情報が正常に保存されました")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .light ? Color.white : Color.black)
        .onAppear {
            logger.log("🎉 MetadataCompletionView appeared - SUCCESS!")
            
            // 保存後は3D生成または下書き保存を選べる画面へ進む。
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard appModel.state == .metadataCompleted else { return }
                appModel.state = .actionSelection
            }
        }
    }
}

struct MetadataCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        MetadataCompletionView()
            .environmentObject(AppDataModel())
    }
}
