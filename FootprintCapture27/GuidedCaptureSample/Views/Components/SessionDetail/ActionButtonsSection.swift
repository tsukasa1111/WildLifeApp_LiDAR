import SwiftUI
import RealityKit

struct ActionButtonsSection: View {
    let hasModel: Bool
    let isReconstructing: Bool
    let modelURL: URL?
    let captureFolderURL: URL
    @Binding var showModel: Bool
    let onGenerateModel: () -> Void
    @EnvironmentObject var appModel: AppDataModel
    @State private var showPointCloud = false
    @State private var selectedPointCloudType: PointCloudType = .enhanced

    private var objectCaptureSession: ObjectCaptureSession? {
        return appModel.objectCaptureSession
    }

    private func showPointCloudComparison(type: PointCloudType) {
        selectedPointCloudType = type
        showPointCloud = true
    }

    var body: some View {
        VStack(spacing: 12) {
            if hasModel && !isReconstructing {
                Button {
                    if modelURL != nil { showModel = true }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "cube.fill").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        Text("3Dモデルを表示").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .background(Color.blue)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .disabled(modelURL == nil)

                if hasPointCloud() {
                    let bestType = getBestAvailablePointCloudType()
                    Button { showPointCloudComparison(type: bestType) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "cube.transparent.fill").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                            Text("点群データを表示").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .background(Color.orange)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }

                ShareLink(item: captureFolderURL) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        Text("すべてのファイルを共有").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .background(Color.green)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else if !isReconstructing {
                Button { onGenerateModel() } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        Text("3Dモデルを生成").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .background(Color.blue)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                ShareLink(item: captureFolderURL) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        Text("キャプチャを共有").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .background(Color.green)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                VStack(spacing: 12) {
                    Button(action: {}) {
                        HStack(spacing: 12) {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.8)
                            Text("処理中...").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .background(Color.gray)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .disabled(true)
                }
            }
        }
        .sheet(isPresented: $showModel) {
            if let modelURL = modelURL {
                ModelView(modelFile: modelURL) { showModel = false }
            }
        }
        .sheet(isPresented: $showPointCloud) {
            if hasPointCloud() {
                NavigationView {
                    SimplePointCloudView(captureFolderURL: captureFolderURL, pointCloudType: selectedPointCloudType)
                        .navigationTitle("点群データ")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("閉じる") { showPointCloud = false }
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Helpers
    private func hasPointCloud() -> Bool {
        for type in PointCloudType.allCases {
            let url = captureFolderURL.appendingPathComponent(type.rawValue)
            if FileManager.default.fileExists(atPath: url.path) { return true }
        }
        return false
    }

    private func getAvailablePointCloudTypes() -> [PointCloudType] {
        PointCloudType.allCases.filter { type in
            FileManager.default.fileExists(atPath: captureFolderURL.appendingPathComponent(type.rawValue).path)
        }
    }

    private func getBestAvailablePointCloudType() -> PointCloudType {
        let available = getAvailablePointCloudTypes()
        for type in [.research, .enhanced, .standard, .traditional] as [PointCloudType] {
            if available.contains(type) { return type }
        }
        return available.first ?? .enhanced
    }

    private func getPointCloudURL(type: PointCloudType = .enhanced) -> URL {
        captureFolderURL.appendingPathComponent(type.rawValue)
    }

}
