//
//  MoreMenuThemeSettingsViewModel.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-28.
//

import Combine
import Localization
import NoorUI
import QuranText
import QuranTextKit
import VLogging

@MainActor
final class MoreMenuThemeSettingsViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
        themeStyle = themeService.themeStyle
        appearanceMode = themeService.appearanceMode

        translationFontSize = fontSizePreferences.translationFontSize
        arabicFontSize = fontSizePreferences.arabicFontSize
        translationFont = fontSizePreferences.translationFont
        translationViewMode = contentStatePreferences.translationViewMode
        appLanguage = AppLanguage

        $themeStyle
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] newValue in
                logger.info("More Menu: set themeStyle \(newValue)")
                self?.themeService.themeStyle = newValue
            }
            .store(in: &cancellables)

        $appearanceMode
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] newValue in
                logger.info("More Menu: set appearanceMode \(newValue)")
                self?.themeService.appearanceMode = newValue
            }
            .store(in: &cancellables)

        themeService.themeStylePublisher
            .removeDuplicates()
            .sink { [weak self] newStyle in
                guard let self else { return }
                if self.themeStyle != newStyle {
                    self.themeStyle = newStyle
                }
            }
            .store(in: &cancellables)

        themeService.appearanceModePublisher
            .removeDuplicates()
            .sink { [weak self] newMode in
                guard let self else { return }
                if self.appearanceMode != newMode {
                    self.appearanceMode = newMode
                }
            }
            .store(in: &cancellables)

        $translationFontSize
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set translation font size \(newValue)")
                self?.fontSizePreferences.translationFontSize = newValue
            }
            .store(in: &cancellables)

        $arabicFontSize
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set arabic font size \(newValue)")
                self?.fontSizePreferences.arabicFontSize = newValue
            }
            .store(in: &cancellables)

        $translationFont
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set translation font \(newValue)")
                self?.fontSizePreferences.translationFont = newValue
            }
            .store(in: &cancellables)

        $translationViewMode
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set translation view mode \(newValue)")
                self?.contentStatePreferences.translationViewMode = newValue
            }
            .store(in: &cancellables)

        $appLanguage
            .dropFirst()
            .sink { newValue in
                logger.info("More Menu: set app language \(newValue)")
                AppLanguage = newValue
            }
            .store(in: &cancellables)
    }

    // MARK: Internal

    @Published var themeStyle: ThemeStyle
    @Published var appearanceMode: AppearanceMode

    @Published var arabicFontSize: FontSize
    @Published var translationFontSize: FontSize
    @Published var translationFont: TranslationFont
    @Published var translationViewMode: TranslationViewMode
    @Published var appLanguage: Language

    var canRestoreFontDefaults: Bool {
        arabicFontSize != FontSizePreferences.defaultArabicValue ||
        translationFontSize != FontSizePreferences.defaultTranslationValue ||
        translationFont != FontSizePreferences.defaultTranslationFont
    }

    func restoreFontDefaults() {
        arabicFontSize = FontSizePreferences.defaultArabicValue
        translationFontSize = FontSizePreferences.defaultTranslationValue
        translationFont = FontSizePreferences.defaultTranslationFont
    }

    // MARK: Private

    private var cancellables: Set<AnyCancellable> = []

    private let themeService = ThemeService.shared
    private let fontSizePreferences = FontSizePreferences.shared
    private let contentStatePreferences = QuranContentStatePreferences.shared
}
