# GuidedCaptureSample — 分割計画（進行中）

## ゴール
- 大型 SwiftUI View を安全に分割し、依存を明確化。
- 将来の MVVM 化に備え、責務を View / Components / Models / Utils に整理。

## 現在の構成（目標ディレクトリ）

```
GuidedCaptureSample/
├── Models/
│   └── FootprintTypes.swift
├── Views/
│   ├── Components/
│   │   ├── AnnotationControlPanel.swift
│   │   ├── FootprintMarker.swift
│   │   └── SavedFootprintMarker.swift
│   ├── TopOverlay/
│   │   ├── CustomConfirmationDialog.swift  (GC_CustomConfirmationDialog)
│   │   ├── CustomImageSelectorView.swift   (GC_CustomImageSelectorView)
│   │   └── FootprintConfirmationView.swift (GC_FootprintConfirmationView)
│   └── FootprintAnnotationView.swift       (本体: 参照のみ)
└── Utils/
    └── OrientationTransform.swift
```

## ステップ計画（小刻み）

1) FootprintAnnotationView の分割ターゲットを整理（完了）
2) 座標/向き関連のユーティリティ抽出（進行中）
3) アノテーション用キャンバス View を抽出
4) 本体からキャンバス差し替え（ビルド確認）
5) ツールバー群のアクション/レイアウト抽出
6) 本体からツールバー差し替え（ビルド確認）
7) クリンナップ（不要コードの削除・import 最小化）

各ステップごとに:
- 新ファイルを Xcode の Target に追加
- Clean Build で差分エラーを最小修正
- 次ステップへ進む

## メモ
- `.toolbar` の曖昧性は `SwiftUI.ToolbarItem` 指定で解消。
- 未使用 View はターゲットから外す選択肢も考慮（将来用なら残す）。

