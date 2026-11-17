import SwiftUI

struct GC_CustomConfirmationDialog: View {
    let selectedIndex: Int
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 8) {
                    Text("足跡スタンプを編集")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("画像 \(selectedIndex + 1) に足跡スタンプを追加しますか？")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            HStack(spacing: 12) {
                Button("キャンセル") { onCancel() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                
                Button("編集する") { onConfirm(selectedIndex) }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}
