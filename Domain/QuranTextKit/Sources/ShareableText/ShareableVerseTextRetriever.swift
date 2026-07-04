//
//  ShareableVerseTextRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/4/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation
import Localization
import QuranKit
import QuranText
import TranslationService
import VerseTextPersistence

public struct ShareableVerseTextRetriever {
    // MARK: Lifecycle

    public init(databasesURL: URL, quranFileURL: URL) {
        textService = QuranTextDataService(databasesURL: databasesURL, quranFileURL: quranFileURL)
        shareableVersePersistence = GRDBQuranVerseTextPersistence(mode: .share, fileURL: quranFileURL)
        localTranslationsRetriever = LocalTranslationsRetriever(databasesURL: databasesURL)
    }

    init(
        textService: QuranTextDataService,
        shareableVersePersistence: VerseTextPersistence,
        localTranslationsRetriever: LocalTranslationsRetriever
    ) {
        self.textService = textService
        self.shareableVersePersistence = shareableVersePersistence
        self.localTranslationsRetriever = localTranslationsRetriever
    }

    // MARK: Public

    public func textForVerses(_ verses: [AyahNumber]) async throws -> [String] {
        let sharingPreferences = SharePreferences.shared
        let wantInlineAyahNumbers = sharingPreferences.includeInlineAyahNumbers
        let includeTranslation = sharingPreferences.includeTranslation
        let inlineTranslation = sharingPreferences.inlineTranslation
        let includeNotes = sharingPreferences.showNotes

        var footnotes: [String] = []
        var result: [String] = []

        if inlineTranslation {
            // Fetch translations if needed
            let selectedTrans = includeTranslation ? try await selectedTranslations() : []
            let verseTexts = selectedTrans.isEmpty ? [:] : try await textService.textForVerses(verses, translations: selectedTrans)

            for verse in verses {
                var ayahLine = ""

                // Prepend Ayah number in Western digits if enabled
                if wantInlineAyahNumbers && includeTranslation {
                    ayahLine += "\(verse.ayah). "
                }

                // Arabic text of this verse
                let arabicVerse = try await arabicText(for: verse)
                ayahLine += arabicVerse

                if includeTranslation && !selectedTrans.isEmpty {
                    result.append(ayahLine)

                    if let verseText = verseTexts[verse] {
                        for (index, _) in selectedTrans.enumerated() {
                            let text = verseText.translations[index]
                            let processedText = processTranslationText(text, includeNotes: includeNotes, footnotes: &footnotes)

                            if !processedText.isEmpty {
                                result.append(processedText)
                            }
                        }
                    }

                    result.append("")
                } else {
                    // No translation or grouped, use ۩ separator
                    result.append(ayahLine + " ۩")
                }
            }

        } else {
            // Grouped: Arabic first, then translations at the end
            let arabicScriptText = try await arabicScript(for: verses)
            result.append(contentsOf: arabicScriptText)
            result.append("")

            let translationsText = try await translations(for: verses, footnotes: &footnotes)
            if !translationsText.isEmpty {
                var cleanTranslations = translationsText
                if cleanTranslations.first == "" {
                    cleanTranslations.removeFirst()
                }
                result.append(contentsOf: cleanTranslations)
                result.append("")
            }
        }

        // Footnotes
        if includeNotes && !footnotes.isEmpty {
            let footnotesHeader = AppLanguage == .kannada ? "ಟಿಪ್ಪಣಿಗಳು : " : "Footnotes : "
            result.append(footnotesHeader)
            for (idx, note) in footnotes.enumerated() {
                result.append("\u{2007}\(idx + 1). \(note)")
            }
            result.append("")
        }

        // Summary
        let localizedSummary = versesSummary(verses)
        result.append("[\(localizedSummary)]")
        result.append("")

        // Download footer
        result.append("Download :")
        result.append("https://quran.hisnulmuslimdua.com/")

        return result
    }

    // MARK: Private

    private static let rightToLeftMark = "\u{202B}"
    private static let endMark = "\u{202C}"

    private let preferences = QuranContentStatePreferences.shared
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
    private let textService: QuranTextDataService
    private let shareableVersePersistence: VerseTextPersistence
    private let localTranslationsRetriever: LocalTranslationsRetriever

    private func versesSummary(_ verses: [AyahNumber]) -> String {
        guard let first = verses.first else { return "" }
        let suraName = first.sura.localizedName(withPrefix: false, language: .english)
        if verses.count == 1 {
            return "Surah \(suraName): \(first.ayah)"
        }
        return "Surah \(suraName): \(first.ayah)-\(verses.last!.ayah)"
    }

    private func arabicText(for verse: AyahNumber) async throws -> String {
        // Avoid the arabic text to be displayed in the wrong direction in LTR languages
        let arabicVerse = try await shareableVersePersistence.textForVerse(verse)

        return "\(Self.rightToLeftMark)\(arabicVerse)\(Self.endMark)"
    }

    private func arabicScript(for verses: [AyahNumber]) async throws -> [String] {
        // TODO: improve performance by parallize the loading
        let arabicAyahsText = try await verses.asyncMap { try await arabicText(for: $0) }
            .joined(separator: " ۩ ")
        return [arabicAyahsText + " ۩"]
    }

    private func translations(for verses: [AyahNumber], footnotes: inout [String]) async throws -> [String] {
        let sharingPreferences = SharePreferences.shared
        guard sharingPreferences.includeTranslation else {
            return []
        }

        let translations = try await selectedTranslations()
        let verseTexts = try await textService.textForVerses(verses, translations: translations)
        let orderedVerseTexts = verses.compactMap { verseTexts[$0] }
        return versesTranslationsText(translations: translations, verseTexts: orderedVerseTexts, verses: verses, footnotes: &footnotes)
    }

    private func versesTranslationsText(
        translations: [Translation],
        verseTexts: [VerseText],
        verses: [AyahNumber],
        footnotes: inout [String]
    ) -> [String] {
        var components = [""]
        let sharingPreferences = SharePreferences.shared

        for (index, translation) in translations.enumerated() {
            // translation text for all verses
            for (vIdx, verseText) in verseTexts.enumerated() {
                var transText = processTranslationText(
                    verseText.translations[index],
                    includeNotes: sharingPreferences.showNotes,
                    footnotes: &footnotes
                )
                if sharingPreferences.includeInlineAyahNumbers {
                    transText = "[\(verses[vIdx].ayah)] \(transText)"
                }
                components.append(transText)
            }

            // separate multiple translations
            components.append("")
        }

        return components.dropLast()
    }

    private func selectedTranslations() async throws -> [Translation] {
        let localTranslations = try await localTranslationsRetriever.getLocalTranslations()
        return selectedTranslationsPreferences.selectedTranslations(from: localTranslations)
    }

    private func cleanTextWithoutFootnotes(_ string: TranslationString) -> String {
        var cleanText = ""
        var currentIndex = string.text.startIndex
        for range in string.footnoteRanges {
            cleanText.append(contentsOf: string.text[currentIndex ..< range.lowerBound])
            currentIndex = range.upperBound
        }
        cleanText.append(contentsOf: string.text[currentIndex...])
        return cleanText
    }

    private func processTranslationText(_ text: TranslationText, includeNotes: Bool, footnotes: inout [String]) -> String {
        switch text {
        case .reference(let verse):
            return lFormat("translation.text.see-referenced-verse", verse.ayah)
        case .string(let string):
            if includeNotes {
                for footnote in string.footnotes {
                    let cleanFootnote = footnote.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                    footnotes.append(cleanFootnote)
                }
                return string.text
            } else {
                return cleanTextWithoutFootnotes(string)
            }
        }
    }
}
