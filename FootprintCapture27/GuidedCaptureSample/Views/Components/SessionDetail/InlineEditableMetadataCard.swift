import SwiftUI

struct MetadataEditor: View {
    let original: TraceMetadata
    let onSave: (TraceMetadata) throws -> Void
    let onCancel: () -> Void

    @State private var saveError: String?
    @State private var hasFootprint: Bool
    @State private var animalType: String
    @State private var otherAnimal: String = ""
    @State private var traceType: String
    @State private var weather: String
    @State private var substrate: String
    @State private var notes: String

    let animalTypes = ["イノシシ", "シカ", "その他"]
    let traceTypes = ["足跡", "糞", "食痕", "爪痕", "その他", "調査地点"]
    let weatherOptions = ["晴れ", "曇り", "雨", "雪", "霧", "その他"]
    let substrateOptions = ["硬い", "普通", "柔らかい"]

    init(metadata: TraceMetadata, onSave: @escaping (TraceMetadata) throws -> Void, onCancel: @escaping () -> Void) {
        let recognized = ["イノシシ", "シカ"].contains(metadata.animalType)
        original = metadata
        self.onSave = onSave
        self.onCancel = onCancel
        _hasFootprint = State(initialValue: metadata.hasFootprint)
        _animalType = State(initialValue: recognized ? metadata.animalType : "その他")
        _otherAnimal = State(initialValue: recognized ? "" : metadata.animalType)
        _traceType = State(initialValue: metadata.traceType)
        _weather = State(initialValue: metadata.weather ?? "未記録")
        _substrate = State(initialValue: metadata.substrate ?? "未記録")
        _notes = State(initialValue: metadata.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                SwiftUI.Section("調査結果") {
                    Toggle("足跡あり", isOn: $hasFootprint)
                    if hasFootprint {
                        Picker("動物の種類", selection: $animalType) {
                            ForEach(animalTypes, id: \.self) { Text($0) }
                        }
                        if animalType == "その他" {
                            TextField("動物名", text: $otherAnimal)
                        }
                        Picker("痕跡の種類", selection: $traceType) {
                            options(traceTypes, including: traceType)
                        }
                    }
                }
                SwiftUI.Section("環境") {
                    Picker("天候", selection: $weather) {
                        options(["未記録"] + weatherOptions, including: weather)
                    }
                    Picker("地面の柔らかさ", selection: $substrate) {
                        options(["未記録"] + substrateOptions, including: substrate)
                    }
                }
                SwiftUI.Section("メモ") {
                    TextField("観察したこと", text: $notes, axis: .vertical)
                        .lineLimit(2...8)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("記録の編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        do { try onSave(composeMetadata()) }
                        catch { saveError = error.localizedDescription }
                    }
                    .disabled(hasFootprint && animalType == "その他" && otherAnimal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("詳細情報を保存できませんでした", isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: { Text(saveError ?? "") }
            .onChange(of: hasFootprint) { _, present in
                traceType = present ? "足跡" : "調査地点"
            }
        }
    }

    private func options(_ values: [String], including current: String) -> some View {
        ForEach(values.contains(current) ? values : values + [current], id: \.self) { Text($0) }
    }

    private func composeMetadata() -> TraceMetadata {
        let finalAnimal = hasFootprint ? ((animalType == "その他") ? otherAnimal.trimmingCharacters(in: .whitespacesAndNewlines) : animalType) : ""
        return TraceMetadata(
            hasFootprint: hasFootprint,
            animalType: finalAnimal,
            traceType: hasFootprint ? traceType : "調査地点",
            weather: weather == "未記録" ? nil : weather,
            substrate: substrate == "未記録" ? nil : substrate,
            notes: notes.isEmpty ? nil : notes,
            location: original.location,
            timestamp: original.timestamp,
            id: original.id
        )
    }
}

