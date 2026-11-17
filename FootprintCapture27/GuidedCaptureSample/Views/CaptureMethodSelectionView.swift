/*
Capture Method Selection View
キャプチャ方法選択画面 - iOS 18対応
従来方式 vs リアルタイム点群キャプチャ
*/

import SwiftUI
import RealityKit
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "CaptureMethodSelection")

struct CaptureMethodSelectionView: View {
    @EnvironmentObject var appModel: AppDataModel
    @State private var selectedMethod: CaptureMethod = .traditional
    
    enum CaptureMethod {
        case traditional
        case realtime
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 10) {
                    Text("🦎 動物痕跡スキャナー")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("キャプチャ方法を選択してください")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // 方法選択カード
                VStack(spacing: 20) {
                    // 従来方式
                    CaptureMethodCard(
                        title: "📸 従来のフォトキャプチャ",
                        subtitle: "Object Capture標準方式",
                        description: "写真を撮影してから点群を生成\n高品質な3Dモデル作成",
                        features: [
                            "🏆 最高品質の3Dモデル",
                            "📊 安定した処理",
                            "⏱️ 処理時間: 5-10分"
                        ],
                        isSelected: selectedMethod == .traditional,
                        action: { selectedMethod = .traditional }
                    )
                    
                    // iOS 18対応のリアルタイム方式
                    if #available(iOS 18.0, *) {
                        CaptureMethodCard(
                            title: "🚀 リアルタイム点群キャプチャ",
                            subtitle: "iOS 18革新技術",
                            description: "撮影しながら即座に点群を生成\nLiDAR + RGB融合技術",
                            features: [
                                "⚡ リアルタイム処理",
                                "🌟 LiDAR高密度点群",
                                "🎯 即座に結果確認"
                            ],
                            isSelected: selectedMethod == .realtime,
                            action: { selectedMethod = .realtime },
                            badge: "NEW"
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 開始ボタン
                Button(action: startCapture) {
                    HStack {
                        Image(systemName: selectedMethod == .realtime ? "camera.fill" : "camera.circle.fill")
                        Text(selectedMethod == .realtime ? "リアルタイムキャプチャ開始" : "フォトキャプチャ開始")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: selectedMethod == .realtime ? [.blue, .purple] : [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func startCapture() {
        logger.log("Selected capture method: \(String(describing: selectedMethod))")
        
        switch selectedMethod {
        case .traditional:
            logger.log("🎯 Starting traditional photo capture")
            appModel.state = .ready
        case .realtime:
            if #available(iOS 18.0, *) {
                logger.log("🚀 Starting iOS 18 realtime capture")
                // リアルタイムキャプチャモードに切り替え
                appModel.captureMode = .area // エリアモードでリアルタイム処理
                appModel.state = .ready
            }
        }
    }
}

struct CaptureMethodCard: View {
    let title: String
    let subtitle: String
    let description: String
    let features: [String]
    let isSelected: Bool
    let action: () -> Void
    let badge: String?
    
    init(title: String, subtitle: String, description: String, features: [String], isSelected: Bool, action: @escaping () -> Void, badge: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.features = features
        self.isSelected = isSelected
        self.action = action
        self.badge = badge
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 15) {
                // ヘッダー
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                
                // 説明
                Text(description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                // 機能リスト
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(features, id: \.self) { feature in
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 3 : 1)
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}