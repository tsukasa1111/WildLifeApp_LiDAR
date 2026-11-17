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
    
    // 足跡有無の選択
    @State private var hasFootprint: Bool = true
    
    // 共通項目
    @State private var weather: String = "晴れ"
    @State private var softness: Int = 2
    @State private var notes: String = ""
    
    // 足跡ありの場合のみ必要な項目
    @State private var animalType: String = "イノシシ"
    @State private var otherAnimal: String = ""
    @State private var hasCompletedAnnotation = false
    @State private var showingFootprintAnnotation = false
    @State private var thumbnailImage: UIImage?
    @State private var isLoadingThumbnail = false
    @State private var selectedImageIndex: Int = 2  // 3枚目をデフォルト（0ベース）
    @State private var availableImages: [URL] = []
    @State private var showImageSelector = false
    
    // バリデーション用の状態
    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""
    @State private var isSaving: Bool = false
    
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
    
    // リアルタイムバリデーション
    private var isValidInput: Bool {
        // 足跡ありの場合はアノテーション必須
        if hasFootprint {
            guard hasCompletedAnnotation else { return false }
            
            if animalType == "その他" {
                let trimmedOtherAnimal = otherAnimal.trimmingCharacters(in: .whitespacesAndNewlines)
                return !trimmedOtherAnimal.isEmpty && trimmedOtherAnimal.count <= 20 && notes.count <= 200
            }
        }
        
        // 足跡なしの場合は天候と地面の硬さのみで十分
        return notes.count <= 200
    }
    
    private var validationErrors: [String] {
        var errors: [String] = []
        
        if hasFootprint {
            if !hasCompletedAnnotation {
                errors.append("足跡の位置をマークしてください")
            }
            
            if animalType == "その他" {
                let trimmedOtherAnimal = otherAnimal.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedOtherAnimal.isEmpty {
                    errors.append("動物名を入力してください")
                } else if trimmedOtherAnimal.count > 20 {
                    errors.append("動物名は20文字以内で入力してください")
                }
            }
        }
        
        if notes.count > 200 {
            errors.append("メモは200文字以内で入力してください")
        }
        
        return errors
    }
    
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
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    footprintPresenceSection
                    
                    if hasFootprint {
                        withFootprintSection
                    } else {
                        withoutFootprintSection
                    }
                    
                    commonSection
                    footerSection
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle(hasFootprint ? "🐾 痕跡情報記録" : "📍 調査地点記録")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingFootprintAnnotation) {
            if let image = thumbnailImage {
                if let captureFolderManager = appModel.captureFolderManager {
                    FootprintAnnotationView(
                        captureImage: image,
                        captureFolderManager: captureFolderManager
                    )
                    .onDisappear {
                        checkAnnotationCompletion()
                    }
                } else {
                    Text("キャプチャフォルダが見つかりません")
                        .foregroundColor(.red)
                }
            } else if isLoadingThumbnail {
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
                        loadThumbnailImageSynchronously()
                    }
                    .padding(.top)
                }
                .onAppear {
                    logger.log("Auto-retrying image load...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        loadThumbnailImageSynchronously()
                    }
                }
            }
        }
        .alert("入力エラー", isPresented: $showValidationError) {
            Button("OK") {
                showValidationError = false
            }
        } message: {
            Text(validationMessage)
        }
        .sheet(isPresented: $showImageSelector) {
            ImageSelectorView(
                availableImages: availableImages,
                selectedIndex: $selectedImageIndex,
                onSelectionChanged: { newIndex in
                    selectedImageIndex = newIndex
                    loadThumbnailImage() // 選択が変更されたら画像を再読み込み
                }
            )
        }
        .onAppear {
            logger.log("MetadataInputView appeared")
            
            // 利用可能な画像リストを読み込み
            loadAvailableImages()
            
            // 足跡ありの場合のみ画像を事前読み込み
            if hasFootprint {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    loadThumbnailImage()
                    checkAnnotationCompletion()
                }
            }
        }
        .onChange(of: hasFootprint) { _, newValue in
            if newValue {
                // 足跡ありに変更された場合は画像を読み込み
                loadThumbnailImage()
                checkAnnotationCompletion()
            } else {
                // 足跡なしに変更された場合はアノテーション状態をリセット
                hasCompletedAnnotation = false
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: hasFootprint ? [Color.blue.opacity(0.2), Color.green.opacity(0.1)] : [Color.orange.opacity(0.2), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: hasFootprint ? "pawprint.fill" : "mappin.circle.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: hasFootprint ? [.blue, .green] : [.orange, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text(hasFootprint ? "痕跡の詳細情報" : "調査地点の記録")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(hasFootprint ? "発見した動物痕跡の情報を記録してください" : "動物痕跡が見つからなかった地点の環境情報を記録してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.top, 20)
    }
    
    private var footprintPresenceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                Text("調査結果")
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
                footprintPresenceButton(hasFootprint: true)
                footprintPresenceButton(hasFootprint: false)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func footprintPresenceButton(hasFootprint footprintPresent: Bool) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                hasFootprint = footprintPresent
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(footprintPresent == hasFootprint ? Color.blue.opacity(0.1) : Color(UIColor.systemGray6))
                        .frame(width: 50, height: 50)
                    
                    Text(footprintPresent ? "🐾" : "🔍")
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(footprintPresent ? "足跡あり" : "足跡なし")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(footprintPresent == hasFootprint ? .primary : .secondary)
                    
                    Text(footprintPresent ? "動物の痕跡を発見" : "痕跡は見つからず")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if footprintPresent == hasFootprint {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(footprintPresent == hasFootprint ? Color.blue.opacity(0.05) : Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(footprintPresent == hasFootprint ? Color.blue.opacity(0.3) : Color(UIColor.systemGray4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 足跡ありの場合の詳細入力セクション
    private var withFootprintSection: some View {
        VStack(spacing: 20) {
            animalTypeCard
            if animalType == "その他" {
                otherAnimalCard
            }
            footprintAnnotationCard
        }
    }
    
    // 足跡なしの場合の簡易入力セクション
    private var withoutFootprintSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                        .frame(width: 24, height: 24)
                    
                    Text("簡易記録")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                Text("足跡が見つからなかった地点の環境情報を記録します。動物の種類や詳細なアノテーションは不要です。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
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
        .disabled(isLoadingThumbnail)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private func animalTypeButton(type: (String, String, String)) -> some View {
        Button(action: {
            animalType = type.0
        }) {
            HStack(spacing: 12) {
                Text(type.1)
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(animalType == type.0 ? Color.blue.opacity(0.1) : Color(UIColor.systemGray6))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.0)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(animalType == type.0 ? .primary : .secondary)
                    
                    Text(type.2)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if animalType == type.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(animalType == type.0 ? Color.blue.opacity(0.05) : Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(animalType == type.0 ? Color.blue.opacity(0.3) : Color(UIColor.systemGray4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var otherAnimalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("動物名を入力", systemImage: "pencil")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .trailing, spacing: 4) {
                TextField("動物名を入力してください", text: $otherAnimal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(otherAnimal.count > 20 ? Color.red : Color.clear, lineWidth: 1)
                    )
                
                Text("\(otherAnimal.count)/20")
                    .font(.caption)
                    .foregroundColor(otherAnimal.count > 20 ? .red : .secondary)
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
                
                Text("必須")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(4)
            }
            
            Button(action: {
                openFootprintAnnotation()
            }) {
                HStack {
                    Image(systemName: hasCompletedAnnotation ? "checkmark.circle.fill" : "location.magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(hasCompletedAnnotation ? .green : .orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hasCompletedAnnotation ? "足跡位置設定済み" : "足跡位置を設定")
                            .font(.headline)
                            .foregroundColor(hasCompletedAnnotation ? .green : .primary)
                        
                        Text(hasCompletedAnnotation ? "画像上に足跡がマークされています" : "画像上で足跡の位置をマークしてください")
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
                        .fill(hasCompletedAnnotation ? Color.green.opacity(0.05) : Color(UIColor.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(hasCompletedAnnotation ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoadingThumbnail)
            
            // 画像選択ボタン
            HStack {
                Text("使用する画像:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    showImageSelector = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 14))
                        Text("画像\(selectedImageIndex + 1)を選択")
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
                .disabled(availableImages.isEmpty)
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
            weather = option.0
        }) {
            VStack(spacing: 6) {
                Text(option.1)
                    .font(.system(size: 24))
                
                Text(option.0)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(weather == option.0 ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(weather == option.0 ? Color.blue.opacity(0.1) : Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(weather == option.0 ? Color.blue.opacity(0.5) : Color(UIColor.systemGray4), lineWidth: 1)
                    )
            )
        }
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
            softness = option.0
        }) {
            VStack(spacing: 6) {
                Text(option.1)
                    .font(.system(size: 24))
                
                Text(option.2)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(softness == option.0 ? .brown : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(softness == option.0 ? Color.brown.opacity(0.1) : Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(softness == option.0 ? Color.brown.opacity(0.5) : Color(UIColor.systemGray4), lineWidth: 1)
                    )
            )
        }
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
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(notes.count > 200 ? Color.red : Color(UIColor.systemGray4), lineWidth: 1)
                    )
                
                Text("\(notes.count)/200")
                    .font(.caption)
                    .foregroundColor(notes.count > 200 ? .red : .secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            if !validationErrors.isEmpty {
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
                        ForEach(validationErrors, id: \.self) { error in
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
            
            Button(action: saveMetadata) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(isSaving ? "保存中..." : "保存")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isValidInput ? Color.blue : Color.gray)
                )
            }
            .disabled(!isValidInput || isSaving)
            .buttonStyle(PlainButtonStyle())
            
            Spacer(minLength: 20)
        }
    }
    
    // MARK: - Helper Methods
    
    private func openFootprintAnnotation() {
        guard hasFootprint else { return }
        
        if thumbnailImage == nil {
            loadThumbnailImageSynchronously()
        }
        showingFootprintAnnotation = true
    }
    
    private func loadThumbnailImage() {
        guard let captureFolderManager = appModel.captureFolderManager else {
            logger.error("CaptureFolderManager is nil")
            return
        }
        
        isLoadingThumbnail = true
        
        Task {
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: captureFolderManager.imagesFolder,
                    includingPropertiesForKeys: nil,
                    options: []
                )
                
                let sortedImages = contents
                    .filter({ !$0.hasDirectoryPath })
                    .sorted(by: { $0.path < $1.path })
                
                // 選択されたインデックスの画像を使用
                let selectedImageURL: URL
                if selectedImageIndex < sortedImages.count {
                    selectedImageURL = sortedImages[selectedImageIndex]
                    logger.log("Using selected image \(selectedImageIndex + 1) for annotation: \(selectedImageURL.lastPathComponent)")
                } else if !sortedImages.isEmpty {
                    selectedImageURL = sortedImages.last!  // インデックスが範囲外の場合は最後の画像
                    logger.log("Selected index out of range, using last image: \(selectedImageURL.lastPathComponent)")
                } else {
                    logger.error("No images found in capture folder")
                    await MainActor.run {
                        isLoadingThumbnail = false
                    }
                    return
                }
                
                let imageData = try Data(contentsOf: selectedImageURL)
                guard let uiImage = UIImage(data: imageData) else {
                    logger.error("Failed to create UIImage from data")
                    await MainActor.run {
                        isLoadingThumbnail = false
                    }
                    return
                }
                
                await MainActor.run {
                    thumbnailImage = uiImage
                    isLoadingThumbnail = false
                    logger.log("Successfully loaded thumbnail image")
                }
            } catch {
                logger.error("Failed to load thumbnail image: \(error)")
                await MainActor.run {
                    isLoadingThumbnail = false
                }
            }
        }
    }
    
    private func loadThumbnailImageSynchronously() {
        logger.log("Loading thumbnail image synchronously...")
        loadThumbnailImage()
    }
    
    private func loadAvailableImages() {
        guard let captureFolderManager = appModel.captureFolderManager else { return }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: captureFolderManager.imagesFolder,
                includingPropertiesForKeys: nil,
                options: []
            )
            
            availableImages = contents
                .filter({ !$0.hasDirectoryPath })
                .sorted(by: { $0.path < $1.path })
            
            // 選択されたインデックスが範囲外の場合は調整
            if selectedImageIndex >= availableImages.count && !availableImages.isEmpty {
                selectedImageIndex = availableImages.count - 1
            }
            
            logger.log("Found \(availableImages.count) images, selected index: \(selectedImageIndex)")
        } catch {
            logger.error("Failed to load available images: \(error)")
            availableImages = []
        }
    }
    
    private func checkAnnotationCompletion() {
        guard hasFootprint, let captureFolderManager = appModel.captureFolderManager else {
            hasCompletedAnnotation = false
            return
        }
        
        let annotatedImageURL = captureFolderManager.captureFolder.appendingPathComponent("annotated_footprints.jpg")
        hasCompletedAnnotation = FileManager.default.fileExists(atPath: annotatedImageURL.path)
        
        logger.log("Annotation completion check: \(hasCompletedAnnotation)")
    }
    
    private func saveMetadata() {
        guard !isSaving else { return }
        
        let errors = validationErrors
        if !errors.isEmpty {
            validationMessage = errors.joined(separator: "\n")
            showValidationError = true
            return
        }
        
        isSaving = true
        
        Task {
            do {
                let metadata = TraceMetadata(
                    hasFootprint: hasFootprint,
                    animalType: hasFootprint ? (animalType == "その他" ? otherAnimal : animalType) : "",
                    traceType: hasFootprint ? "足跡" : "調査地点",
                    weather: weather,
                    substrate: softnessOptions.first(where: { $0.0 == softness })?.2,
                    notes: notes.isEmpty ? nil : notes,
                    location: displayLocation,
                    timestamp: Date()
                )
                
                // メタデータを保存
                if let captureFolderManager = appModel.captureFolderManager {
                    let metadataURL = captureFolderManager.captureFolder.appendingPathComponent("metadata.json")
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    let jsonData = try encoder.encode(metadata)
                    try jsonData.write(to: metadataURL)
                    
                    logger.log("📅 Saved metadata with timestamp: \(metadata.timestamp)")
                    logger.log("📁 Saved to: \(metadataURL.path)")
                    
                    logger.log("✅ Metadata saved successfully")
                    
                    await MainActor.run {
                        isSaving = false
                        // 完了画面に遷移
                        appModel.state = .metadataCompleted
                    }
                } else {
                    throw NSError(domain: "MetadataInputView", code: 1, userInfo: [NSLocalizedDescriptionKey: "CaptureFolderManager not found"])
                }
            } catch {
                logger.error("Failed to save metadata: \(error)")
                await MainActor.run {
                    isSaving = false
                    validationMessage = "保存に失敗しました: \(error.localizedDescription)"
                    showValidationError = true
                }
            }
        }
    }
}

// MARK: - LocationInfoRow Component

struct LocationInfoRow: View {
    let location: CLLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("座標", systemImage: "location")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(location.coordinate.latitude, specifier: "%.6f"), \(location.coordinate.longitude, specifier: "%.6f")")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            HStack {
                Label("標高", systemImage: "mountain.2")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(location.altitude, specifier: "%.1f") m")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            HStack {
                Label("精度", systemImage: "target")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("± \(location.horizontalAccuracy, specifier: "%.1f") m")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Image Selector View

struct ImageSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    let availableImages: [URL]
    @Binding var selectedIndex: Int
    let onSelectionChanged: (Int) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(availableImages.enumerated()), id: \.offset) { index, imageURL in
                    HStack {
                        // サムネイル画像
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(8)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.7)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("画像 \(index + 1)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(imageURL.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if index == selectedIndex {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedIndex = index
                        onSelectionChanged(index)
                        dismiss()
                    }
                }
            }
            .navigationTitle("画像を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}
