//
//  AyahShareImageViewModel.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import Combine
import Foundation
import Localization
import QuranKit
import QuranText
import QuranTextKit
import TranslationService
import UIKit
import VLogging

@MainActor
public final class AyahShareImageViewModel: ObservableObject {
    @Published public var cardData: AyahCardData?
    @Published public var selectedTheme: AyahCardTheme = .emerald
    @Published public var showArabic: Bool = true
    @Published public var showTranslation: Bool = true
    @Published public var isLoading: Bool = true
    @Published public var saveSuccessToast: String?

    public let verses: [AyahNumber]
    private let databasesURL: URL
    private let quranFileURL: URL
    private let textService: QuranTextDataService
    private let localTranslationsRetriever: LocalTranslationsRetriever

    public init(verses: [AyahNumber], databasesURL: URL, quranFileURL: URL) {
        self.verses = verses
        self.databasesURL = databasesURL
        self.quranFileURL = quranFileURL
        self.textService = QuranTextDataService(databasesURL: databasesURL, quranFileURL: quranFileURL)
        self.localTranslationsRetriever = LocalTranslationsRetriever(databasesURL: databasesURL)
    }

    public func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let localTranslations = try await localTranslationsRetriever.getLocalTranslations()
            let selectedTrans = SelectedTranslationsPreferences.shared.selectedTranslations(from: localTranslations)
            let versesTexts = try await textService.textForVerses(verses, translations: selectedTrans)

            let isKannada = AppLanguage == .kannada || Locale.current.languageCode == "kn"
            guard let firstVerse = verses.first else { return }

            let suraName = isKannada ? firstVerse.sura.localizedName() : firstVerse.sura.localizedName(language: .english)
            let suraNumber = firstVerse.sura.suraNumber

            let ayahRangeString: String
            let referenceText: String
            if verses.count == 1 {
                let ayahFormatted = isKannada ? NumberFormatter.shared.format(firstVerse.ayah) : "\(firstVerse.ayah)"
                ayahRangeString = ayahFormatted
                referenceText = isKannada ? "\(suraName) : \(ayahFormatted)" : "Surah \(suraName): \(ayahFormatted)"
            } else {
                let lastVerse = verses.last!
                let startFormatted = isKannada ? NumberFormatter.shared.format(firstVerse.ayah) : "\(firstVerse.ayah)"
                let endFormatted = isKannada ? NumberFormatter.shared.format(lastVerse.ayah) : "\(lastVerse.ayah)"
                ayahRangeString = "\(startFormatted)–\(endFormatted)"
                referenceText = isKannada ? "\(suraName) : \(startFormatted)–\(endFormatted)" : "Surah \(suraName): \(startFormatted)–\(endFormatted)"
            }

            // Combine Arabic texts
            let arabicLines = verses.compactMap { versesTexts[$0]?.arabicText }
            let arabicCombined = arabicLines.joined(separator: " ۝ ")

            // Combine Translation texts
            var translationLines: [String] = []
            for verse in verses {
                if let verseText = versesTexts[verse], let firstTrans = verseText.translations.first {
                    let clean = cleanTranslationText(firstTrans)
                    if !clean.isEmpty {
                        translationLines.append(clean)
                    }
                }
            }
            let translationCombined = translationLines.joined(separator: "\n\n")
            let translatorName = selectedTrans.first?.translator

            self.cardData = AyahCardData(
                suraName: suraName,
                suraNumber: suraNumber,
                ayahRangeString: ayahRangeString,
                referenceText: referenceText,
                arabicText: arabicCombined,
                translationText: translationCombined,
                translator: translatorName
            )
        } catch {
            logger.error("AyahShareImageViewModel: Failed to load verses data: \(error)")
        }
    }

    public func generateExportImage() -> UIImage? {
        guard let data = cardData else { return nil }
        let exportCard = AyahShareCardView(
            data: data,
            theme: selectedTheme,
            showArabic: showArabic,
            showTranslation: showTranslation,
            isExport: true
        )
        return AyahCardRenderer.render(view: exportCard, targetWidth: 1080)
    }

    public func share(from viewController: UIViewController, sourceView: UIView?) {
        guard let image = generateExportImage() else { return }

        var items: [Any] = [image]
        let fileName = "kannada_quran_\(cardData?.suraNumber ?? 1)_\(cardData?.ayahRangeString ?? "ayah").png"
        if let fileURL = AyahCardRenderer.saveToTemporaryFile(image: image, fileName: fileName) {
            items.append(fileURL)
        }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = sourceView ?? viewController.view
            popover.sourceRect = sourceView?.bounds ?? CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 1, height: 1)
        }
        viewController.present(activityVC, animated: true)
    }

    public func saveToPhotos() {
        guard let image = generateExportImage() else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        let isKannada = AppLanguage == .kannada || Locale.current.languageCode == "kn"
        saveSuccessToast = isKannada ? "ಫೋಟೋಗಳಿಗೆ ಉಳಿಸಲಾಗಿದೆ! ✓" : "Saved to Photos! ✓"

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.saveSuccessToast = nil
        }
    }

    private func cleanTranslationText(_ translationText: TranslationText) -> String {
        switch translationText {
        case .string(let translationString):
            var text = translationString.text
            // Strip bracketed footnotes like [[1]] or [1]
            text = text.replacingOccurrences(of: "\\[\\[.*?\\]\\]", with: "", options: .regularExpression)
            text = text.replacingOccurrences(of: "\\[\\d+\\]", with: "", options: .regularExpression)
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .reference(let verse):
            return lFormat("translation.text.see-referenced-verse", verse.ayah)
        }
    }
}
