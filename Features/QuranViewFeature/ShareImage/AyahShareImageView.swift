//
//  AyahShareImageView.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import AVFoundation
import Localization
import SwiftUI
import UIx

public struct AyahShareImageView: View {
    @ObservedObject var viewModel: AyahShareImageViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingRemoteGallery = false
    @State private var hostViewController: UIViewController?
    let onDismiss: () -> Void

    public init(viewModel: AyahShareImageViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    private var activeTextColorScheme: AyahCardTextColorScheme {
        viewModel.colorTarget == .arabic ? viewModel.textColorScheme : viewModel.translationTextColorScheme
    }

    public var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    mainContent
                }
            } else {
                NavigationView {
                    mainContent
                }
                .navigationViewStyle(.stack)
            }
        }
        .background(UIViewControllerReader(viewController: $hostViewController))
    }

    private var mainContent: some View {
        ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                } else if let cardData = viewModel.displayedCardData ?? viewModel.cardData {
                    if horizontalSizeClass == .regular {
                        HStack(spacing: 0) {
                            pinnedPreview(cardData: cardData)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(UIColor.systemGroupedBackground))

                            Divider()

                            controlsScrollView
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        GeometryReader { outerGeo in
                            let previewHeight = min(max(outerGeo.size.height * 0.42, 240), 340)
                            VStack(spacing: 0) {
                                pinnedPreview(cardData: cardData)
                                    .frame(height: previewHeight)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(UIColor.systemGroupedBackground))

                                Divider()

                                controlsScrollView
                            }
                        }
                    }
                }
                // Toast Banner
                if let toast = viewModel.saveSuccessToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(toast)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.85))
                        )
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(), value: toast)
                }
            }
            .navigationTitle(
                viewModel.isVideoMode
                    ? lChoice(kn: "ವೀಡಿಯೊ ಹಂಚಿಕೆ", en: "Share Ayah Video", ar: "مشاركة فيديو الآية")
                    : lChoice(kn: "ಚಿತ್ರ ಹಂಚಿಕೆ", en: "Share Ayah", ar: "مشاركة الآية")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.stopAudioPreview()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
            .onDisappear {
                viewModel.stopAudioPreview()
            }
            .sheet(isPresented: $showingRemoteGallery) {
                RemoteBackgroundPickerView(viewModel: viewModel, isPresented: $showingRemoteGallery)
            }
            .alert(isPresented: Binding(
                get: { viewModel.errorAlertMessage != nil },
                set: { if !$0 { viewModel.errorAlertMessage = nil } }
            )) {
                Alert(
                    title: Text(lChoice(kn: "ದೋಷ", en: "Notice", ar: "تنبيه")),
                    message: Text(viewModel.errorAlertMessage ?? ""),
                    dismissButton: .default(Text(lChoice(kn: "ಸರಿ", en: "OK", ar: "حسناً")))
                )
            }
            .onChange(of: viewModel.customBackgroundImage) { newImage in
                if newImage != nil {
                    withAnimation {
                        viewModel.selectedTheme = .customPhoto
                        if viewModel.backgroundMode != 1 {
                            viewModel.backgroundMode = 1
                        }
                    }
                }
            }
    }

    @ViewBuilder
    private func pinnedPreview(cardData: AyahCardData) -> some View {
        GeometryReader { geo in
            let baseSize = CGSize(
                width: 330,
                height: viewModel.selectedAspectRatio.height(for: 330)
            )
            let availW = max(1, geo.size.width - 28)
            let availH = max(1, geo.size.height - 20)
            let fitScale = min(availW / baseSize.width, availH / baseSize.height, 1.15)
            let slideCount = viewModel.cardData?.ayahSlides.count ?? cardData.ayahSlides.count

            ZStack {
                if viewModel.isLiveVideoBackground {
                    Group {
                        if let videoURL = viewModel.selectedBackgroundVideoURL {
                            LoopingVideoPlayerView(url: videoURL, scale: viewModel.photoScale)
                        } else {
                            ZStack {
                                Color.black
                                if viewModel.isDownloadingBackgroundVideo {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                        }
                    }
                    .frame(width: baseSize.width, height: baseSize.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                }

                AyahShareCardView(
                    data: cardData,
                    theme: viewModel.selectedTheme,
                    aspectRatio: viewModel.selectedAspectRatio,
                    showArabic: viewModel.showArabic,
                    showTranslation: viewModel.showTranslation,
                    showFootnotes: viewModel.showFootnotes,
                    showQRCode: viewModel.showQRCode,
                    showAppURL: viewModel.showAppURL,
                    fontSizeScale: viewModel.fontSizeScale,
                    textColorScheme: viewModel.textColorScheme,
                    customTextColor: viewModel.textColorScheme == .custom ? viewModel.customTextColor : nil,
                    translationTextColorScheme: viewModel.translationTextColorScheme,
                    customTranslationTextColor: viewModel.translationTextColorScheme == .custom ? viewModel.customTranslationTextColor : nil,
                    arabicFont: viewModel.arabicFont,
                    translationFont: viewModel.translationFont,
                    photoScale: viewModel.photoScale,
                    customImage: viewModel.customBackgroundImage,
                    transparentBackground: viewModel.isLiveVideoBackground,
                    isExport: false
                )
                .frame(width: baseSize.width, height: baseSize.height)

                if viewModel.backgroundMode == 1 && viewModel.isDownloadingBackgroundPhoto {
                    ZStack {
                        RoundedRectangle(cornerRadius: 0, style: .continuous)
                            .fill(Color.black.opacity(0.35))
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    .frame(width: baseSize.width, height: baseSize.height)
                    .allowsHitTesting(false)
                }

                if viewModel.isVideoMode {
                    // Top-right badge: MP4 (+ multi-ayah slide index when synced)
                    HStack(spacing: 4) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 9.5, weight: .bold))
                        if viewModel.syncAyahWithAudio && slideCount > 1 {
                            Text("\(viewModel.activePreviewSlideIndex + 1)/\(slideCount) · MP4")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        } else {
                            Text("MP4")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.65)))
                    .padding(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .allowsHitTesting(false)

                    // Bottom-center Play/Stop reciter preview button (sits above permanent Store+QR footer)
                    Button {
                        viewModel.toggleAudioPreview()
                    } label: {
                        HStack(spacing: 6) {
                            if viewModel.isLoadingAudioPreview {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.75)
                            } else {
                                Image(systemName: viewModel.isPlayingAudioPreview ? "stop.fill" : "play.fill")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            Text(
                                viewModel.isPlayingAudioPreview
                                    ? lChoice(kn: "ನಿಲ್ಲಿಸಿ", en: "Stop Preview", ar: "إيقاف المعاينة")
                                    : lChoice(kn: "ಪಠಣ ಕೇಳಿ", en: "Preview Recitation", ar: "معاينة التلاوة")
                            )
                            .font(.system(size: 11.5, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.72))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.28), lineWidth: 1)
                        )
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 58)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(width: baseSize.width, height: baseSize.height)
            .scaleEffect(fitScale)
            .frame(width: baseSize.width * fitScale, height: baseSize.height * fitScale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }


    private var controlsScrollView: some View {
        ScrollView {
            VStack(spacing: 18) {
                            if let progress = viewModel.exportProgress {
                                VStack(spacing: 8) {
                                    HStack(spacing: 10) {
                                        ProgressView()
                                        Text(progress.message)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if let pct = progress.percent {
                                            Text("\(pct)%")
                                                .font(.system(size: 12.5, weight: .semibold, design: .monospaced))
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    if let pct = progress.percent {
                                        ProgressView(value: Double(min(max(pct, 0), 100)), total: 100.0)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .padding(.horizontal, 16)
                            }

                            if viewModel.isVideoMode {
                                VStack(spacing: 10) {
                                    // Reciter Selector
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            HStack(spacing: 6) {
                                                Image(systemName: "waveform")
                                                    .font(.system(size: 13.5))
                                                    .foregroundColor(.secondary)
                                                Text(lChoice(kn: "ಪಠಣಕಾರರು (ಖಾರಿ)", en: "Reciter (Qari)", ar: "القارئ"))
                                                    .font(.system(size: 13.5, weight: .medium))
                                            }
                                            Spacer()
                                            if let reciterName = viewModel.selectedReciterName {
                                                Text(reciterName)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }

                                        if viewModel.availableReciters.isEmpty {
                                            Text(lChoice(kn: "ಪಠಣಕಾರರನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...", en: "Loading reciters...", ar: "جارٍ تحميل القرّاء..."))
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        } else {
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 8) {
                                                    ForEach(viewModel.availableReciters) { reciter in
                                                        let isSelected = viewModel.selectedReciterId == reciter.id
                                                        Button {
                                                            if viewModel.selectedReciterId != reciter.id {
                                                                viewModel.stopAudioPreview()
                                                                viewModel.selectedReciterId = reciter.id
                                                            }
                                                        } label: {
                                                            HStack(spacing: 5) {
                                                                if isSelected {
                                                                    Image(systemName: "checkmark.circle.fill")
                                                                        .font(.system(size: 11))
                                                                }
                                                                Text(reciter.name)
                                                                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                                                                    .lineLimit(1)
                                                            }
                                                            .padding(.horizontal, 12)
                                                            .padding(.vertical, 7)
                                                            .background(
                                                                Capsule()
                                                                    .fill(isSelected ? Color.accentColor : Color(UIColor.tertiarySystemGroupedBackground))
                                                            )
                                                            .foregroundColor(isSelected ? .white : .primary)
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                }
                                                .padding(.vertical, 2)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(12)

                                    if (viewModel.cardData?.ayahSlides.count ?? 0) > 1 {
                                        Toggle(
                                            lChoice(
                                                kn: "ಪಠಣದೊಂದಿಗೆ ಪ್ರತಿ ಆಯತ್ ಬದಲಿಸಿ",
                                                en: "Sync Per-Ayah Card with Recitation",
                                                ar: "مزامنة البطاقة مع تلاوة كل آية"
                                            ),
                                            isOn: $viewModel.syncAyahWithAudio
                                        )
                                        .font(.system(size: 13.5, weight: .medium))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .cornerRadius(12)
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(lChoice(kn: "ವೀಡಿಯೊ ಗುಣಮಟ್ಟ", en: "Video Quality", ar: "جودة الفيديو"))
                                            .font(.system(size: 12.5, weight: .semibold))
                                            .foregroundColor(.secondary)

                                        Picker("", selection: $viewModel.videoExportQuality) {
                                            ForEach(AyahVideoExportQuality.allCases) { quality in
                                                Text(quality.displayName).tag(quality)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal, 16)
                            }

                            HStack(spacing: 8) {
                                ForEach(AyahCardAspectRatio.allCases) { ratio in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.selectedAspectRatio = ratio
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: ratio == .square ? "square" : (ratio == .portrait ? "rectangle.portrait" : "iphone"))
                                                .font(.system(size: 11, weight: .semibold))
                                            Text(ratio.displayName)
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(viewModel.selectedAspectRatio == ratio ? Color.accentColor : Color(UIColor.secondarySystemGroupedBackground))
                                        )
                                        .foregroundColor(viewModel.selectedAspectRatio == ratio ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)

                            // Background Mode Picker: Colors vs Photos (and Videos in Video Mode)
                            VStack(spacing: 12) {
                                Picker("", selection: $viewModel.backgroundMode) {
                                    Text(lChoice(kn: "ಬಣ್ಣಗಳು", en: "Colors", ar: "ألوان")).tag(0)
                                    Text(lChoice(kn: "ಫೋಟೋಗಳು", en: "Photos", ar: "صور")).tag(1)
                                    if viewModel.isVideoMode {
                                        Text(lChoice(kn: "ವೀಡಿಯೊಗಳು", en: "Videos", ar: "فيديوهات")).tag(2)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, 16)
                                .onChange(of: viewModel.backgroundMode) { newMode in
                                    viewModel.onBackgroundModeChanged(newMode)
                                }

                                if viewModel.backgroundMode == 0 {
                                    // Color Swatches (7 Colors)
                                    HStack(spacing: 10) {
                                        Spacer(minLength: 0)
                                        ForEach(AyahCardTheme.colorThemes) { theme in
                                            ZStack {
                                                Circle()
                                                    .fill(theme.iconColor)
                                                    .frame(width: 32, height: 32)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                                    )

                                                if viewModel.selectedTheme == theme {
                                                    Circle()
                                                        .stroke(Color.accentColor, lineWidth: 2.5)
                                                        .frame(width: 40, height: 40)

                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(theme == .minimal || theme == .parchment ? .black : .white)
                                                }
                                            }
                                            .frame(width: 42, height: 42)
                                            .contentShape(Circle())
                                            .onTapGesture {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    viewModel.selectedTheme = theme
                                                }
                                            }
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 16)
                                } else if viewModel.backgroundMode == 1 {
                                    CloudBackgroundSwatchesRow(
                                        items: viewModel.inlinePhotoCatalogItems,
                                        selectedId: viewModel.selectedRemotePhotoItem?.id,
                                        fallbackSystemImage: "photo",
                                        browseTitle: lChoice(
                                            kn: "ಕ್ಲೌಡ್ ಫೋಟೋಗಳನ್ನು ನೋಡಿ",
                                            en: "Browse Cloud Photos",
                                            ar: "تصفح صور السحابة"
                                        ),
                                        isDownloaded: { viewModel.isPhotoDownloaded($0) },
                                        onBrowseMore: { showingRemoteGallery = true },
                                        onSelectItem: { item in
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                viewModel.selectRemotePhoto(item)
                                            }
                                        }
                                    )

                                    if viewModel.customBackgroundImage != nil {
                                        BackgroundZoomControl(
                                            label: lChoice(kn: "ಫೋಟೋ ಜೂಮ್", en: "Photo Zoom", ar: "تكبير الصورة"),
                                            scale: $viewModel.photoScale
                                        )
                                    }
                                } else if viewModel.isVideoMode {
                                    CloudBackgroundSwatchesRow(
                                        items: viewModel.inlineVideoCatalogItems,
                                        selectedId: viewModel.selectedRemoteVideoItem?.id,
                                        fallbackSystemImage: "video.fill",
                                        browseTitle: lChoice(
                                            kn: "ಕ್ಲೌಡ್ ವೀಡಿಯೊಗಳನ್ನು ನೋಡಿ",
                                            en: "Browse Cloud Videos",
                                            ar: "تصفح فيديوهات السحابة"
                                        ),
                                        isDownloaded: { viewModel.isVideoDownloaded($0) },
                                        onBrowseMore: { showingRemoteGallery = true },
                                        onSelectItem: { item in
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                viewModel.selectRemoteVideo(item)
                                            }
                                        }
                                    )

                                    if viewModel.isLiveVideoBackground {
                                        BackgroundZoomControl(
                                            label: lChoice(kn: "ವೀಡಿಯೊ ಜೂಮ್", en: "Video Zoom", ar: "تكبير الفيديو"),
                                            scale: $viewModel.photoScale
                                        )
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)

                            // Text Size Stepper (50% to 200%)
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "textformat.size")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                    Text(lChoice(kn: "ಪಠ್ಯದ ಗಾತ್ರ", en: "Text Size", ar: "حجم النص"))
                                        .font(.system(size: 14, weight: .medium))
                                }

                                Spacer()

                                HStack(spacing: 12) {
                                    Button {
                                        if viewModel.fontSizeScale > 0.25 {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                viewModel.fontSizeScale = max(0.2, (viewModel.fontSizeScale * 10 - 1).rounded() / 10)
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "minus")
                                            .font(.system(size: 13, weight: .bold))
                                            .frame(width: 32, height: 32)
                                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                    .contentShape(Rectangle())

                                    Text("\(Int(round(viewModel.fontSizeScale * 100)))%")
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                        .frame(width: 44)

                                    Button {
                                        if viewModel.fontSizeScale < 1.95 {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                viewModel.fontSizeScale = min(2.0, (viewModel.fontSizeScale * 10 + 1).rounded() / 10)
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 13, weight: .bold))
                                            .frame(width: 32, height: 32)
                                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                    .contentShape(Rectangle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)

                            // Font Style Selector (Uthmanic, Kitab, Geeza Pro vs Noto Serif, Noto Sans, Baloo, Anek)
                            VStack(spacing: 8) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "textformat")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                        Text(lChoice(kn: "ಫಾಂಟ್ ಶೈಲಿ", en: "Font Style", ar: "نمط الخط"))
                                            .font(.system(size: 14, weight: .medium))
                                    }

                                    Spacer()

                                    Text(viewModel.colorTarget == .arabic ? viewModel.arabicFont.displayName : viewModel.translationFont.displayName)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        if viewModel.colorTarget == .arabic {
                                            ForEach(AyahCardArabicFont.allCases) { fontOption in
                                                Button {
                                                    withAnimation(.easeInOut(duration: 0.15)) {
                                                        viewModel.arabicFont = fontOption
                                                    }
                                                } label: {
                                                    Text(fontOption.displayName)
                                                        .font(.system(size: 12.5, weight: viewModel.arabicFont == fontOption ? .semibold : .regular))
                                                        .padding(.horizontal, 14)
                                                        .padding(.vertical, 7)
                                                        .background(
                                                            Capsule()
                                                                .fill(viewModel.arabicFont == fontOption ? Color.accentColor : Color(UIColor.tertiarySystemGroupedBackground))
                                                        )
                                                        .foregroundColor(viewModel.arabicFont == fontOption ? .white : .primary)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        } else {
                                            ForEach(AyahCardTranslationFont.allCases) { fontOption in
                                                Button {
                                                    withAnimation(.easeInOut(duration: 0.15)) {
                                                        viewModel.translationFont = fontOption
                                                    }
                                                } label: {
                                                    Text(fontOption.displayName)
                                                        .font(.system(size: 12.5, weight: viewModel.translationFont == fontOption ? .semibold : .regular))
                                                        .padding(.horizontal, 14)
                                                        .padding(.vertical, 7)
                                                        .background(
                                                            Capsule()
                                                                .fill(viewModel.translationFont == fontOption ? Color.accentColor : Color(UIColor.tertiarySystemGroupedBackground))
                                                        )
                                                        .foregroundColor(viewModel.translationFont == fontOption ? .white : .primary)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 3)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)

                            // Text Color Scheme Selector (Option B: Arabic vs Translation Segmented Controls)
                            VStack(spacing: 10) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "paintpalette")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                        Text(lChoice(kn: "ಪಠ್ಯದ ಬಣ್ಣ", en: "Text Color", ar: "لون النص"))
                                            .font(.system(size: 14, weight: .medium))
                                    }

                                    Spacer()

                                    if viewModel.textColorScheme != .themeDefault || viewModel.translationTextColorScheme != .themeDefault {
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                viewModel.textColorScheme = .themeDefault
                                                viewModel.translationTextColorScheme = .themeDefault
                                            }
                                        } label: {
                                            HStack(spacing: 3) {
                                                Image(systemName: "arrow.counterclockwise")
                                                    .font(.system(size: 10, weight: .semibold))
                                                Text(lChoice(kn: "ಮರುಹೊಂದಿಸಿ", en: "Reset", ar: "إعادة ضبط"))
                                                    .font(.system(size: 11, weight: .semibold))
                                            }
                                            .foregroundColor(.accentColor)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(
                                                Capsule()
                                                    .fill(Color.accentColor.opacity(0.12))
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(activeTextColorScheme == .custom ? (viewModel.colorTarget == .arabic ? viewModel.customTextColor : viewModel.customTranslationTextColor) : activeTextColorScheme.previewColor)
                                            .frame(width: 9, height: 9)
                                            .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 0.5))

                                        Text(activeTextColorScheme.displayName)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }

                                // Segmented target picker: Arabic vs Translation
                                Picker("", selection: $viewModel.colorTarget) {
                                    Text(lChoice(kn: "ಅರೇಬಿಕ್", en: "Arabic", ar: "العربية")).tag(AyahCardTextColorTarget.arabic)
                                    Text(lChoice(kn: "ಅನುವಾದ", en: "Translation", ar: "الترجمة")).tag(AyahCardTextColorTarget.translation)
                                }
                                .pickerStyle(.segmented)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        // 1. Curated 8 presets
                                        ForEach(AyahCardTextColorScheme.presets) { scheme in
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    if viewModel.colorTarget == .arabic {
                                                        viewModel.textColorScheme = scheme
                                                    } else {
                                                        viewModel.translationTextColorScheme = scheme
                                                    }
                                                }
                                            } label: {
                                                ZStack {
                                                    Circle()
                                                        .fill(scheme.previewColor)
                                                        .frame(width: 26, height: 26)
                                                        .overlay(
                                                            Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                                        )

                                                    if activeTextColorScheme == scheme {
                                                        Circle()
                                                            .stroke(Color.accentColor, lineWidth: 2.5)
                                                            .frame(width: 34, height: 34)

                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(scheme == .pureWhite || scheme == .classicGold ? .black : .white)
                                                    }
                                                }
                                                .frame(width: 36, height: 36)
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        // Divider between presets and custom picker
                                        Rectangle()
                                            .fill(Color.secondary.opacity(0.25))
                                            .frame(width: 1, height: 24)
                                            .padding(.horizontal, 2)

                                        // 2. Advanced: Native iOS ColorPicker (🎨)
                                        ZStack {
                                            if viewModel.colorTarget == .arabic {
                                                ColorPicker("", selection: $viewModel.customTextColor, supportsOpacity: false)
                                                    .labelsHidden()
                                                    .frame(width: 30, height: 30)
                                                    .clipShape(Circle())
                                                    .onChange(of: viewModel.customTextColor) { _ in
                                                        withAnimation {
                                                            viewModel.textColorScheme = .custom
                                                        }
                                                    }
                                            } else {
                                                ColorPicker("", selection: $viewModel.customTranslationTextColor, supportsOpacity: false)
                                                    .labelsHidden()
                                                    .frame(width: 30, height: 30)
                                                    .clipShape(Circle())
                                                    .onChange(of: viewModel.customTranslationTextColor) { _ in
                                                        withAnimation {
                                                            viewModel.translationTextColorScheme = .custom
                                                        }
                                                    }
                                            }

                                            if activeTextColorScheme == .custom {
                                                Circle()
                                                    .stroke(Color.accentColor, lineWidth: 2.5)
                                                    .frame(width: 34, height: 34)
                                                    .allowsHitTesting(false)
                                            }
                                        }
                                        .frame(width: 36, height: 36)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)

                            // Customization Toggles
                            VStack(spacing: 0) {
                                Toggle(lChoice(kn: "ಅರೇಬಿಕ್ ಪಠ್ಯ ತೋರಿಸಿ", en: "Show Arabic Text", ar: "إظهار النص العربي"), isOn: $viewModel.showArabic)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)

                                Divider()
                                    .padding(.leading, 16)

                                Toggle(lChoice(kn: "ಅನುವಾದ ತೋರಿಸಿ", en: "Show Translation", ar: "إظهار الترجمة"), isOn: $viewModel.showTranslation)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)

                                if viewModel.hasFootnotes {
                                    Divider()
                                        .padding(.leading, 16)

                                    Toggle(lChoice(kn: "ಟಿಪ್ಪಣಿಗಳನ್ನು ಸೇರಿಸಿ", en: "Include Footnotes", ar: "تضمين الحواشي"), isOn: $viewModel.showFootnotes)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)

                            // Accompanying Message Mode
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    Text(lChoice(kn: "ಹಂಚಿಕೊಳ್ಳುವ ಸಂದೇಶ", en: "Accompanying Text", ar: "النص المرافق"))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 4)

                                Picker("", selection: $viewModel.captionMode) {
                                    ForEach(AyahShareCaptionMode.allCases) { mode in
                                        Text(mode.displayName(isVideoMode: viewModel.isVideoMode)).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(.horizontal, 16)

                            // Action Buttons
                            VStack(spacing: 10) {
                                // Share Button
                                Button {
                                    triggerShare()
                                } label: {
                                    HStack(spacing: 8) {
                                        if viewModel.isExporting {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Image(systemName: viewModel.isVideoMode ? "video.badge.checkmark" : "square.and.arrow.up")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        Text(
                                            viewModel.isVideoMode
                                                ? lChoice(kn: "ವೀಡಿಯೊ ಹಂಚಿಕೊಳ್ಳಿ", en: "Share Video", ar: "مشاركة الفيديو")
                                                : lChoice(kn: "ಹಂಚಿಕೊಳ್ಳಿ", en: "Share", ar: "مشاركة")
                                        )
                                        .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.12, green: 0.65, blue: 0.38))
                                    )
                                    .opacity(viewModel.isExporting ? 0.65 : 1.0)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .disabled(viewModel.isExporting)

                                // Save to Photos Button
                                Button {
                                    viewModel.saveToPhotos()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.down.to.line")
                                            .font(.system(size: 15, weight: .medium))
                                        Text(
                                            viewModel.isVideoMode
                                                ? lChoice(kn: "ಫೋಟೋಗಳಿಗೆ ವೀಡಿಯೊ ಉಳಿಸಿ", en: "Save Video to Photos", ar: "حفظ الفيديو في الصور")
                                                : lChoice(kn: "ಫೋಟೋಗಳಿಗೆ ಉಳಿಸಿ", en: "Save to Photos", ar: "حفظ في الصور")
                                        )
                                        .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                                    .opacity(viewModel.isExporting ? 0.65 : 1.0)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .disabled(viewModel.isExporting)
                            }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 30)
            }
            .padding(.top, 14)
        }
    }

    private func resolvePresenterViewController() -> UIViewController? {
        if let host = hostViewController, host.viewIfLoaded?.window != nil {
            var rootHost = host
            while let parent = rootHost.parent, !(parent is UINavigationController && parent.presentingViewController == nil) {
                rootHost = parent
            }
            var top = rootHost
            while let presented = top.presentedViewController, !presented.isBeingDismissed {
                top = presented
            }
            return top
        }

        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        guard let rootVC = (activeScene?.windows.first(where: \.isKeyWindow) ?? activeScene?.windows.first)?.rootViewController else {
            return nil
        }
        var topVC = rootVC
        while let presented = topVC.presentedViewController, !presented.isBeingDismissed {
            topVC = presented
        }
        return topVC
    }

    private func triggerShare() {
        guard let presenter = resolvePresenterViewController() else {
            return
        }
        viewModel.share(from: presenter, sourceView: presenter.view)
    }
}

private final class LoopingVideoContainerView: UIView {
    let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = true
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        playerLayer.bounds = bounds
        CATransaction.commit()
    }
}

private struct LoopingVideoPlayerView: UIViewRepresentable {
    let url: URL
    let scale: CGFloat

    final class Coordinator {
        var currentURL: URL?
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?

        deinit {
            player?.pause()
            player?.removeAllItems()
            looper = nil
            player = nil
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> LoopingVideoContainerView {
        let view = LoopingVideoContainerView()
        configurePlayer(for: view, coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: LoopingVideoContainerView, context: Context) {
        if context.coordinator.currentURL != url {
            configurePlayer(for: uiView, coordinator: context.coordinator)
        }
        uiView.playerLayer.setAffineTransform(
            scale > 1.01 ? CGAffineTransform(scaleX: scale, y: scale) : .identity
        )
    }

    static func dismantleUIView(_ uiView: LoopingVideoContainerView, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.player?.removeAllItems()
        coordinator.looper = nil
        coordinator.player = nil
        uiView.playerLayer.player = nil
    }

    private func configurePlayer(for view: LoopingVideoContainerView, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.player?.removeAllItems()
        coordinator.looper = nil
        coordinator.player = nil

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false
        let looper = AVPlayerLooper(player: queuePlayer, templateItem: item)

        coordinator.currentURL = url
        coordinator.player = queuePlayer
        coordinator.looper = looper
        view.playerLayer.player = queuePlayer
        queuePlayer.play()
    }
}

private struct CloudBackgroundSwatchesRow: View {
    let items: [RemoteAyahBackgroundItem]
    let selectedId: String?
    let fallbackSystemImage: String
    let browseTitle: String
    let isDownloaded: (RemoteAyahBackgroundItem) -> Bool
    let onBrowseMore: () -> Void
    let onSelectItem: (RemoteAyahBackgroundItem) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                VStack(spacing: 4) {
                    Button(action: onBrowseMore) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.accentColor.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.accentColor.opacity(0.08)))

                            VStack(spacing: 1) {
                                Image(systemName: "cloud.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(.accentColor)
                                Image(systemName: "plus")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .frame(width: 52, height: 52)
                    }
                    .buttonStyle(.plain)

                    Text(lChoice(kn: "ಇನ್ನಷ್ಟು", en: "More", ar: "المزيد"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }

                if items.isEmpty {
                    Button(action: onBrowseMore) {
                        HStack(spacing: 6) {
                            Image(systemName: "cloud.and.arrow.down")
                                .font(.system(size: 13, weight: .semibold))
                            Text(browseTitle)
                                .font(.system(size: 12.5, weight: .semibold))
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentColor.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                } else {
                    ForEach(items) { item in
                        let isSelected = selectedId == item.id
                        let downloaded = isDownloaded(item)
                        VStack(spacing: 4) {
                            ZStack {
                                RemoteMediaThumbnailView(item: item, fallbackSystemImage: fallbackSystemImage)
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())

                                if !downloaded {
                                    Circle()
                                        .fill(Color.black.opacity(0.28))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                                }

                                if isSelected {
                                    Circle()
                                        .stroke(Color.accentColor, lineWidth: 2.5)
                                        .frame(width: 52, height: 52)

                                    if downloaded {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(radius: 2)
                                    }
                                }
                            }
                            .frame(width: 54, height: 54)
                            .contentShape(Circle())
                            .onTapGesture {
                                onSelectItem(item)
                            }

                            Text(item.localizedName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isSelected ? .accentColor : .secondary)
                                .lineLimit(1)
                                .frame(maxWidth: 64)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct BackgroundZoomControl: View {
    let label: String
    @Binding var scale: CGFloat

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    if scale > 1.05 {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            scale = max(1.0, (scale * 10 - 1).rounded() / 10)
                        }
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Text("\(Int(round(scale * 100)))%")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .frame(width: 44)

                Button {
                    if scale < 1.95 {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            scale = min(2.0, (scale * 10 + 1).rounded() / 10)
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
}

private struct RemoteMediaThumbnailView: View {
    let item: RemoteAyahBackgroundItem
    let fallbackSystemImage: String
    @State private var image: UIImage?

    init(item: RemoteAyahBackgroundItem, fallbackSystemImage: String) {
        self.item = item
        self.fallbackSystemImage = fallbackSystemImage
        self._image = State(initialValue: RemoteBackgroundService.shared.cachedMemoryThumbnail(for: item.id))
    }

    var body: some View {
        ZStack {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(UIColor.tertiarySystemGroupedBackground)
                Image(systemName: fallbackSystemImage)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .task(id: item.id) {
            if image == nil {
                image = await RemoteBackgroundService.shared.loadThumbnail(for: item)
            }
        }
    }
}
