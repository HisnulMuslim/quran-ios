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
import SwiftUI
import TranslationService
import UIKit
import VLogging

@MainActor
public final class AyahShareImageViewModel: ObservableObject {
    @Published public var cardData: AyahCardData?
    @Published public var selectedTheme: AyahCardTheme = .emerald
    @Published public var selectedAspectRatio: AyahCardAspectRatio = .square
    @Published public var showArabic: Bool = true
    @Published public var showTranslation: Bool = true
    @Published public var showFootnotes: Bool = false
    @Published public var showQRCode: Bool = true
    @Published public var showAppURL: Bool = true
    @Published public var fontSizeScale: CGFloat = 1.0
    @Published public var arabicFont: AyahCardArabicFont = .uthmanic
    @Published public var translationFont: AyahCardTranslationFont = .notoSerif
    @Published public var colorTarget: AyahCardTextColorTarget = .arabic
    @Published public var textColorScheme: AyahCardTextColorScheme = .themeDefault
    @Published public var customTextColor: Color = Color(red: 1.0, green: 0.85, blue: 0.5)
    @Published public var translationTextColorScheme: AyahCardTextColorScheme = .themeDefault
    @Published public var customTranslationTextColor: Color = Color.white
    @Published public var photoScale: CGFloat = 1.0
    @Published public var captionMode: AyahShareCaptionMode = .linkOnly
    @Published public var customBackgroundImage: UIImage? = nil
    @Published public var hasFootnotes: Bool = false
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

            // Combine Translation texts and extract footnotes
            var translationLines: [String] = []
            var extractedFootnotes: [String] = []

            for verse in verses {
                if let verseText = versesTexts[verse], let firstTrans = verseText.translations.first {
                    let clean = cleanTranslationText(firstTrans)
                    if !clean.isEmpty {
                        translationLines.append(clean)
                    }
                    if case .string(let translationString) = firstTrans {
                        for fn in translationString.footnotes {
                            let cleanFn = cleanFootnoteString(String(fn))
                            if !cleanFn.isEmpty {
                                extractedFootnotes.append(cleanFn)
                            }
                        }
                    }
                }
            }
            let translationCombined = translationLines.joined(separator: "\n\n")
            let translatorName = selectedTrans.first?.translator
            let footnotesList = extractedFootnotes.isEmpty ? nil : extractedFootnotes
            self.hasFootnotes = footnotesList != nil

            self.cardData = AyahCardData(
                suraName: suraName,
                suraNumber: suraNumber,
                ayahRangeString: ayahRangeString,
                referenceText: referenceText,
                arabicText: arabicCombined,
                translationText: translationCombined,
                translator: translatorName,
                footnotes: footnotesList
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
            aspectRatio: selectedAspectRatio,
            showArabic: showArabic,
            showTranslation: showTranslation,
            showFootnotes: showFootnotes,
            showQRCode: showQRCode,
            showAppURL: showAppURL,
            fontSizeScale: fontSizeScale,
            textColorScheme: textColorScheme,
            customTextColor: textColorScheme == .custom ? customTextColor : nil,
            translationTextColorScheme: translationTextColorScheme,
            customTranslationTextColor: translationTextColorScheme == .custom ? customTranslationTextColor : nil,
            arabicFont: arabicFont,
            translationFont: translationFont,
            photoScale: photoScale,
            customImage: customBackgroundImage,
            isExport: true
        )
        return AyahCardRenderer.render(view: exportCard, targetWidth: 1080)
    }

    public func buildShortCompanionShareCaption() -> String {
        "https://quran.hisnulmuslimdua.com/"
    }

    public func buildCompanionShareCaption() -> String {
        let isKannada = AppLanguage == .kannada || Locale.current.languageCode == "kn"
        var parts: [String] = []

        if let ref = cardData?.referenceText {
            parts.append("📖 \(ref)")
        }

        if showArabic, let arabic = cardData?.arabicText, !arabic.isEmpty {
            parts.append(arabic)
        }

        if showTranslation, let trans = cardData?.translationText, !trans.isEmpty {
            parts.append(trans)
        }

        if showFootnotes, let notes = cardData?.footnotes, !notes.isEmpty {
            let header = isKannada ? "ಟಿಪ್ಪಣಿಗಳು:" : "Footnotes:"
            let notesFormatted = notes.joined(separator: "\n")
            parts.append("\(header)\n\(notesFormatted)")
        }

        parts.append("https://quran.hisnulmuslimdua.com/")
        return parts.joined(separator: "\n\n")
    }

    public func share(from viewController: UIViewController, sourceView: UIView?) {
        guard let image = generateExportImage() else { return }

        var items: [Any] = []
        let fileName = "kannada_quran_\(cardData?.suraNumber ?? 1)_\(cardData?.ayahRangeString ?? "ayah").png"
        if let fileURL = AyahCardRenderer.saveToTemporaryFile(image: image, fileName: fileName) {
            items.append(fileURL)
        }

        switch captionMode {
        case .imageOnly:
            break
        case .linkOnly:
            let shortCaption = buildShortCompanionShareCaption()
            if !shortCaption.isEmpty {
                items.append(shortCaption)
            }
        case .fullText:
            let fullCaption = buildCompanionShareCaption()
            if !fullCaption.isEmpty {
                items.append(fullCaption)
            }
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

    private func cleanFootnoteString(_ rawFootnote: String) -> String {
        var text = rawFootnote.trimmingCharacters(in: CharacterSet(charactersIn: "[] \t\n\r"))
        text = text.replacingOccurrences(of: "^\\[\\d+\\]\\s*", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "^\\[[0-9\\u0CE6-\\u0CEF]+\\]\\s*", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "^[0-9\\u0CE6-\\u0CEF]+[\\.\\:\\-]\\s*", with: "", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cleanTranslationText(_ translationText: TranslationText) -> String {
        switch translationText {
        case .string(let translationString):
            // Remove footnote markers using exact footnoteRanges
            var cleanText = ""
            var currentIndex = translationString.text.startIndex
            for range in translationString.footnoteRanges {
                cleanText.append(contentsOf: translationString.text[currentIndex ..< range.lowerBound])
                currentIndex = range.upperBound
            }
            cleanText.append(contentsOf: translationString.text[currentIndex...])

            var text = cleanText.isEmpty && !translationString.text.isEmpty ? translationString.text : cleanText
            // Also strip any bracketed footnote patterns or digits
            text = text.replacingOccurrences(of: "\\[\\[.*?\\]\\]", with: "", options: .regularExpression)
            text = text.replacingOccurrences(of: "\\[\\d+\\]", with: "", options: .regularExpression)
            text = text.replacingOccurrences(of: "\\[[0-9\\u0CE6-\\u0CEF]+\\]", with: "", options: .regularExpression)
            // Normalize spaces
            text = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .reference(let verse):
            return lFormat("translation.text.see-referenced-verse", verse.ayah)
        }
    }
}
