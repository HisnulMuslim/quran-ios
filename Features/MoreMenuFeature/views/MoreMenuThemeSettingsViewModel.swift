//
//  MoreMenuThemeSettingsViewModel.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-28.
//

import Combine
import Foundation
import Localization
import NoorUI
import QuranText
import QuranTextKit
import TranslationService
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
        hasNoTranslations = selectedTranslationsPreferences.selectedTranslationIds.isEmpty
        hasDownloadedTranslations = !selectedTranslationsPreferences.selectedTranslationIds.isEmpty

        selectedTranslationsPreferences.$selectedTranslationIds
            .sink { [weak self] ids in
                self?.hasNoTranslations = ids.isEmpty
                Task { [weak self] in
                    await self?.loadDownloadedTranslationsStatus()
                }
            }
            .store(in: &cancellables)

        Task { [weak self] in
            await self?.loadDownloadedTranslationsStatus()
        }

        $themeStyle
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set themeStyle \(newValue)")
                self?.themeService.themeStyle = newValue
            }
            .store(in: &cancellables)

        $appearanceMode
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set appearanceMode \(newValue)")
                self?.themeService.appearanceMode = newValue
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
                guard let self else { return }
                if newValue == .both && !self.hasDownloadedTranslations {
                    self.translationViewMode = .arabicOnly
                    return
                }
                logger.info("More Menu: set translation view mode \(newValue)")
                self.contentStatePreferences.translationViewMode = newValue
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
    @Published var hasNoTranslations: Bool
    @Published var hasDownloadedTranslations: Bool

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

    private func loadDownloadedTranslationsStatus() async {
        let databasesURL = FileManager.documentsURL.appendingPathComponent("databases", isDirectory: true)
        let retriever = LocalTranslationsRetriever(databasesURL: databasesURL)
        do {
            let localTranslations = try await retriever.getLocalTranslations()
            let hasDownloaded = localTranslations.contains { $0.isDownloaded }
            logger.info("MoreMenuThemeSettings: localTranslations count=\(localTranslations.count), hasDownloaded=\(hasDownloaded)")
            self.hasDownloadedTranslations = hasDownloaded
            if !hasDownloaded && self.translationViewMode == .both {
                self.translationViewMode = .arabicOnly
            }
        } catch {
            logger.error("MoreMenuThemeSettings: loadDownloadedTranslationsStatus error: \(error)")
        }
    }

    // MARK: Private

    private var cancellables: Set<AnyCancellable> = []

    private let themeService = ThemeService.shared
    private let fontSizePreferences = FontSizePreferences.shared
    private let contentStatePreferences = QuranContentStatePreferences.shared
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
}
