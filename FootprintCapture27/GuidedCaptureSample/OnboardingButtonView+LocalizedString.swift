/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The localized strings used by OnboardingButtonView.
*/

import Foundation

extension OnboardingButtonView {
    struct LocalizedString {
        static let `continue` = NSLocalizedString(
            "Continue (Object Capture, Review)",
            bundle: Bundle.main,
            value: "続ける",
            comment: "Title of button to continue to flip the object and capture more."
        )

        static let finish = NSLocalizedString(
            "Finish (Object Capture, Review)",
            bundle: Bundle.main,
            value: "完了",
            comment: "Title for finish button on the review screen."
        )

        static let process = NSLocalizedString(
            "Process (Object Capture, Review)",
            bundle: Bundle.main,
            value: "処理",
            comment: "Title for process button on the review screen."
        )

        static let skip = NSLocalizedString(
            "Skip (Object Capture, Review)",
            bundle: Bundle.main,
            value: "スキップ",
            comment: "Title for skip button on the review screen."
        )

        static let cannotFlipYourObject = NSLocalizedString(
            "Can't flip your object? (Object Capture, Review)",
            bundle: Bundle.main,
            value: "オブジェクトを回転できませんか？",
            comment: "Title for button on the object capture screen that lets users indicate that their object cannot be flipped."
        )

        static let flipAnyway = NSLocalizedString(
            "Flip object anyway (Object Capture, Review)",
            bundle: Bundle.main,
            value: "とにかく回転する",
            comment: "Title for button on the object capture screen that lets users indicate they want to flip their object."
        )

        static let saveDraft = NSLocalizedString(
            "Save Draft (Object Capture, Review)",
            bundle: Bundle.main,
            value: "下書き保存",
            comment: "Title for button to finish the session and run reconstruction later."
        )

        static let cancel = NSLocalizedString(
            "Cancel button (Object Capture, Review)",
            bundle: Bundle.main,
            value: "キャンセル",
            comment: "Title of button to go back to capturing."
        )
        
        static let inputMetadata = NSLocalizedString(
            "Input Metadata (Object Capture, Review)",
            bundle: Bundle.main,
            value: "詳細情報を入力",
            comment: "Title for button to input metadata about the captured object."
        )
    }
}
