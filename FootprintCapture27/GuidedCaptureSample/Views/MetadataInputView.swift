/*
Metadata Input View
動物痕跡の詳細情報入力画面 - 足跡有無対応版
*/

import SwiftUI
import CoreLocation
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "MetadataInputView")

struct MetadataInputView: View {
    @EnvironmentObject var appModel: AppDataModel
    @StateObject private var viewModel = MetadataInputViewModel()
    
    let animalTypes = [
        ("イノシシ", "🐗", "Sus scrofa"),
        ("シカ", "🦌", "Cervus nippon"),
        ("その他", "🐾", "不明な動物")
    ]
    let weatherOptions = [
        ("晴れ", "☀️", "sun.max.fill"),
        ("曇り", "☁️", "cloud.fill"),
        ("雨", "🌧️", "cloud.rain.fill"),
        ("雪", "❄️", "cloud.snow.fill"),
        ("霧", "🌫️", "cloud.fog.fill"),
        ("その他", "❓", "questionmark.circle.fill")
    ]
    let softnessOptions = [
        (1, "🪨", "硬い"),
        (2, "🟤", "普通"),
        (3, "🤎", "柔らかい")
    ]
    
    // 位置情報表示用のcomputed properties
    private var hasValidLocation: Bool {
        return appModel.currentLocation != nil || appModel.scanStartLocation != nil
    }
    
    private var displayLocation: CLLocation? {
        return appModel.scanStartLocation ?? appModel.currentLocation
    }
    
    private var locationIcon: String {
        return hasValidLocation ? "location.fill" : "location.slash.fill"
    }
    
    private var locationIconColor: Color {
        return hasValidLocation ? .green : .orange
    }
    
    private var locationStatusIcon: String {
        return hasValidLocation ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }
    
    private var locationStatusColor: Color {
        return hasValidLocation ? .green : .orange
    }
    
    private var locationBorderColor: Color {
        return hasValidLocation ? .green.opacity(0.3) : .orange.opacity(0.3)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    footprintPresenceSection
                    
                    if viewModel.hasFootprint {
                        withFootprintSection
                    }
                    
                    commonSection
                    validationSection
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(viewModel.hasFootprint ? "痕跡の記録" : "調査地点の記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isSaving ? "保存中…" : "保存") {
                        Task { await saveWithViewModel() }
                    }
                    .disabled(!viewModel.isValidInput || viewModel.isSaving)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingFootprintAnnotation) {
            if let image = viewModel.thumbnailImage {
                if let captureFolderManager = appModel.captureFolderManager {
                    FootprintAnnotationView(
                        captureImage: image,
                        captureFolderManager: captureFolderManager,
                        sourceImageName: viewModel.availableImages.indices.contains(viewModel.selectedImageIndex)
                            ? viewModel.availableImages[viewModel.selectedImageIndex].lastPathComponent : nil,
                        legacySourceImageName: viewModel.availableImages.prefix(3).last?.lastPathComponent
                    )
                    .onDisappear {
                        viewModel.checkAnnotationCompletion(appModel: appModel)
                    }
                } else {
                    Text("キャプチャフォルダが見つかりません")
                        .foregroundColor(.red)
                }
            } else if viewModel.isLoadingThumbnail {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("画像を読み込んでいます...")
                        .padding(.top)
                }
            } else {
                VStack {
                    Text("画像の読み込みに失敗しました")
                        .foregroundColor(.red)
                    Button("再試行") {
                        viewModel.loadThumbnailImageSynchronously(appModel: appModel)
                    }
                    .padding(.top)
                }
                .onAppear {
                    logger.log("Auto-retrying image load...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.loadThumbnailImageSynchronously(appModel: appModel)
                    }
                }
            }
        }
        .alert("入力エラー", isPresented: $viewModel.showValidationError) {
            Button("OK") {
                viewModel.showValidationError = false
            }
        } message: {
            Text(viewModel.validationMessage)
        }
        .sheet(isPresented: $viewModel.showImageSelector) {
            ImageSelectorView(
                availableImages: viewModel.availableImages,
                selectedIndex: $viewModel.selectedImageIndex,
                onSelectionChanged: { newIndex in
                    viewModel.selectedImageIndex = newIndex
                    viewModel.loadThumbnailImage(appModel: appModel) // 選択が変更されたら画像を再読み込み
                }
            )
        }
        .onAppear {
            logger.log("MetadataInputView appeared")
            
            // 利用可能な画像リストを読み込み
            viewModel.loadAvailableImages(appModel: appModel)
            
            // 足跡ありの場合のみ画像を事前読み込み
            if viewModel.hasFootprint {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.loadThumbnailImage(appModel: appModel)
                    viewModel.checkAnnotationCompletion(appModel: appModel)
                }
            }
        }
        .onChange(of: viewModel.hasFootprint) { _, newValue in
            if newValue {
                // 足跡ありに変更された場合は画像を読み込み
                viewModel.loadThumbnailImage(appModel: appModel)
                viewModel.checkAnnotationCompletion(appModel: appModel)
            } else {
                // 足跡なしに変更された場合はアノテーション状態をリセット
                viewModel.hasCompletedAnnotation = false
            }
        }
    }
    
    // MARK: - View Components
    
    private var footprintPresenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("調査結果", systemImage: "pawprint.fill")
                .font(.headline)
            Picker("調査結果", selection: $viewModel.hasFootprint) {
                Text("足跡あり").tag(true)
                Text("足跡なし").tag(false)
            }
            .pickerStyle(.segmented)
        }
    }

    // 足跡ありの場合の詳細入力セクション
    private var withFootprintSection: some View {
        VStack(spacing: 20) {
            animalTypeCard
            if viewModel.animalType == "その他" {
                otherAnimalCard
            }
            footprintAnnotationCard
        }
    }
    
    // 共通入力セクション（天候・地面の硬さ・位置情報・メモ）
    private var commonSection: some View {
        VStack(spacing: 20) {
            weatherCard
            softnessCard
            locationCard
            notesCard
        }
    }
    
    private var animalTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hare.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
                    .frame(width: 24, height: 24)
                
                Text("動物の種類")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("必須")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .cornerRadius(4)
            }
            
            VStack(spacing: 12) {
                ForEach(animalTypes, id: \.0) { type in
                    animalTypeButton(type: type)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private func animalTypeButton(type: (String, String, String)) -> some View {
        Button(action: {
            viewModel.animalType = type.0
        }) {
            HStack(spacing: 12) {
                Text(type.1)
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(viewModel.animalType == type.0 ? Color.blue.opacity(0.1) : Color(UIColor.systemGray6))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.0)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.animalType == type.0 ? .primary : .secondary)
                    
                    Text(type.2)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if viewModel.animalType == type.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.animalType == type.0 ? Color.blue.opacity(0.05) : Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.animalType == type.0 ? Color.blue.opacity(0.3) : Color(UIColor.systemGray4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityAddTraits(viewModel.animalType == type.0 ? .isSelected : [])
    }
    
    private var otherAnimalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("動物名を入力", systemImage: "pencil")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .trailing, spacing: 4) {
                TextField("動物名を入力してください", text: $viewModel.otherAnimal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(viewModel.otherAnimal.count > 20 ? Color.red : Color.clear, lineWidth: 1)
                    )
                
                if viewModel.otherAnimal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("動物名を入力してください").font(.caption).foregroundStyle(.secondary)
                }
                Text("\(viewModel.otherAnimal.count)/20")
                    .font(.caption)
                    .foregroundColor(viewModel.otherAnimal.count > 20 ? .red : .secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var footprintAnnotationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
                    .frame(width: 24, height: 24)
                
                Text("足跡の位置")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("任意")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray)
                    .cornerRadius(4)
            }
            
            Button(action: {
                viewModel.openFootprintAnnotation()
            }) {
                HStack {
                    Image(systemName: viewModel.hasCompletedAnnotation ? "checkmark.circle.fill" : "location.magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.hasCompletedAnnotation ? .green : .blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.hasCompletedAnnotation ? "足跡位置設定済み" : "必要に応じて足跡位置を設定")
                            .font(.headline)
                            .foregroundColor(viewModel.hasCompletedAnnotation ? .green : .primary)
                        
                        Text(viewModel.hasCompletedAnnotation ? "画像上に足跡がマークされています" : "保存は位置マークなしでも可能です")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.hasCompletedAnnotation ? Color.green.opacity(0.05) : Color(UIColor.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.hasCompletedAnnotation ? Color.green.opacity(0.3) : Color.blue.opacity(0.2), lineWidth: 1)
                            )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isLoadingThumbnail || viewModel.availableImages.isEmpty)

            if viewModel.availableImages.isEmpty {
                Text("撮影画像がないため、足跡位置を設定できません")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 画像選択ボタン
            HStack {
                Text("マーキングする画像")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    viewModel.showImageSelector = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 14))
                        Text(viewModel.availableImages.isEmpty ? "画像なし" : "画像 \(viewModel.selectedImageIndex + 1) / \(viewModel.availableImages.count)")
                            .font(.subheadline)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .disabled(viewModel.availableImages.isEmpty)
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                Text("天候")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(weatherOptions, id: \.0) { option in
                    weatherButton(option: option)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private func weatherButton(option: (String, String, String)) -> some View {
        Button(action: {
            viewModel.weather = option.0
        }) {
            VStack(spacing: 6) {
                Text(option.1)
                    .font(.system(size: 24))
                
                Text(option.0)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.weather == option.0 ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(viewModel.weather == option.0 ? Color.blue.opacity(0.1) : Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(viewModel.weather == option.0 ? Color.blue.opacity(0.5) : Color(UIColor.systemGray4), lineWidth: 1)
                    )
            )
        }
        .overlay(alignment: .topTrailing) {
            if viewModel.weather == option.0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.tint)
                    .padding(4)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityAddTraits(viewModel.weather == option.0 ? .isSelected : [])
        .buttonStyle(PlainButtonStyle())
    }
    
    private var softnessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.brown)
                    .frame(width: 24, height: 24)
                
                Text("地面の硬さ")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                ForEach(softnessOptions, id: \.0) { option in
                    softnessButton(option: option)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private func softnessButton(option: (Int, String, String)) -> some View {
        Button(action: {
            viewModel.softness = option.0
        }) {
            VStack(spacing: 6) {
                Text(option.1)
                    .font(.system(size: 24))
                
                Text(option.2)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.softness == option.0 ? .brown : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(viewModel.softness == option.0 ? Color.brown.opacity(0.1) : Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(viewModel.softness == option.0 ? Color.brown.opacity(0.5) : Color(UIColor.systemGray4), lineWidth: 1)
                    )
            )
        }
        .overlay(alignment: .topTrailing) {
            if viewModel.softness == option.0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.tint)
                    .padding(4)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityAddTraits(viewModel.softness == option.0 ? .isSelected : [])
        .buttonStyle(PlainButtonStyle())
    }
    
    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: locationIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(locationIconColor)
                    .frame(width: 24, height: 24)
                
                Text("位置情報")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: locationStatusIcon)
                        .font(.system(size: 12))
                        .foregroundColor(locationStatusColor)
                    
                    Text(hasValidLocation ? "取得済み" : "未取得")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(locationStatusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(locationStatusColor.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            if let location = displayLocation {
                LocationInfoRow(location: location)
            } else {
                HStack {
                    Image(systemName: "location.slash")
                        .foregroundColor(.secondary)
                    
                    Text("位置情報が記録されていません")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(locationBorderColor, lineWidth: 1)
                )
        )
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                
                Text("メモ")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("任意")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray)
                    .cornerRadius(4)
            }
            
            VStack(alignment: .trailing, spacing: 4) {
                TextEditor(text: $viewModel.notes)
                    .accessibilityLabel("メモ")
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.notes.count > 200 ? Color.red : Color(UIColor.systemGray4), lineWidth: 1)
                    )
                
                Text("\(viewModel.notes.count)/200")
                    .font(.caption)
                    .foregroundColor(viewModel.notes.count > 200 ? .red : .secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private var validationSection: some View {
        VStack(spacing: 16) {
            if !viewModel.validationErrors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                        
                        Text("入力内容を確認してください")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.validationErrors, id: \.self) { error in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            

        }
    }
    
    // MARK: - Helper Methods
    
    private func saveWithViewModel() async {
        await viewModel.saveMetadata(appModel: appModel)
    }

}

// moved: LocationInfoRow and ImageSelectorView are split into Views/Components.
