/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class to support the creation, listing, and filename support of a
 capture folder in the Documents directory which will contain three
 subdirectories --- one for images, one for reconstruction checkpoint,
 and one for the created model.
*/

import Foundation
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem,
                            category: "CaptureFolderManager")

@Observable
class CaptureFolderManager {
    enum Error: Swift.Error {
        case notFileUrl
        case creationFailed
        case alreadyExists
        case invalidShotUrl
    }

    // The app's documents folder that includes captures from all sessions.
    let appDocumentsFolder: URL = URL.documentsDirectory

    // Top-level capture directory that contains imagesFolder, checkpointFolder, and modelsFolder.
    // Automatically created at init() with timestamp.
    let captureFolder: URL

    // Subdirectory of captureFolder to store the images.
    let imagesFolder: URL

    // Subdirectory of captureFolder to store the reconstruction checkpoint.
    let checkpointFolder: URL

    // Subdirectory of captureFolder to store the created model.
    let modelsFolder: URL

    static let imagesFolderName = "Images/"

    init() throws {
        guard let newFolder = CaptureFolderManager.createNewCaptureDirectory() else {
            throw Error.creationFailed
        }
        captureFolder = newFolder

        // Create the subdirectories
        imagesFolder = newFolder.appendingPathComponent(Self.imagesFolderName)
        try CaptureFolderManager.createDirectoryRecursively(imagesFolder)

        checkpointFolder = newFolder.appendingPathComponent("Checkpoint/")
        try CaptureFolderManager.createDirectoryRecursively(checkpointFolder)

        modelsFolder = newFolder.appendingPathComponent("Models/")
        try CaptureFolderManager.createDirectoryRecursively(modelsFolder)
    }
    
    // 既存フォルダ用のイニシャライザ（一括処理用）
    init(existingFolder: URL) throws {
        captureFolder = existingFolder
        
        // 既存のサブディレクトリを設定
        imagesFolder = existingFolder.appendingPathComponent(Self.imagesFolderName)
        checkpointFolder = existingFolder.appendingPathComponent("Checkpoint/")
        modelsFolder = existingFolder.appendingPathComponent("Models/")
        
        // サブディレクトリが存在しない場合は作成
        if !FileManager.default.fileExists(atPath: checkpointFolder.path) {
            try CaptureFolderManager.createDirectoryRecursively(checkpointFolder)
        }
        
        if !FileManager.default.fileExists(atPath: modelsFolder.path) {
            try CaptureFolderManager.createDirectoryRecursively(modelsFolder)
        }
        
        // Imagesフォルダは必須
        guard FileManager.default.fileExists(atPath: imagesFolder.path) else {
            throw Error.creationFailed
        }
    }

    // - MARK: Private interface below.

    // Creates a new capture directory based on the current timestamp in the top level Documents
    // folder. Otherwise, returns nil on failure.
    // Contains Images and Checkpoint subdirectories.
    //
    // - Returns: the created folder's file URL, else nil on error.
    private static func createNewCaptureDirectory() -> URL? {
        // Set the Info.plist to allow sharing so the app documents directory is visible
        // from the Files app for viewing, deleting, and sharing with AirDrop, Mail, iCloud, etc to move
        // the folder to the engine macOS platform.
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())
        let newCaptureDir = URL.documentsDirectory
            .appendingPathComponent("\(timestamp)-\(UUID().uuidString)", isDirectory: true)

        logger.log("Creating capture path: \"\(String(describing: newCaptureDir))\"")
        let capturePath = newCaptureDir.path
        do {
            try FileManager.default.createDirectory(atPath: capturePath,
                                                    withIntermediateDirectories: false)
        } catch {
            logger.error("Failed to create capturepath=\"\(capturePath)\" error=\(String(describing: error))")
            return nil
        }
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: capturePath, isDirectory: &isDir)
        guard exists && isDir.boolValue else {
            return nil
        }

        return newCaptureDir
    }

    // Creates all path components until it exists, else throws.
    // Throws if the file already exists as well.
    private static func createDirectoryRecursively(_ outputDir: URL) throws {
        guard outputDir.isFileURL else {
            throw CaptureFolderManager.Error.notFileUrl
        }
        let expandedPath = outputDir.path
        var isDirectory: ObjCBool = false

        guard !FileManager.default.fileExists(atPath: outputDir.path, isDirectory: &isDirectory) else {
            logger.error("File already exists at \(expandedPath, privacy: .private)")
            throw CaptureFolderManager.Error.alreadyExists
        }

        logger.log("Creating dir recursively: \"\(expandedPath, privacy: .private)\"")
        try FileManager.default.createDirectory(atPath: expandedPath,
                               withIntermediateDirectories: true)

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDir) && isDir.boolValue else {
            logger.error("Dir \"\(expandedPath, privacy: .private)\" doesn't exist after creation!")
            throw CaptureFolderManager.Error.creationFailed
        }
        logger.log("... success creating dir.")
    }

    // What is appended in front of the capture id to get a file basename.
    private static let imageStringPrefix = "IMG_"
    private static let heicImageExtension = "HEIC"
    
    // MARK: - Point Cloud Support
    
    static let pointCloudFileName = "ultra_high_density_pointcloud.ply"
    private static let pointCloudFileNames = [
        "traditional_pointcloud.ply",
        "standard_pointcloud.ply",
        pointCloudFileName,
        "research_grade_pointcloud.ply"
    ]
    
    var pointCloudURL: URL {
        return captureFolder.appendingPathComponent(Self.pointCloudFileName)
    }
    
    // MARK: - Footprint Annotation Support
    
    static let annotatedImageFileName = "annotated_footprints.jpg"
    static let annotationMetadataFileName = "footprint_annotations.json"
    
    var annotatedImageURL: URL {
        return captureFolder.appendingPathComponent(Self.annotatedImageFileName)
    }
    
    var annotationMetadataURL: URL {
        return captureFolder.appendingPathComponent(Self.annotationMetadataFileName)
    }
    
    func hasAnnotatedImage() -> Bool {
        return FileManager.default.fileExists(atPath: annotatedImageURL.path)
    }
    
    func hasAnnotationMetadata() -> Bool {
        return FileManager.default.fileExists(atPath: annotationMetadataURL.path)
    }
    
    func loadAnnotationMetadata() -> AnnotationMetadata? {
        guard hasAnnotationMetadata() else { return nil }
        
        do {
            let data = try Data(contentsOf: annotationMetadataURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(AnnotationMetadata.self, from: data)
        } catch {
            logger.error("Failed to load annotation metadata: \(error)")
            return nil
        }
    }
    
    func hasPointCloud() -> Bool {
        // Check for any of the four point cloud types
        for fileName in Self.pointCloudFileNames {
            let url = captureFolder.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: url.path) {
                return true
            }
        }
        return false
    }
    
    func getPointCloudFileSize() -> Int64? {
        for fileName in Self.pointCloudFileNames {
            let url = captureFolder.appendingPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let size = attributes[.size] as? Int64 { return size }
            } catch {
                logger.error("Failed to get point cloud file size: \(error)")
            }
        }
        return nil
    }
    
    // MARK: - 3D Model Support
    
    /// 3Dモデルファイルが存在するかチェック
    func has3DModel() -> Bool {
        let modelTypes = [
            "model-mobile.usdz",
            "background-model.usdz",
            "model.usdz"
        ]
        
        for fileName in modelTypes {
            let url = modelsFolder.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: url.path) {
                return true
            }
        }
        return false
    }
    
    /// 処理可能（画像があるが3Dモデルがない）かチェック
    func needsProcessing() -> Bool {
        return hasImages() && !has3DModel() && !hasProcessingError()
    }
    
    /// 3Dモデル生成エラーが記録されているかチェック
    func hasProcessingError() -> Bool {
        let errorFile = self.captureFolder.appendingPathComponent("processing_error.txt")
        return FileManager.default.fileExists(atPath: errorFile.path)
    }
    
    /// 3Dモデル生成エラーを記録
    func recordProcessingError(_ error: Swift.Error) {
        let errorFile = self.captureFolder.appendingPathComponent("processing_error.txt")
        let errorInfo = """
        Error: \(error.localizedDescription)
        Timestamp: \(ISO8601DateFormatter().string(from: Date()))
        Images Count: \(self.getImageCount())
        """
        
        do {
            try errorInfo.write(to: errorFile, atomically: true, encoding: .utf8)
            logger.log("Recorded processing error for capture: \(self.captureFolder.lastPathComponent)")
        } catch {
            logger.error("Failed to record processing error: \(error)")
        }
    }
    
    /// エラー記録をクリア（再試行時）
    func clearProcessingError() {
        let errorFile = self.captureFolder.appendingPathComponent("processing_error.txt")
        try? FileManager.default.removeItem(at: errorFile)
    }
    
    /// 処理状態を取得
    func getProcessingStatus() -> ProcessingStatus {
        if has3DModel() {
            return .completed
        } else if hasProcessingError() {
            return .error
        } else if hasImages() {
            return .needsProcessing
        } else {
            return .noImages
        }
    }
    
    enum ProcessingStatus {
        case completed      // 3Dモデルあり
        case needsProcessing // 画像ありだが3Dモデルなし
        case error          // 処理エラー記録あり
        case noImages       // 画像なし
    }
    
    /// 画像が存在するかチェック
    private func hasImages() -> Bool {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: imagesFolder, includingPropertiesForKeys: nil)
            let imageFiles = contents.filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "heic" || ext == "jpg" || ext == "jpeg"
            }
            return !imageFiles.isEmpty
        } catch {
            return false
        }
    }
    
    /// キャプチャの画像数を取得
    func getImageCount() -> Int {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: imagesFolder, includingPropertiesForKeys: nil)
            let imageFiles = contents.filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "heic" || ext == "jpg" || ext == "jpeg"
            }
            return imageFiles.count
        } catch {
            return 0
        }
    }
}
