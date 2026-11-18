import SwiftUI

struct GalleryStandaloneView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            GC_GalleryView()
                .navigationTitle("キャプチャ一覧")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("閉じる") { dismiss() }
                    }
                }
        }
    }
}
