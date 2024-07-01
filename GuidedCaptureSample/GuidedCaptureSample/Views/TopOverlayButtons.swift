import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "TopOverlayButtons")

struct TopOverlayButtons: View, OverlayButtons {
    @Environment(AppDataModel.self) var appModel
    var session: ObjectCaptureSession
    var showCaptureModeGuidance: Bool

    var body: some View {
        VStack {
            HStack {
                CaptureCancelButton()
                Spacer()
                if isCapturingStarted(state: session.state) {
                    NextButton(session: session)
                } else {
                    CaptureFolderButton()
                }
            }
            .foregroundColor(.white)
            Spacer().frame(height: 26)
            if session.state == .ready, showCaptureModeGuidance {
                CaptureModeGuidanceView()
            }
        }
    }
}

private struct CaptureCancelButton: View {
    @Environment(AppDataModel.self) var appModel

    var body: some View {
        Button(action: {
            logger.log("\(LocalizedString.cancel) button clicked!")
            appModel.objectCaptureSession?.cancel()
            appModel.removeCaptureFolder()
        }, label: {
            Text(LocalizedString.cancel)
                .modifier(VisualEffectRoundedCorner())
        })
    }

    struct LocalizedString {
        static let cancel = NSLocalizedString(
            "Cancel (Object Capture)",
            bundle: Bundle.main,
            value: "Cancel",
            comment: "Title for the Cancel button on the object capture screen.")
    }
}

private struct NextButton: View {
    @Environment(AppDataModel.self) var appModel
    var session: ObjectCaptureSession
    @State private var showOnboardingView: Bool = false

    var body: some View {
        Button(action: {
            logger.log("\(LocalizedString.next) button clicked!")
            showOnboardingView = true
        },
               label: {
            Text(appModel.captureMode == .object ? LocalizedString.next : LocalizedString.done)
                .modifier(VisualEffectRoundedCorner())
        })
        .sheet(isPresented: $showOnboardingView) {
            if let onboardingState = appModel.determineCurrentOnboardingState() {
                OnboardingView(state: onboardingState,
                               showOnboardingView: $showOnboardingView)
                .interactiveDismissDisabled()
            }
        }
        .onChange(of: showOnboardingView) {
            appModel.setShowOverlaySheets(to: showOnboardingView)
        }
        .task {
            for await userCompletedScanPass in session.userCompletedScanPassUpdates where userCompletedScanPass {
                logger.log("The scan pass is completed!")
                showOnboardingView = true
            }
        }
    }

    struct LocalizedString {
        static let next = NSLocalizedString(
            "Next (Object Capture)",
            bundle: Bundle.main,
            value: "Next",
            comment: "Title for the Next button on the object capture screen."
        )

        static let done = NSLocalizedString(
            "Done (Object Capture)",
            bundle: Bundle.main,
            value: "Done",
            comment: "Title for the Done button on the object capture screen."
        )
    }
}

private struct CaptureFolderButton: View {
    @Environment(AppDataModel.self) var appModel
    @State private var showCaptureFolders: Bool = false

    var body: some View {
        Button(action: {
            logger.log("Capture folder button clicked!")
            showCaptureFolders = true
        }, label: {
            Image(systemName: "folder")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22)
                .foregroundColor(.white)
                .padding(20)
                .contentShape(.rect)
        })
        .padding(-20)
        .sheet(isPresented: $showCaptureFolders) {
            GalleryView(showCaptureFolders: $showCaptureFolders)
        }
        .onChange(of: showCaptureFolders) {
            appModel.setShowOverlaySheets(to: showCaptureFolders)
        }
    }
}

private struct CaptureModeGuidanceView: View {
    @Environment(AppDataModel.self) var appModel

    var body: some View {
        Text(guidanceText)
            .font(.subheadline)
            .bold()
            .padding(.all, 6)
            .foregroundColor(.white)
            .background(.blue)
            .cornerRadius(5)
    }

    private var guidanceText: String {
        switch appModel.captureMode {
            case .object:
                return LocalizedString.objectMode
            case .area:
                return LocalizedString.areaMode
        }
    }

    private struct LocalizedString {
        static let areaMode = NSLocalizedString(
            "Area mode (Object Capture)",
            bundle: Bundle.main,
            value: "AREA MODE",
            comment: "Title for the Area Mode guidance text.")

        static let objectMode = NSLocalizedString(
            "Object mode (Object Capture)",
            bundle: Bundle.main,
            value: "OBJECT MODE",
            comment: "Title for the Object Mode guidance text.")
    }
}

private struct VisualEffectRoundedCorner: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16.0)
            .font(.subheadline)
            .bold()
            .foregroundColor(.white)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .cornerRadius(15)
            .multilineTextAlignment(.center)
    }
}

private struct GalleryView: View {
    @Environment(AppDataModel.self) var appModel
    @Binding var showCaptureFolders: Bool

    var body: some View {
        if let captureFolderURLs {
            ScrollView {
                ZStack {
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
                    Text(LocalizedString.captures)
                        .foregroundColor(.primary).bold()
                }
                Divider().padding(.vertical, 8)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()),
                                         count: UIDevice.current.userInterfaceIdiom == .pad ? 5 : 3)) {
                    ForEach(captureFolderURLs, id: \.self) { url in
                        ThumbnailView(captureFolderURL: url)
                    }
                }
            }.padding()
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
        guard let folderURLs else { return nil }
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
    @State private var image: UIImage?

    var body: some View {
        if let imageURL = getFirstImage(from: captureFolderURL) {
            ShareLink(item: captureFolderURL) {
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

    nonisolated private func loadThumbnail(url: URL) async -> UIImage? {
        // Load the embedded thumbnail.
        let maxPixelSize = 200
        let options: [CFString: Any] = [kCGImageSourceThumbnailMaxPixelSize: maxPixelSize]

        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) {
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
        } else { // If embedded thumbnail is not available, load the image.
            let uiImage = UIImage(contentsOfFile: url.path())
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
}
