# いのしかとーる

動物の足跡を撮影し、位置・環境情報と画像上の足跡マーカーを保存するiOSアプリです。`FootprintCapture27` は調査対象の27版を基にしています。

## 動作環境

- 撮影: LiDARスキャナ、A14 Bionic以降、iOS / iPadOS 18以降を備えた実機
- ビルド: Xcode 16.4以降
- シミュレータ: ビルドと撮影不可時のキャプチャ一覧表示を確認できます。撮影と3D復元は実機が必要です。

## 主な流れ

1. アプリを開き、カメラ権限を許可して撮影します。
2. 足跡の有無、動物、天候、地面の状態などを入力します。
3. 必要に応じて画像を選び、足跡マーカーを配置して保存します。
4. 3Dモデルを生成するか、写真とメタデータを下書きとして保存します。
5. キャプチャ一覧から画像、注釈、メタデータ、生成した3Dモデルを確認します。

記録はアプリのDocuments内のキャプチャフォルダに保存します。主なファイルは `Images/`、`metadata.json`、`annotated_footprints.jpg`、`footprint_annotations.json`、`Models/` です。

通常の撮影経路はRealityKitのObject Captureを使います。点群と3Dモデルは写真を用いた再構成結果です。再構成時に保存する点群は1ファイルです。ARKitの深度マップを読むリアルタイム・ハイブリッド画面もソースにありますが、現在のメイン画面からは開けません。研究データとして扱う前に、実機で座標、縮尺、精度を検証してください。

## ビルド確認

`.github/workflows/ios-build.yml` でiOSシミュレータ向けビルドと、撮影非対応時の一覧起動を確認します。手元でのビルド例:

```sh
xcodebuild -project FootprintCapture27/GuidedCaptureSample.xcodeproj \
  -scheme GuidedCaptureSample \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

実機での撮影手順の基になったAppleの資料: [Discover area mode for Object Capture](https://developer.apple.com/wwdc24/10107/)
