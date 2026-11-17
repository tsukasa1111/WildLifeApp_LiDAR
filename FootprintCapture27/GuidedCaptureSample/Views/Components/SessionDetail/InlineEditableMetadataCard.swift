import SwiftUI

struct InlineEditableMetadataCard: View {
    @Binding var traceMetadata: TraceMetadata?
    let onSave: (TraceMetadata) -> Void
    let onCancel: () -> Void

    @State private var hasFootprint: Bool
    @State private var animalType: String
    @State private var otherAnimal: String = ""
    @State private var traceType: String
    @State private var weather: String
    @State private var softness: Int
    @State private var notes: String

    let animalTypes = ["イノシシ", "シカ", "その他"]
    let traceTypes = ["足跡", "糞", "食痕", "爪痕", "その他"]
    let weatherOptions = ["晴れ", "曇り", "雨", "雪", "霧"]
    let softnessOptions = [1,2,3,4,5]

    init(metadata: Binding<TraceMetadata?>, onSave: @escaping (TraceMetadata) -> Void, onCancel: @escaping () -> Void) {
        self._traceMetadata = metadata
        self.onSave = onSave
        self.onCancel = onCancel

        if let m = metadata.wrappedValue {
            self._hasFootprint = State(initialValue: m.hasFootprint)
            self._animalType = State(initialValue: m.animalType)
            self._traceType = State(initialValue: m.traceType)
            self._weather = State(initialValue: m.weather ?? "晴れ")
            if let s = m.substrate, let level = Int(s) { self._softness = State(initialValue: level) } else { self._softness = State(initialValue: 3) }
            self._notes = State(initialValue: m.notes ?? "")
        } else {
            self._hasFootprint = State(initialValue: true)
            self._animalType = State(initialValue: "イノシシ")
            self._traceType = State(initialValue: "足跡")
            self._weather = State(initialValue: "晴れ")
            self._softness = State(initialValue: 3)
            self._notes = State(initialValue: "")
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "square.and.pencil").font(.title2).foregroundColor(.blue)
                    Text("痕跡の詳細情報を入力").font(.headline).fontWeight(.semibold)
                    Spacer()
                }
                Text("発見した動物痕跡の詳細を記録してください").font(.subheadline).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 16) {
                // 足跡有無
                MetadataEditRow(icon: "pawprint.fill", title: "足跡の有無", color: .orange) {
                    HStack(spacing: 20) {
                        Toggle("足跡あり", isOn: $hasFootprint).toggleStyle(.switch)
                    }
                }

                // 動物の種類
                VStack(alignment: .leading, spacing: 8) {
                    Label("動物の種類", systemImage: "hare.fill").font(.subheadline).fontWeight(.medium).foregroundColor(.blue)
                    Picker("動物の種類", selection: $animalType) { ForEach(animalTypes, id: \.self) { Text($0).tag($0) } }
                        .pickerStyle(.segmented)
                    if animalType == "その他" { TextField("動物名を入力してください", text: $otherAnimal).textFieldStyle(.roundedBorder) }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

                // 痕跡の種類
                VStack(alignment: .leading, spacing: 8) {
                    Label("痕跡の種類", systemImage: "pawprint.fill").font(.subheadline).fontWeight(.medium).foregroundColor(.green)
                    Picker("痕跡の種類", selection: $traceType) { ForEach(traceTypes, id: \.self) { Text($0).tag($0) } }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

                // 天候
                VStack(alignment: .leading, spacing: 8) {
                    Label("天候", systemImage: "cloud.sun.fill").font(.subheadline).fontWeight(.medium).foregroundColor(.orange)
                    Picker("天候", selection: $weather) { ForEach(weatherOptions, id: \.self) { Text($0).tag($0) } }
                        .pickerStyle(.segmented)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

                // 地面の柔らかさ
                VStack(alignment: .leading, spacing: 8) {
                    Label("地面の柔らかさ", systemImage: "hand.point.down.fill").font(.subheadline).fontWeight(.medium).foregroundColor(.brown)
                    Picker("地面の柔らかさ", selection: $softness) { ForEach(softnessOptions, id: \.self) { Text("\($0)").tag($0) } }
                        .pickerStyle(.wheel).frame(height: 120)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

                // 備考
                MetadataEditRow(icon: "note.text", title: "備考", color: .gray) {
                    TextEditor(text: $notes).frame(minHeight: 80).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(UIColor.systemGray4)))
                }

                HStack {
                    Button("キャンセル", action: onCancel)
                    Spacer()
                    Button("保存") { onSave(composeMetadata()) }.buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func composeMetadata() -> TraceMetadata {
        let finalAnimal = (animalType == "その他") ? otherAnimal : animalType
        return TraceMetadata(
            hasFootprint: hasFootprint,
            animalType: finalAnimal,
            traceType: traceType,
            weather: weather,
            substrate: String(softness),
            notes: notes.isEmpty ? nil : notes,
            location: traceMetadata?.location,
            timestamp: traceMetadata?.timestamp ?? Date()
        )
    }
}

