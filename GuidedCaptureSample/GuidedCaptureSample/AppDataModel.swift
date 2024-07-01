import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem,
                            category: "AppDataModel")

@MainActor
@Observable
class AppDataModel: Identifiable {
    static let instance = AppDataModel()
    
    /// キャプチャを開始するときに、captureFolderManagerの場所を設定
    var objectCaptureSession: ObjectCaptureSession? {
        willSet {
            detachListeners()
        }
        didSet {
            guard objectCaptureSession != nil else { return }
            attachListeners()
        }
    }

    static let minNumImages = 10

    /// 再構築部分に向かうときに、セッションを保持
    private(set) var photogrammetrySession: PhotogrammetrySession?

    /// 新しいキャプチャを開始するときに、フォルダを設定
    private(set) var captureFolderManager: CaptureFolderManager?

    /// ユーザーが再構築をスキップすることを決定したか
    private(set) var isSaveDraftEnabled = false

    var messageList = TimedMessageList()

    enum ModelState {
        case notSet
        case ready
        case capturing
        case prepareToReconstruct
        case reconstructing
        case viewing
        case completed
        case restart
        case failed
    }

    var state: ModelState = .notSet {
        didSet {
            logger.debug("didSet AppDataModel.state to \(String(describing: self.state))")
            performStateTransition(from: oldValue, to: state)
        }
    }

    var orbit: Orbit = .orbit1
    var isObjectFlipped: Bool = false

    var hasIndicatedObjectCannotBeFlipped: Bool = false
    var hasIndicatedFlipObjectAnyway: Bool = false
    var isObjectFlippable: Bool {
        //ユーザーがオブジェクトを反転できないと示した場合やオブジェクトを反転しても良いと示した場合にフィードバックを上書き
        guard !hasIndicatedObjectCannotBeFlipped else { return false }
        guard !hasIndicatedFlipObjectAnyway else { return true }
        guard let session = objectCaptureSession else { return true }
        return !session.feedback.contains(.objectNotFlippable)
    }

    enum CaptureMode: Equatable {
        case object
        case area
    }

    var captureMode: CaptureMode = .object

    // 状態が失敗に移行したとき，これが原因
    private(set) var error: Swift.Error?

    //ObjectCaptureViewを非表示にしないよう，ObjectCaptureSessionの一時停止状態を適切に維持す
    private(set) var showOverlaySheets = false

    // チュートリアルがセッション中に一度再生されたかどうかを示.
    var tutorialPlayedOnce = false

    // ObjectCaptureSessionとPhotogrammetrySessionの作成を必要になるまで延ばす
    private init() {
        state = .ready
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppTermination(notification:)),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        DispatchQueue.main.async {
            self.detachListeners()
        }
    }

    //再構築とビューイングが完了したら，新しいキャプチャビューに戻ることができるようにアプリに知らせるためにこれを呼び出す
    //ここでは明示的にモデルを破壊しない．スプラッシュスクリーンが開始するときにAppDataModelをクリーンな状態に設定
    //これはキャンセルまたはエラー再構築後に開始画面に戻るためにも呼び出すことが可能．
    func endCapture() {
        state = .completed
    }

    func removeCaptureFolder() {
        logger.log("Removing the capture folder...")
        guard let url = captureFolderManager?.captureFolder else { return }
        try? FileManager.default.removeItem(at: url)
    }

    // showOverlaySheetsを直接操作しない．代わりにsetShowOverlaySheets()を呼び出し．
    // シートを使用し、ObjectCaptureViewを画面に表示したままにしてぼかす．手動でセッションを一時停止/再開する
    func setShowOverlaySheets(to shown: Bool) {
        guard shown != showOverlaySheets else { return }
        if shown {
            showOverlaySheets = true
            objectCaptureSession?.pause()
        } else {
            objectCaptureSession?.resume()
            showOverlaySheets = false
        }
    }

    func saveDraft() {
        objectCaptureSession?.finish()
        isSaveDraftEnabled = true
    }

    // - MARK: Private Interface

    private var currentFeedback: Set<Feedback> = []

    private typealias Feedback = ObjectCaptureSession.Feedback
    private typealias Tracking = ObjectCaptureSession.Tracking

    private var tasks: [ Task<Void, Never> ] = []
}

extension AppDataModel {
    private func attachListeners() {
        logger.debug("Attaching listeners...")
        guard let model = objectCaptureSession else {
            fatalError("Logic error")
        }
        
        tasks.append(
            Task<Void, Never> { [weak self] in
                for await newFeedback in model.feedbackUpdates {
                    logger.debug("Task got async feedback change to: \(String(describing: newFeedback))")
                    self?.updateFeedbackMessages(for: newFeedback)
                }
                logger.log("^^^ Got nil from stateUpdates iterator!  Ending observation task...")
            })
        
        tasks.append(Task<Void, Never> { [weak self] in
            for await newState in model.stateUpdates {
                logger.debug("Task got async state change to: \(String(describing: newState))")
                self?.onStateChanged(newState: newState)
            }
            logger.log("^^^ Got nil from stateUpdates iterator!  Ending observation task...")
        })
    }
    
    private func detachListeners() {
        logger.debug("Detaching listeners...")
        for task in tasks {
            task.cancel()
        }
        tasks.removeAll()
    }
    
    @objc
    private func handleAppTermination(notification: Notification) {
        logger.log("Notification for the app termination is received...")
        if state == .ready || state == .capturing {
            removeCaptureFolder()
        }
    }
    
    
    // 新しいキャプチャを作成する際に呼び出す．セッションが必要になる前に呼び出し．
    private func startNewCapture() throws {
        logger.log("startNewCapture() called...")
        if !ObjectCaptureSession.isSupported {
            preconditionFailure("ObjectCaptureSession is not supported on this device!")
        }
        
        captureFolderManager = try CaptureFolderManager()
        objectCaptureSession = ObjectCaptureSession()
        
        guard let session = objectCaptureSession else {
            preconditionFailure("startNewCapture() got unexpectedly nil session!")
        }
        
        guard let captureFolderManager else {
            preconditionFailure("captureFolderManager unexpectedly nil!")
        }
        
        var configuration = ObjectCaptureSession.Configuration()
        configuration.isOverCaptureEnabled = true
        configuration.checkpointDirectory = captureFolderManager.checkpointFolder
        // 初期セグメントを開始し、出力場所を設定
        session.start(imagesDirectory: captureFolderManager.imagesFolder,
                      configuration: configuration)
        
        if case let .failed(error) = session.state {
            logger.error("Got error starting session! \(String(describing: error))")
            switchToErrorState(error: error)
        } else {
            state = .capturing
        }
    }
    
    private func switchToErrorState(error inError: Swift.Error) {
        // エラーを最初に設定します。遷移がnilではないことを前提
        error = inError
        state = .failed
    }
    
    // prepareToReconstructから.reconstructingに移行．
    // ReconstructionPrimaryView非同期タスクが画面に表示されたら呼び出し．
    private func startReconstruction() throws {
        logger.debug("startReconstruction() called.")
        
        var configuration = PhotogrammetrySession.Configuration()
        if captureMode == .area {
            configuration.isObjectMaskingEnabled = false
        }
        
        guard let captureFolderManager else {
            preconditionFailure("captureFolderManager unexpectedly nil!")
        }
        
        configuration.checkpointDirectory = captureFolderManager.checkpointFolder
        photogrammetrySession = try PhotogrammetrySession(
            input: captureFolderManager.imagesFolder,
            configuration: configuration)
        
        state = .reconstructing
    }
    
    private func reset() {
        logger.info("reset() called...")
        photogrammetrySession = nil
        objectCaptureSession = nil
        captureFolderManager = nil
        showOverlaySheets = false
        orbit = .orbit1
        isObjectFlipped = false
        currentFeedback = []
        messageList.removeAll()
        captureMode = .object
        state = .ready
        isSaveDraftEnabled = false
        tutorialPlayedOnce = false
    }
    
    private func onStateChanged(newState: ObjectCaptureSession.CaptureState) {
        logger.info("OCViewModel switched to state: \(String(describing: newState))")
        if case .completed = newState {
            logger.log("ObjectCaptureSession moved in .completed state.")
            if isSaveDraftEnabled {
                logger.log("The data is stored. Closing the session...")
                reset()
            } else {
                logger.log("Switch app model to reconstruction...")
                state = .prepareToReconstruct
            }
        } else if case let .failed(error) = newState {
            logger.error("OCS moved to error state \(String(describing: error))...")
            if case ObjectCaptureSession.Error.cancelled = error {
                state = .restart
            } else {
                switchToErrorState(error: error)
            }
        }
    }
    
    private func updateFeedbackMessages(for feedback: Set<Feedback>) {
        // 受け取ったフィードバックと以前のフィードバックを比較し，共通部分（交差）を見つける
        let persistentFeedback = currentFeedback.intersection(feedback)
        
        // もうアクティブでないフィードバックを見つける
        let feedbackToRemove = currentFeedback.subtracting(persistentFeedback)
        for thisFeedback in feedbackToRemove {
            if let feedbackString = FeedbackMessages.getFeedbackString(for: thisFeedback, captureMode: captureMode) {
                messageList.remove(feedbackString)
            }
        }
        
        // 新しいフィードバックを見つける
        let feedbackToAdd = feedback.subtracting(persistentFeedback)
        for thisFeedback in feedbackToAdd {
            if let feedbackString = FeedbackMessages.getFeedbackString(for: thisFeedback, captureMode: captureMode) {
                messageList.add(feedbackString)
            }
        }
        
        // 現在のフィードバックを更新する
        currentFeedback = feedback
    }
    
    private func performStateTransition(from fromState: ModelState, to toState: ModelState) {
        // 同じ状態間の遷移は無視する
        if fromState == toState { return }
        // 失敗状態から遷移するときはエラーをクリア
        if fromState == .failed { error = nil }
        
        switch toState {
        case .ready:
            do {
                // 新しいキャプチャを開始する
                try startNewCapture()
            } catch {
                logger.error("Starting new capture failed!")
            }
        case .prepareToReconstruct:
            // セッションをクリーンアップしてGPUとメモリリソースを解放する
            objectCaptureSession = nil
            do {
                // 再構築を開始する
                try startReconstruction()
            } catch {
                logger.error("Reconstructing failed!")
                switchToErrorState(error: error)
            }
        case .restart, .completed:
            // システムをリセットする
            reset()
        case .viewing:
            // フォトグラメトリーセッションをクリアする
            photogrammetrySession = nil
            // チェックポイントフォルダを削除する
            removeCheckpointFolder()
        case .failed:
            logger.error("App failed state error=\(String(describing: self.error!))")
            // エラースクリーンを表示する予定
        default:
            break
        }
    }
    
    private func removeCheckpointFolder() {
        // モデルが生成されたので、チェックポイントフォルダを削除してスペースを解放する
        if let captureFolderManager {
            DispatchQueue.global(qos: .background).async {
                try? FileManager.default.removeItem(at: captureFolderManager.checkpointFolder)
            }
        }
    }
    
    func determineCurrentOnboardingState() -> OnboardingState? {
        guard let session = objectCaptureSession else { return nil }
        
        switch captureMode {
        case .object:
            // ユーザーがスキャンパスを完了したかどうかを確認する
            let orbitCompleted = session.userCompletedScanPass
            var currentState = OnboardingState.tooFewImages
            // 撮影した画像の数が最小画像数以上であるかを確認する
            if session.numberOfShotsTaken >= AppDataModel.minNumImages {
                // 現在のオービットに応じてオンボーディングステートを設定する
                switch orbit {
                case .orbit1:
                    currentState = orbitCompleted ? .firstSegmentComplete : .firstSegmentNeedsWork
                case .orbit2:
                    currentState = orbitCompleted ? .secondSegmentComplete : .secondSegmentNeedsWork
                case .orbit3:
                    currentState = orbitCompleted ? .thirdSegmentComplete : .thirdSegmentNeedsWork
                }
            }
            return currentState
        case .area:
            return .captureInAreaMode
        }
    }
}
