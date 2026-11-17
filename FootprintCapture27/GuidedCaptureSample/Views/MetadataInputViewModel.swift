import SwiftUI
import CoreLocation
import os

@MainActor
final class MetadataInputViewModel: ObservableObject {
    // Footprint presence
    @Published var hasFootprint: Bool = true

    // Common fields
    @Published var weather: String = "晴れ"
    @Published var softness: Int = 2
    @Published var notes: String = ""

    // Footprint-specific
    @Published var animalType: String = "イノシシ"
    @Published var otherAnimal: String = ""
    @Published var hasCompletedAnnotation = false
    @Published var showingFootprintAnnotation = false
    @Published var thumbnailImage: UIImage?
    @Published var isLoadingThumbnail = false
    @Published var selectedImageIndex: Int = 2
    @Published var availableImages: [URL] = []
    @Published var showImageSelector = false

    // Validation UI
    @Published var showValidationError: Bool = false
    @Published var validationMessage: String = ""
    @Published var isSaving: Bool = false

    let animalTypes = [
        ("イノシシ", "🐗", "Sus scrofa"),
        ("シカ", "🦌", "Cervus nippon"),
        ("その他", "🐾", "不明な動物")
    ]
    let weatherOptions = [
        ("晴れ", "☀️", "sun.max.fill"),
        ("曇り", "☁️", "cloud.fill"),
        ("雨", "🌧️", "cloud.rain.fill"),
        ("雪", "❄️", "cloud.snow.fill"),
        ("霧", "🌫️", "cloud.fog.fill"),
        ("その他", "❓", "questionmark.circle.fill")
    ]
    let softnessOptions = [
        (1, "🪨", "硬い"),
        (2, "🟤", "普通"),
        (3, "🤎", "柔らかい")
    ]

    private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "MetadataInputVM")

    // MARK: - Validation
    var isValidInput: Bool {
        if hasFootprint && animalType == "その他" {
            let trimmed = otherAnimal.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty && trimmed.count <= 20 && notes.count <= 200
        }
        return notes.count <= 200
    }

    var validationErrors: [String] {
        var errors: [String] = []
        if hasFootprint && animalType == "その他" {
            let trimmed = otherAnimal.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { errors.append("動物名を入力してください") }
            else if trimmed.count > 20 { errors.append("動物名は20文字以内で入力してください") }
        }
        if notes.count > 200 { errors.append("メモは200文字以内で入力してください") }
        return errors
    }

    // MARK: - Actions
    func openFootprintAnnotation() {
        guard hasFootprint else { return }
        if thumbnailImage == nil { /* defer actual load to view trigger */ }
        showingFootprintAnnotation = true
    }

    func loadAvailableImages(appModel: AppDataModel) {
        guard let cfm = appModel.captureFolderManager else { return }
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: cfm.imagesFolder,
                includingPropertiesForKeys: nil,
                options: []
            )
            availableImages = contents.filter { !$0.hasDirectoryPath }.sorted { $0.path < $1.path }
            if selectedImageIndex >= availableImages.count && !availableImages.isEmpty {
                selectedImageIndex = availableImages.count - 1
            }
            logger.log("Found \\(self.availableImages.count) images, selected index: \\(self.selectedImageIndex)")
        } catch {
            logger.error("Failed to load available images: \\(error.localizedDescription)")
            availableImages = []
        }
    }

    func loadThumbnailImage(appModel: AppDataModel) {
        guard let cfm = appModel.captureFolderManager else {
            logger.error("CaptureFolderManager is nil")
            return
        }
        isLoadingThumbnail = true
        Task {
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: cfm.imagesFolder,
                    includingPropertiesForKeys: nil,
                    options: []
                )
                let sorted = contents.filter { !$0.hasDirectoryPath }.sorted { $0.path < $1.path }
                let chosenURL: URL
                if selectedImageIndex < sorted.count {
                    chosenURL = sorted[self.selectedImageIndex]
                    logger.log("Using selected image \\(self.selectedImageIndex + 1): \\(chosenURL.lastPathComponent)")
                } else if let last = sorted.last {
                    chosenURL = last
                    logger.log("Index out of range, using last image: \\(chosenURL.lastPathComponent)")
                } else {
                    logger.error("No images found in capture folder")
                    await MainActor.run { self.isLoadingThumbnail = false }
                    return
                }
                let data = try Data(contentsOf: chosenURL)
                guard let uiImage = UIImage(data: data) else {
                    logger.error("Failed to create UIImage from data")
                    await MainActor.run { self.isLoadingThumbnail = false }
                    return
                }
                await MainActor.run {
                    self.thumbnailImage = uiImage
                    self.isLoadingThumbnail = false
                    logger.log("Successfully loaded thumbnail image")
                }
            } catch {
                logger.error("Failed to load thumbnail image: \\(error.localizedDescription)")
                await MainActor.run { self.isLoadingThumbnail = false }
            }
        }
    }

    func loadThumbnailImageSynchronously(appModel: AppDataModel) {
        logger.log("Loading thumbnail image synchronously...")
        loadThumbnailImage(appModel: appModel)
    }

    func checkAnnotationCompletion(appModel: AppDataModel) {
        guard hasFootprint, let cfm = appModel.captureFolderManager else {
            hasCompletedAnnotation = false
            return
        }
        let annotatedImageURL = cfm.captureFolder.appendingPathComponent("annotated_footprints.jpg")
        hasCompletedAnnotation = FileManager.default.fileExists(atPath: annotatedImageURL.path)
        logger.log("Annotation completion check: \\(self.hasCompletedAnnotation)")
    }

    func saveMetadata(appModel: AppDataModel) async {
        guard !isSaving else { return }
        let errors = validationErrors
        if !errors.isEmpty {
            validationMessage = errors.joined(separator: "\n")
            showValidationError = true
            return
        }
        isSaving = true
        do {
            let metadata = TraceMetadata(
                hasFootprint: hasFootprint,
                animalType: hasFootprint ? (animalType == "その他" ? otherAnimal : animalType) : "",
                traceType: hasFootprint ? "足跡" : "調査地点",
                weather: weather,
                substrate: softnessOptions.first(where: { $0.0 == softness })?.2,
                notes: notes.isEmpty ? nil : notes,
                location: appModel.scanStartLocation ?? appModel.currentLocation,
                timestamp: Date()
            )
            guard let cfm = appModel.captureFolderManager else {
                throw NSError(domain: "MetadataInputView", code: 1, userInfo: [NSLocalizedDescriptionKey: "CaptureFolderManager not found"])
            }
            let url = cfm.captureFolder.appendingPathComponent("metadata.json")
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let json = try encoder.encode(metadata)
            try json.write(to: url)
            logger.log("📅 Saved metadata with timestamp: \\(metadata.timestamp)")
            logger.log("📁 Saved to: \\(url.path)")
            await MainActor.run {
                self.isSaving = false
                appModel.state = .metadataCompleted
            }
        } catch {
            logger.error("Failed to save metadata: \\(error.localizedDescription)")
            await MainActor.run {
                self.isSaving = false
                self.validationMessage = "保存に失敗しました: \\(error.localizedDescription)"
                self.showValidationError = true
            }
        }
    }
}
