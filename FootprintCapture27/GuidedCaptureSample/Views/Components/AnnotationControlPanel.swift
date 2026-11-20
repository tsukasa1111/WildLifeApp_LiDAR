import SwiftUI

struct AnnotationControlPanel: View {
    let annotationCount: Int
    let onClearAll: () -> Void
    @Binding var selectedSize: FootprintScaleSize
    @State private var confirmClear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label {
                    Text("\(annotationCount) / 10").monospacedDigit()
                } icon: {
                    Image(systemName: "pawprint.fill")
                }
                .font(.headline)
                Spacer()
                Button(role: .destructive) { confirmClear = true } label: {
                    Image(systemName: "trash").frame(width: 44, height: 44)
                }
                .accessibilityLabel("すべての印を消す")
                .disabled(annotationCount == 0)
            }
            Text(annotationCount == 10 ? "上限の10個です。印を長押しすると削除できます。" :
                 (annotationCount == 0 ? "写真をタップして、足跡の位置に印を置きます。" :
                    "印をドラッグして位置を調整できます。"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            LabeledContent("追加する印のサイズ") {
                Picker("追加する印のサイズ", selection: $selectedSize) {
                    ForEach(FootprintScaleSize.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 180)
            }
            .font(.subheadline)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(.regularMaterial)
        .alert("すべての印を消しますか？", isPresented: $confirmClear) {
            Button("キャンセル", role: .cancel) {}
            Button("消す", role: .destructive, action: onClearAll)
        } message: {
            Text("保存するまでは元の記録に反映されません。")
        }
    }
}
