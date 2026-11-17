/*
Annotated Image Viewer
Displays saved footprint annotations on captured images
*/

import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "AnnotatedImageViewer")

struct AnnotatedImageViewer: View {
    @Environment(\.dismiss) private var dismiss
    
    let captureFolderManager: CaptureFolderManager
    @State private var annotatedImage: UIImage?
    @State private var annotationMetadata: AnnotationMetadata?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading annotated image...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let annotatedImage = annotatedImage {
                    ScrollView([.horizontal, .vertical]) {
                        ZStack {
                            Image(uiImage: annotatedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipped()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .background(Color.black)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No annotated image found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Create footprint annotations in the metadata input screen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Footprint Annotations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if annotatedImage != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: shareImage) {
                                Label("Share Image", systemImage: "square.and.arrow.up")
                            }
                            
                            if let metadata = annotationMetadata {
                                Button(action: { showAnnotationInfo(metadata) }) {
                                    Label("View Details", systemImage: "info.circle")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .onAppear {
            loadAnnotatedImage()
        }
    }
    
    private func loadAnnotatedImage() {
        isLoading = true
        
        // 静的な合成画像を読み込み
        if captureFolderManager.hasAnnotatedImage() {
            if let image = UIImage(contentsOfFile: captureFolderManager.annotatedImageURL.path) {
                annotatedImage = image
                logger.log("Loaded static annotated image")
            } else {
                logger.error("Failed to load annotated image file")
            }
        } else {
            logger.log("No annotated image found")
        }
        
        // メタデータも読み込んでおく
        annotationMetadata = captureFolderManager.loadAnnotationMetadata()
        if let metadata = annotationMetadata {
            logger.log("Loaded annotation metadata with \(metadata.annotations.count) annotations")
        }
        
        isLoading = false
    }
    
    // TODO: 将来の機能拡張用（動的再構築）
    private func loadOriginalImage() -> UIImage? {
        // 元画像を読み込むロジックを実装
        // 現在は未実装
        return nil
    }
    
    // TODO: 将来の機能拡張用（動的再構築）
    private func createAnnotatedImageFromMetadata(originalImage: UIImage, metadata: AnnotationMetadata) -> UIImage? {
        // 元画像にアノテーションを動的に描画するロジックを実装
        // 現在は未実装
        return nil
    }
    
    private func shareImage() {
        guard let annotatedImage = annotatedImage else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [annotatedImage],
            applicationActivities: nil
        )
        
        // iPad support
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?.rootViewController?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    private func showAnnotationInfo(_ metadata: AnnotationMetadata) {
        // This could be expanded to show a detailed view of annotation info
        logger.log("Annotation metadata: \(metadata.annotations.count) annotations from \(metadata.timestamp)")
    }
}

struct AnnotationInfoSheet: View {
    let metadata: AnnotationMetadata
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Annotation Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
    
    private var mainContent: some View {
        List {
            VStack(alignment: .leading, spacing: 16) {
                summarySection
                footprintDetailsSection
            }
            .padding()
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                summaryRow(title: "Total Footprints", value: "\(metadata.annotations.count)")
                summaryRow(title: "Annotation Date", value: formatDate(metadata.timestamp))
                summaryRow(title: "Image Size", value: "\(Int(metadata.imageSize.width)) × \(Int(metadata.imageSize.height))")
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
    
    private var footprintDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Footprint Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(Array(metadata.annotations.enumerated()), id: \.element.id) { index, annotation in
                footprintDetailCard(index: index, annotation: annotation)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func footprintDetailCard(index: Int, annotation: FootprintAnnotation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Footprint \(index + 1)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(annotation.size.label)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            HStack {
                Text("Position:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("(\(annotation.position.x, specifier: "%.3f"), \(annotation.position.y, specifier: "%.3f"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if annotation.scaleMultiplier != 1.0 {
                HStack {
                    Text("Scale:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(annotation.scaleMultiplier, specifier: "%.1f")x")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}