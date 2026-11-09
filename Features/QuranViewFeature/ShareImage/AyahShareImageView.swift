//
//  AyahShareImageView.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import Localization
import SwiftUI

public struct AyahShareImageView: View {
    @ObservedObject var viewModel: AyahShareImageViewModel
    @State private var backgroundMode: Int = 0 // 0 = Colors, 1 = Photos
    @State private var showingRemoteGallery = false
    let onDismiss: () -> Void

    public init(viewModel: AyahShareImageViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    private var isKannada: Bool {
        AppLanguage == .kannada || Locale.current.languageCode == "kn"
    }

    private var activeTextColorScheme: AyahCardTextColorScheme {
        viewModel.colorTarget == .arabic ? viewModel.textColorScheme : viewModel.translationTextColorScheme
    }

    private func loadThumbnail(name: String) -> UIImage? {
        if let img = UIImage(named: name) {
            return img
        }
        let testPath = "/Users/azhar/.gemini/antigravity/brain/bec757d9-597d-48e9-8d57-290aef403482/\(name).jpg"
        return UIImage(contentsOfFile: testPath)
    }

    public var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                } else if let cardData = viewModel.cardData {
                    ScrollView {
                        VStack(spacing: 18) {
                            // Live Card Preview
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
                                isExport: false
                            )
                            .padding(.top, 8)

                            // Aspect Ratio Selector (1:1, 4:5, 9:16)
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

                            // Background Mode Picker: Colors vs Photos
                            VStack(spacing: 12) {
                                Picker("", selection: $backgroundMode) {
                                    Text(isKannada ? "ಬಣ್ಣಗಳು" : "Colors").tag(0)
                                    Text(isKannada ? "ಫೋಟೋಗಳು" : "Photos").tag(1)
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, 16)
                                .onChange(of: backgroundMode) { newMode in
                                    if newMode == 1 && !viewModel.selectedTheme.isPhoto {
                                        if viewModel.customBackgroundImage != nil {
                                            viewModel.selectedTheme = .customPhoto
                                        } else {
                                            viewModel.selectedTheme = .mosqueDusk
                                        }
                                    } else if newMode == 0 && viewModel.selectedTheme.isPhoto {
                                        viewModel.selectedTheme = .emerald
                                    }
                                }

                                if backgroundMode == 0 {
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
                                } else {
                                    // Photo Swatches: Choose Custom Photo + All 8 Curated Presets
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 14) {
                                            // 1. More Cloud Backgrounds Button
                                            VStack(spacing: 4) {
                                                Button {
                                                    showingRemoteGallery = true
                                                } label: {
                                                    ZStack {
                                                        Circle()
                                                            .strokeBorder(Color.accentColor.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                                                            .frame(width: 44, height: 44)
                                                            .background(
                                                                Circle().fill(Color.accentColor.opacity(0.08))
                                                            )

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

                                                Text(isKannada ? "ಇನ್ನಷ್ಟು" : "More")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }

                                            // 2. Custom photo thumbnail (if user has picked one)
                                            if let custom = viewModel.customBackgroundImage {
                                                VStack(spacing: 4) {
                                                    ZStack {
                                                        Image(uiImage: custom)
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 44, height: 44)
                                                            .clipShape(Circle())

                                                        if viewModel.selectedTheme == .customPhoto {
                                                            Circle()
                                                                .stroke(Color.accentColor, lineWidth: 2.5)
                                                                .frame(width: 52, height: 52)

                                                            Image(systemName: "checkmark")
                                                                .font(.system(size: 13, weight: .bold))
                                                                .foregroundColor(.white)
                                                                .shadow(radius: 2)
                                                        }
                                                    }
                                                    .frame(width: 54, height: 54)
                                                    .contentShape(Circle())
                                                    .onTapGesture {
                                                        withAnimation(.easeInOut(duration: 0.2)) {
                                                            viewModel.selectedTheme = .customPhoto
                                                        }
                                                    }

                                                    Text(isKannada ? "ನನ್ನ ಚಿತ್ರ" : "My Photo")
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(viewModel.selectedTheme == .customPhoto ? .accentColor : .secondary)
                                                }
                                            }

                                            // 3. All 8 Curated Presets
                                            ForEach(AyahCardTheme.photoThemes) { theme in
                                                VStack(spacing: 4) {
                                                    ZStack {
                                                        if let name = theme.imageName, let img = loadThumbnail(name: name) {
                                                            Image(uiImage: img)
                                                                .resizable()
                                                                .scaledToFill()
                                                                .frame(width: 44, height: 44)
                                                                .clipShape(Circle())
                                                        } else {
                                                            Circle()
                                                                .fill(theme.iconColor)
                                                                .frame(width: 44, height: 44)
                                                        }

                                                        if viewModel.selectedTheme == theme {
                                                            Circle()
                                                                .stroke(Color.accentColor, lineWidth: 2.5)
                                                                .frame(width: 52, height: 52)

                                                            Image(systemName: "checkmark")
                                                                .font(.system(size: 13, weight: .bold))
                                                                .foregroundColor(.white)
                                                                .shadow(radius: 2)
                                                        }
                                                    }
                                                    .frame(width: 54, height: 54)
                                                    .contentShape(Circle())
                                                    .onTapGesture {
                                                        withAnimation(.easeInOut(duration: 0.2)) {
                                                            viewModel.selectedTheme = theme
                                                        }
                                                    }

                                                    Text(theme.displayName)
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(viewModel.selectedTheme == theme ? .accentColor : .secondary)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }

                                    // Photo Zoom Control (for background photos)
                                    HStack {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                            Text(isKannada ? "ಫೋಟೋ ಜೂಮ್" : "Photo Zoom")
                                                .font(.system(size: 13, weight: .medium))
                                        }

                                        Spacer()

                                        HStack(spacing: 12) {
                                            Button {
                                                if viewModel.photoScale > 1.05 {
                                                    withAnimation(.easeInOut(duration: 0.15)) {
                                                        viewModel.photoScale = max(1.0, (viewModel.photoScale * 10 - 1).rounded() / 10)
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

                                            Text("\(Int(round(viewModel.photoScale * 100)))%")
                                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                                .frame(width: 44)

                                            Button {
                                                if viewModel.photoScale < 1.95 {
                                                    withAnimation(.easeInOut(duration: 0.15)) {
                                                        viewModel.photoScale = min(2.0, (viewModel.photoScale * 10 + 1).rounded() / 10)
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
                            .frame(maxWidth: .infinity)

                            // Text Size Stepper (50% to 200%)
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "textformat.size")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                    Text(isKannada ? "ಪಠ್ಯದ ಗಾತ್ರ" : "Text Size")
                                        .font(.system(size: 14, weight: .medium))
                                }

                                Spacer()

                                HStack(spacing: 12) {
                                    Button {
                                        if viewModel.fontSizeScale > 0.55 {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                viewModel.fontSizeScale = max(0.5, (viewModel.fontSizeScale * 10 - 1).rounded() / 10)
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
                                        Text(isKannada ? "ಫಾಂಟ್ ಶೈಲಿ" : "Font Style")
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
                                        Text(isKannada ? "ಪಠ್ಯದ ಬಣ್ಣ" : "Text Color")
                                            .font(.system(size: 14, weight: .medium))
                                    }

                                    Spacer()

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
                                    Text(isKannada ? "ಅರೇಬಿಕ್" : "Arabic").tag(AyahCardTextColorTarget.arabic)
                                    Text(isKannada ? "ಅನುವಾದ" : "Translation").tag(AyahCardTextColorTarget.translation)
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
                                Toggle(isKannada ? "ಅರೇಬಿಕ್ ಪಠ್ಯ ತೋರಿಸಿ" : "Show Arabic Text", isOn: $viewModel.showArabic)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)

                                Divider()
                                    .padding(.leading, 16)

                                Toggle(isKannada ? "ಅನುವಾದ ತೋರಿಸಿ" : "Show Translation", isOn: $viewModel.showTranslation)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)

                                if viewModel.hasFootnotes {
                                    Divider()
                                        .padding(.leading, 16)

                                    Toggle(isKannada ? "ಟಿಪ್ಪಣಿಗಳನ್ನು ಸೇರಿಸಿ" : "Include Footnotes", isOn: $viewModel.showFootnotes)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }

                                Divider()
                                    .padding(.leading, 16)

                                Toggle(isKannada ? "QR ಕೋಡ್ ಸೇರಿಸಿ" : "Include QR Code", isOn: $viewModel.showQRCode)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
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
                                    Text(isKannada ? "ಹಂಚಿಕೊಳ್ಳುವ ಸಂದೇಶ" : "Accompanying Text")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 4)

                                Picker("", selection: $viewModel.captionMode) {
                                    ForEach(AyahShareCaptionMode.allCases) { mode in
                                        Text(mode.displayName).tag(mode)
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
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text(isKannada ? "ಹಂಚಿಕೊಳ್ಳಿ" : "Share")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.12, green: 0.65, blue: 0.38))
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                // Save to Photos Button
                                Button {
                                    viewModel.saveToPhotos()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.down.to.line")
                                            .font(.system(size: 15, weight: .medium))
                                        Text(isKannada ? "ಫೋಟೋಗಳಿಗೆ ಉಳಿಸಿ" : "Save to Photos")
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
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 30)
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
            .navigationTitle(isKannada ? "ಚಿತ್ರ ಹಂಚಿಕೆ" : "Share Ayah")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
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
            .sheet(isPresented: $showingRemoteGallery) {
                RemoteBackgroundPickerView(viewModel: viewModel, isPresented: $showingRemoteGallery)
            }
            .onChange(of: viewModel.customBackgroundImage) { newImage in
                if newImage != nil {
                    withAnimation {
                        viewModel.selectedTheme = .customPhoto
                        backgroundMode = 1
                    }
                }
            }
        }
    }

    private func triggerShare() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController else {
            return
        }
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        viewModel.share(from: topVC, sourceView: nil)
    }
}
