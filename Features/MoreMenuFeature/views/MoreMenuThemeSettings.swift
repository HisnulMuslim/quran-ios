//
//  MoreMenuThemeSettings.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-25.
//

import Combine
import Localization
import NoorUI
import QuranText
import QuranTextKit
import SwiftUI
import UIx

public class ThemeSettingsHostingController: UIHostingController<AnyView> {
    public init(showFontSize: Bool = true) {
        let view = MoreMenuThemeSettingsView(showFontSize: showFontSize)
        super.init(rootView: AnyView(view))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil

        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let defaultWidth: CGFloat = isPad ? 480 : 380
        preferredContentSize = CGSize(width: defaultWidth, height: 480)

        sheetPresentationController?.prefersGrabberVisible = true
        sheetPresentationController?.prefersEdgeAttachedInCompactHeight = true
        sheetPresentationController?.widthFollowsPreferredContentSizeWhenEdgeAttached = true

        let detentId = UISheetPresentationController.Detent.Identifier("readingAppearance")
        if #available(iOS 16.0, *) {
            let customDetent = UISheetPresentationController.Detent.custom(identifier: detentId) { [weak self] context in
                let targetHeight = self?.preferredContentSize.height ?? 0
                if targetHeight > 100 {
                    return min(targetHeight, context.maximumDetentValue)
                }
                return min(480, context.maximumDetentValue)
            }
            sheetPresentationController?.detents = [customDetent, .large()]
            sheetPresentationController?.largestUndimmedDetentIdentifier = detentId
        } else {
            sheetPresentationController?.detents = [.medium(), .large()]
            sheetPresentationController?.largestUndimmedDetentIdentifier = .medium
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = nil
    }

    public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        let height = container.preferredContentSize.height
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let targetWidth: CGFloat = isPad ? 480 : 380
        if height > 0 {
            preferredContentSize = CGSize(width: targetWidth, height: height)
        }

        if #available(iOS 16.0, *) {
            sheetPresentationController?.invalidateDetents()
        }
    }
}

struct MoreMenuThemeSettingsMenuItem: View {
    let showFontSize: Bool

    @Environment(\.navigator) private var navigator
    @State private var viewController: UIViewController?

    var body: some View {
        Button {
            // capture the window before dismissing
            let window = viewController?.view.window
            navigator?.dismiss {
                let controller = ThemeSettingsHostingController(showFontSize: showFontSize)
                controller.modalPresentationStyle = .formSheet

                let parentVC = window?.rootViewController?.deepPresentedViewController()
                parentVC?.present(controller, animated: true)
            }
        } label: {
            NoorListItem(
                title: .text(l("menu.theme_settings")),
                accessory: .disclosureIndicator
            )
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(BackgroundHighlightingStyle())
        .background(Color.systemBackground)
        UIViewControllerReader(viewController: $viewController)
    }
}

private struct SectionHeader: View {
    let header: String
    var body: some View {
        Text(header)
            .font(.headline)
    }
}

private struct AppearanceModeSelectorButton: View {
    @Binding var selectedAppearance: AppearanceMode
    var body: some View {
        DropdownButton(items: [.auto, .dark, .light], selectedItem: $selectedAppearance) { appearance in
            Label(appearance.localizedName, systemImage: icon(for: appearance))
        }
    }

    private func icon(for mode: AppearanceMode) -> String {
        switch mode {
        case .auto: return "circle.righthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

private struct FontSizeView: View {
    let label: String
    let labelWidth: CGFloat
    @Binding var size: FontSize
    @Binding var labelSize: CGSize

    var body: some View {
        HStack {
            Text(label)
                .fixedSize()
                .onSizeChange {
                    labelSize = $0
                }
                .frame(width: labelWidth == 0 ? nil : labelWidth, alignment: .leading)

            Spacer()

            FontSizeStepper(fontSize: $size)
                .frame(width: 190)
        }
    }
}

private struct MoreMenuThemeSettingsView: View {
    @StateObject var viewModel = MoreMenuThemeSettingsViewModel()

    let showFontSize: Bool

    @State private var arabicLabelSize: CGSize = .zero
    @State private var arabicFontLabelSize: CGSize = .zero
    @State private var translationLabelSize: CGSize = .zero
    @State private var fontLabelSize: CGSize = .zero
    @State private var appLanguageLabelSize: CGSize = .zero

    @ScaledMetric var compactVerticalPadding = 3.0

    var fontSizeLabelWidth: CGFloat {
        max(arabicLabelSize.width, arabicFontLabelSize.width, translationLabelSize.width, fontLabelSize.width, appLanguageLabelSize.width)
    }

    private var showsArabicTypography: Bool {
        viewModel.translationViewMode == .both || viewModel.translationViewMode == .arabicOnly
    }

    private var showsTranslationTypography: Bool {
        viewModel.translationViewMode == .both || viewModel.translationViewMode == .translationOnly
    }

    var body: some View {
        let _ = viewModel.appLanguage
        PreferredContentSizeMatchesScrollView {
            ScrollView {
                VStack {
                    HStack {
                        Text(l("menu.theme_settings"))
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        CloseButton()
                    }

                    if showFontSize {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(l("menu.displayMode"))
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)

                            DisplayModeTabBar(
                                selectedMode: $viewModel.translationViewMode,
                                isModeDisabled: { mode in
                                    mode == .both && !viewModel.hasDownloadedTranslations
                                },
                                titleForMode: { mode in
                                    localizedName(for: mode)
                                }
                            )

                            if viewModel.translationViewMode == .translationOnly && viewModel.hasNoTranslations {
                                Text(l("menu.displayMode.noTranslationsWarning"))
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.top, 4)

                        if showsArabicTypography {
                            Divider()
                                .padding(.vertical, compactVerticalPadding)

                            FontSizeView(
                                label: l("menu.arabicFontSize"),
                                labelWidth: fontSizeLabelWidth,
                                size: $viewModel.arabicFontSize,
                                labelSize: $arabicLabelSize
                            )

                            Divider()
                                .padding(.vertical, compactVerticalPadding)

                            HStack {
                                Text(lChoice(kn: "ಅರೇಬಿಕ್ ಫಾಂಟ್", en: "Arabic Font", ar: "الخط العربي"))
                                    .fixedSize()
                                    .onSizeChange {
                                        arabicFontLabelSize = $0
                                    }
                                    .frame(width: fontSizeLabelWidth == 0 ? nil : fontSizeLabelWidth, alignment: .leading)

                                Spacer()

                                DropdownButton(
                                    items: ArabicFont.allCases,
                                    selectedItem: $viewModel.arabicFont
                                ) { font in
                                    arabicFontPreviewView(for: font)
                                }
                            }
                        }

                        if showsTranslationTypography {
                            Divider()
                                .padding(.vertical, compactVerticalPadding)

                            FontSizeView(
                                label: l("menu.translationFontSize"),
                                labelWidth: fontSizeLabelWidth,
                                size: $viewModel.translationFontSize,
                                labelSize: $translationLabelSize
                            )

                            Divider()
                                .padding(.vertical, compactVerticalPadding)

                            HStack {
                                Text(lAndroid("menu_translation_font"))
                                    .fixedSize()
                                    .onSizeChange {
                                        fontLabelSize = $0
                                    }
                                    .frame(width: fontSizeLabelWidth == 0 ? nil : fontSizeLabelWidth, alignment: .leading)

                                Spacer()

                                DropdownButton(
                                    items: TranslationFont.allCases,
                                    selectedItem: $viewModel.translationFont
                                ) { font in
                                    fontPreviewView(for: font)
                                }
                            }
                        }

                        HStack {
                            Spacer()
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.restoreFontDefaults()
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text(l("menu.restore_defaults"))
                                }
                                .font(.footnote.weight(.medium))
                                .foregroundColor(viewModel.canRestoreFontDefaults ? .accentColor : .secondary)
                            }
                            .buttonStyle(.plain)
                            .disabled(!viewModel.canRestoreFontDefaults)
                            .opacity(viewModel.canRestoreFontDefaults ? 1.0 : 0.5)
                            .padding(.vertical, 2)
                        }
                    }

                    Divider()
                        .padding(.vertical, compactVerticalPadding)

                    VStack(spacing: 0) {
                        HStack {
                            SectionHeader(header: l("menu.themes"))
                            Spacer()

                            AppearanceModeSelectorButton(selectedAppearance: $viewModel.appearanceMode)
                        }
                        .padding(.horizontal)

                        ThemeStyleSelector(selectedStyle: $viewModel.themeStyle)
                    }

                    if showFontSize {
                        Divider()
                            .padding(.vertical, compactVerticalPadding)

                        HStack {
                            Text(lChoice(kn: "ಆ್ಯಪ್ ಭಾಷೆ", en: "App Language", ar: "لغة التطبيق"))
                                .fixedSize()
                                .onSizeChange {
                                    appLanguageLabelSize = $0
                                }
                                .frame(width: fontSizeLabelWidth == 0 ? nil : fontSizeLabelWidth, alignment: .leading)

                            Spacer()

                            DropdownButton(
                                items: [Language.kannada, Language.english, Language.arabic],
                                selectedItem: $viewModel.appLanguage
                            ) { language in
                                switch language {
                                case .kannada: Text("ಕನ್ನಡ")
                                case .english: Text("English")
                                case .arabic: Text("العربية")
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(.thickMaterial)
    }

    @ViewBuilder
    private func arabicFontPreviewView(for font: ArabicFont) -> some View {
        let name = localizedName(for: font)
        switch font {
        case .uthmanic:
            Text(name)
                .font(Font(UIFont(.quran, size: 15)))
        case .kitab:
            Text(name)
                .font(Font(UIFont(.arabic, size: 15)))
        case .geezaPro:
            Text(name)
                .font(.custom("GeezaPro", size: 15))
        case .mishafi:
            Text(name)
                .font(.custom("DiwanMishafi", size: 15))
        case .system:
            Text(name)
                .font(.system(size: 15))
        }
    }

    private func localizedName(for font: ArabicFont) -> String {
        switch font {
        case .uthmanic:
            return lChoice(kn: "ಉಸ್ಮಾನಿ", en: "Uthmanic", ar: "عثماني")
        case .kitab:
            return lChoice(kn: "ಕಿತಾಬ್", en: "Kitab", ar: "كتاب")
        case .geezaPro:
            return lChoice(kn: "ಗೀಝಾ", en: "Geeza Pro", ar: "جيزا برو")
        case .mishafi:
            return lChoice(kn: "ಮಿಶಫಿ", en: "Mishafi", ar: "مصحفي")
        case .system:
            return lChoice(kn: "ಸಿಸ್ಟಮ್", en: "System", ar: "النظام")
        }
    }

    @ViewBuilder
    private func fontPreviewView(for font: TranslationFont) -> some View {
        let name = localizedName(for: font)
        switch font {
        case .kohinoor:
            Text(name)
                .font(.custom("KohinoorKannada-Regular", size: 15))
        case .system:
            Text(name)
                .font(.system(size: 15))
        case .notoSans:
            Text(name)
                .font(Font(UIFont(.kannada, size: 15)))
        }
    }

    private func localizedName(for font: TranslationFont) -> String {
        switch font {
        case .notoSans:
            return lAndroid("menu_translation_font_noto")
        case .kohinoor:
            return lAndroid("menu_translation_font_kohinoor")
        case .system:
            return lAndroid("menu_translation_font_system")
        }
    }

    private func localizedName(for mode: TranslationViewMode) -> String {
        switch mode {
        case .both:
            return l("menu.displayMode.both")
        case .arabicOnly:
            return l("menu.displayMode.arabicOnly")
        case .translationOnly:
            return l("menu.displayMode.translationOnly")
        }
    }
}

private struct DisplayModeTabBar: View {
    @Binding var selectedMode: TranslationViewMode
    let isModeDisabled: (TranslationViewMode) -> Bool
    let titleForMode: (TranslationViewMode) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(TranslationViewMode.allCases, id: \.self) { mode in
                let isSelected = selectedMode == mode
                let disabled = isModeDisabled(mode)

                Button {
                    guard !disabled, selectedMode != mode else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMode = mode
                    }
                } label: {
                    Text(titleForMode(mode))
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundColor(isSelected ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(isSelected ? Color.accentColor : Color.clear)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(disabled)
                .opacity(disabled ? 0.42 : 1.0)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemFill))
        )
    }
}

#Preview {
    VStack {
        Section {
            MoreMenuThemeSettingsMenuItem(showFontSize: true)
        }

        MoreMenuThemeSettingsView(showFontSize: false)
    }
}
