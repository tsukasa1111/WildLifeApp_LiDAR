import SwiftUI
import RealityKit
import QuickLook
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "GalleryView")

struct GalleryView: View {
    @Environment(AppDataModel.self) var appModel
    @Binding var showCaptureFolders: Bool
    @State private var selectedModelURL: URL? = nil

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button(LocalizedString.cancel) {
                        logger.log("The cancel button in gallery view clicked!")
                        withAnimation {
                            showCaptureFolders = false
                        }
                    }
                    .foregroundColor(.accentColor)
                    Spacer()
                }
                .padding()

                if let captureFolderURLs = captureFolderURLs {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: UIDevice.current.userInterfaceIdiom == .pad ? 5 : 3)) {
                            ForEach(captureFolderURLs, id: \.self) { url in
                                ThumbnailView(captureFolderURL: url, selectedModelURL: $selectedModelURL)
                            }
                        }
                    }
                } else {
                    Text("No captures available.")
                        .foregroundColor(.secondary)
                }
            }
            .sheet(item: $selectedModelURL) { modelURL in
                ModelView(modelFile: modelURL) {
                    self.selectedModelURL = nil
                }
            }
        }
    }

    private var captureFolderURLs: [URL]? {
        guard let topLevelFolder = appModel.captureFolderManager?.appDocumentsFolder else { return nil }
        let folderURLs = try? FileManager.default.contentsOfDirectory(
            at: topLevelFolder,
            includingPropertiesForKeys: nil,
            options: [])
            .filter { $0.hasDirectoryPath }
            .sorted(by: { $0.path > $1.path })
        return folderURLs
    }

    struct LocalizedString {
        static let cancel = NSLocalizedString(
            "Cancel (Object Capture)",
            bundle: Bundle.main,
            value: "Cancel",
            comment: "Title for the Cancel button on the folder view.")
        static let captures = NSLocalizedString(
            "Captures (Object Capture)",
            bundle: Bundle.main,
            value: "Captures",
            comment: "Title for the folder view.")
    }
}

private struct ThumbnailView: View {
    let captureFolderURL: URL
    @Binding var selectedModelURL: URL?
    @State private var image: UIImage?

    var body: some View {
        if let imageURL = getFirstImage(from: captureFolderURL) {
            Button(action: {
                if let modelURL = getModelFile(from: captureFolderURL) {
                    selectedModelURL = modelURL
                } else {
                    // 再構成をユーザーに確認して実行するロジックを追加
                    // For simplicity, assume the model URL is available
                    selectedModelURL = nil // Placeholder logic
                }
            }) {
                let frameSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 100 : 115
                VStack(spacing: 8) {
                    VStack {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: frameSize, height: frameSize)
                    .clipped()
                    .cornerRadius(8)

                    let folderName = captureFolderURL.lastPathComponent
                    Text("\(folderName)")
                        .foregroundColor(.primary)
                        .font(.caption2)
                    Spacer()
                }
                .frame(width: frameSize, height: frameSize + 70)
                .task {
                    image = await loadThumbnail(url: imageURL)
                }
            }
        }
    }

    private func loadThumbnail(url: URL) async -> UIImage? {
        let maxPixelSize = 200
        let options: [CFString: Any] = [kCGImageSourceThumbnailMaxPixelSize: maxPixelSize]

        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) {
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
        } else {
            let uiImage = UIImage(contentsOfFile: url.path)
            return await uiImage?.byPreparingThumbnail(ofSize: CGSize(width: maxPixelSize, height: maxPixelSize))
        }
    }

    private func getFirstImage(from url: URL) -> URL? {
        let imageFolderURL = url.appendingPathComponent(CaptureFolderManager.imagesFolderName)
        let imagesURL: URL? = try? FileManager.default.contentsOfDirectory(
            at: imageFolderURL,
            includingPropertiesForKeys: nil,
            options: [])
            .filter { !$0.hasDirectoryPath }
            .sorted(by: { $0.path < $1.path })
            .first
        return imagesURL
    }

    private func getModelFile(from url: URL) -> URL? {
        let modelFolderURL = url.appendingPathComponent("Models")
        let modelURL: URL? = try? FileManager.default.contentsOfDirectory(
            at: modelFolderURL,
            includingPropertiesForKeys: nil,
            options: [])
            .filter { $0.pathExtension == "usdz" }
            .first
        return modelURL
    }
}
