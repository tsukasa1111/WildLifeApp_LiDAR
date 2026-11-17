/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The guidance view that shows the video tutorial or the point cloud on the review screen.
*/

import RealityKit
import SwiftUI

/// The view that either shows the point cloud or plays the guidance tutorials on the review screens, depending on
/// `currentState` in `onboardingStateMachine`.
struct OnboardingTutorialView: View {
    @EnvironmentObject var appModel: AppDataModel
    var session: ObjectCaptureSession
    var onboardingStateMachine: OnboardingStateMachine
    @Binding var showShotLocations: Bool
    var viewSize: CGSize

    var body: some View {
        VStack {
            let frameSize = min(viewSize.width, viewSize.height) * (UIDevice.current.userInterfaceIdiom == .pad ? 0.6 : 0.8)
            switch appModel.captureMode {
                case .object:
                    // シンプルなプレビューのみ
                    VStack {
                        Spacer()
                        ObjectCapturePointCloudView(session: session)
                            .showShotLocations(showShotLocations)
                        Spacer()
                    }
                    .frame(width: frameSize, height: frameSize)
                case .area:
                    Spacer().frame(height: 30)
                    ObjectCapturePointCloudView(session: session)
                        .showShotLocations(showShotLocations)
                        .frame(width: frameSize, height: frameSize)
                }

            VStack {
                Text(title)
                    .font(.title2)
                    .lineLimit(2)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)

                Text(detailText)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .lineLimit(3)
                
                // Show current image count for tooFewImages state
                if onboardingStateMachine.currentState == .tooFewImages {
                    let currentImageCount = session.numberOfShotsTaken
                    Text(String(format: NSLocalizedString("Currently %d of %d images captured", comment: "Current progress of image capture"), currentImageCount, AppDataModel.minNumImages))
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }

                Spacer().frame(height: 40)
            }
            .foregroundColor(.primary)
            .frame(maxHeight: .infinity)
            .padding([.leading, .trailing], 20)
        }
    }

    private var shouldShowTutorialInReview: Bool {
        switch onboardingStateMachine.currentState {
            case .flipObject, .flipObjectASecondTime, .captureFromLowerAngle, .captureFromHigherAngle:
                return true
            default:
                return false
        }
    }

    private let onboardingStateToTutorialNameMapOnIphone: [ OnboardingState: String ] = [
        .flipObject: "ScanPasses-iPhone-FixedHeight-2",
        .flipObjectASecondTime: "ScanPasses-iPhone-FixedHeight-3",
        .captureFromLowerAngle: "ScanPasses-iPhone-FixedHeight-unflippable-low",
        .captureFromHigherAngle: "ScanPasses-iPhone-FixedHeight-unflippable-high"
    ]

    private let onboardingStateToTutorialNameMapOnIpad: [ OnboardingState: String ] = [
        .flipObject: "ScanPasses-iPad-FixedHeight-2",
        .flipObjectASecondTime: "ScanPasses-iPad-FixedHeight-3",
        .captureFromLowerAngle: "ScanPasses-iPad-FixedHeight-unflippable-low",
        .captureFromHigherAngle: "ScanPasses-iPad-FixedHeight-unflippable-high"
    ]

    private var tutorialUrl: URL? {
        let videoName: String
        if UIDevice.current.userInterfaceIdiom == .pad {
            videoName = onboardingStateToTutorialNameMapOnIpad[onboardingStateMachine.currentState] ?? "ScanPasses-iPad-FixedHeight-1"
        } else {
            videoName = onboardingStateToTutorialNameMapOnIphone[onboardingStateMachine.currentState] ?? "ScanPasses-iPhone-FixedHeight-1"
        }
        return Bundle.main.url(forResource: videoName, withExtension: "mp4")
    }

    private func getOrbitImageName(orbit: AppDataModel.Orbit) -> String? {
        guard let session = appModel.objectCaptureSession else { return nil }
        let orbitCompleted = session.userCompletedScanPass
        let orbitCompleteImage = orbit <= appModel.orbit ? orbit.imageSelected : orbit.image
        let orbitNotCompleteImage = orbit < appModel.orbit ? orbit.imageSelected : orbit.image
        return orbitCompleted ? orbitCompleteImage : orbitNotCompleteImage
    }

    private let onboardingStateToTitleMap: [ OnboardingState: String ] = [
        .tooFewImages: LocalizedString.tooFewImagesTitle,
        .firstSegmentNeedsWork: LocalizedString.firstSegmentNeedsWorkTitle,
        .firstSegmentComplete: LocalizedString.firstSegmentCompleteTitle,
        .secondSegmentNeedsWork: LocalizedString.secondSegmentNeedsWorkTitle,
        .secondSegmentComplete: LocalizedString.secondSegmentCompleteTitle,
        .thirdSegmentNeedsWork: LocalizedString.thirdSegmentNeedsWorkTitle,
        .thirdSegmentComplete: LocalizedString.thirdSegmentCompleteTitle,
        .flipObject: LocalizedString.flipObjectTitle,
        .flipObjectASecondTime: LocalizedString.flipObjectASecondTimeTitle,
        .flippingObjectNotRecommended: LocalizedString.flippingObjectNotRecommendedTitle,
        .captureFromLowerAngle: LocalizedString.captureFromLowerAngleTitle,
        .captureFromHigherAngle: LocalizedString.captureFromHigherAngleTitle,
        .captureInAreaMode: LocalizedString.captureInAreaModeTitle
    ]

    private var title: String {
        onboardingStateToTitleMap[onboardingStateMachine.currentState] ?? ""
    }

    private let onboardingStateToDetailTextMap: [ OnboardingState: String ] = [
        .tooFewImages: String(format: LocalizedString.tooFewImagesDetailText, AppDataModel.minNumImages),
        .firstSegmentNeedsWork: LocalizedString.firstSegmentNeedsWorkDetailText,
        .firstSegmentComplete: LocalizedString.firstSegmentCompleteDetailText,
        .secondSegmentNeedsWork: LocalizedString.secondSegmentNeedsWorkDetailText,
        .secondSegmentComplete: LocalizedString.secondSegmentCompleteDetailText,
        .thirdSegmentNeedsWork: LocalizedString.thirdSegmentNeedsWorkDetailText,
        .thirdSegmentComplete: LocalizedString.thirdSegmentCompleteDetailText,
        .flipObject: LocalizedString.flipObjectDetailText,
        .flipObjectASecondTime: LocalizedString.flipObjectASecondTimeDetailText,
        .flippingObjectNotRecommended: LocalizedString.flippingObjectNotRecommendedDetailText,
        .captureFromLowerAngle: LocalizedString.captureFromLowerAngleDetailText,
        .captureFromHigherAngle: LocalizedString.captureFromHigherAngleDetailText,
        .captureInAreaMode: LocalizedString.captureInAreaModeDetailText
    ]

    private var detailText: String {
        onboardingStateToDetailTextMap[onboardingStateMachine.currentState] ?? ""
    }
}
