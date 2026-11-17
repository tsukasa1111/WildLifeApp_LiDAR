import SwiftUI

struct GalleryStandaloneView: View {
    @EnvironmentObject var appModel: AppDataModel
    @Environment(\.dismiss) private var dismiss
    @State private var show: Bool = true

    var body: some View {
        NavigationView {
            GC_GalleryView(showCaptureFolders: $show)
                .navigationTitle("キャプチャ一覧")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("閉じる") { dismiss(); appModel.showReadOnlyGallery = false }
                    }
                }
        }
        .onChange(of: show) { _, newVal in
            if newVal == false { appModel.showReadOnlyGallery = false }
        }
    }
}
