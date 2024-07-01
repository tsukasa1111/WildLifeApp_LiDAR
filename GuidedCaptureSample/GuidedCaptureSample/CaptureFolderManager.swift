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

// ロガーの設定
private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem,
                            category: "CaptureFolderManager")

@Observable
class CaptureFolderManager {
    // エラーの列挙型定義
    enum Error: Swift.Error {
        case notFileUrl
        case creationFailed
        case alreadyExists
        case invalidShotUrl
    }

    // アプリのドキュメントフォルダ．
    let appDocumentsFolder: URL = URL.documentsDirectory

    // キャプチャディレクトリimagesFolder, checkpointFolder, modelsFolderを含む
    // init()時にタイムスタンプと共に自動作成
    let captureFolder: URL

    // 画像を保存するためのサブディレクトリ
    let imagesFolder: URL

    // 再構築チェックポイントを保存するためのサブディレクトリ
    let checkpointFolder: URL

    // 作成されたモデルを保存するためのサブディレクトリ
    let modelsFolder: URL

    // 画像フォルダの名前
    static let imagesFolderName = "Images/"

    init() throws {
        // 新しいキャプチャディレクトリを作成
        guard let newFolder = CaptureFolderManager.createNewCaptureDirectory() else {
            throw Error.creationFailed
        }
        captureFolder = newFolder

        // サブディレクトリの作成
        imagesFolder = newFolder.appendingPathComponent(Self.imagesFolderName)
        try CaptureFolderManager.createDirectoryRecursively(imagesFolder)

        checkpointFolder = newFolder.appendingPathComponent("Checkpoint/")
        try CaptureFolderManager.createDirectoryRecursively(checkpointFolder)

        modelsFolder = newFolder.appendingPathComponent("Models/")
        try CaptureFolderManager.createDirectoryRecursively(modelsFolder)
    }

    // - MARK:  Private Interface

    // 現在のタイムスタンプに基づいて新しいキャプチャディレクトリをトップレベルのドキュメントフォルダに作成
    // 失敗した場合はnilを返す
    // 画像とチェックポイントのサブディレクトリを含む
    // - Returns: 作成されたフォルダのファイルURL．エラー時にはnilを返す
    private static func createNewCaptureDirectory() -> URL? {
        // Info.plistを設定して共有を許可し，Filesアプリからアプリのドキュメントディレクトリが見えるようにする．
        // これにより，AirDrop，メール，iCloudなどを通じてフォルダをエンジンのmacOSプラットフォームに移動できる
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())
        let newCaptureDir = URL.documentsDirectory
            .appendingPathComponent(timestamp, isDirectory: true)

        logger.log("Creating capture path: \"\(String(describing: newCaptureDir))\"")
        let capturePath = newCaptureDir.path
        do {
            try FileManager.default.createDirectory(atPath: capturePath,
                                                    withIntermediateDirectories: true)
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

    // 全てのパスコンポーネントを作成し，存在するまで再帰的に作成．ファイルが既に存在する場合はエラーを投げる
    private static func createDirectoryRecursively(_ outputDir: URL) throws {
        guard outputDir.isFileURL else {
            throw CaptureFolderManager.Error.notFileUrl
        }
        let expandedPath = outputDir.path
        var isDirectory: ObjCBool = false

        // ファイルが既に存在する場合はエラーを投げる
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

    // キャプチャIDの前に付加される文字列
    private static let imageStringPrefix = "IMG_"
    // HEIC画像の拡張子
    private static let heicImageExtension = "HEIC"
}
