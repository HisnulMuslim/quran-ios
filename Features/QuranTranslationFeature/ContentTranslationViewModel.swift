//
//  ContentTranslationViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-12-29.
//

import AnnotationsService
import Combine
import Crashing
import Foundation
import QuranKit
import QuranText
import QuranTextKit
import SwiftUI
import TranslationService
import UIx
import VLogging

@MainActor
public final class ContentTranslationViewModel: ObservableObject {
    // MARK: Lifecycle

    public init(
        localTranslationsRetriever: LocalTranslationsRetriever,
        dataService: QuranTextDataService,
        highlightsService: QuranHighlightsService
    ) {
        self.dataService = dataService
        self.highlightsService = highlightsService
        self.localTranslationsRetriever = localTranslationsRetriever
        arabicFontSize = fontSizePreferences.arabicFontSize
        translationFontSize = fontSizePreferences.translationFontSize
        translationFont = fontSizePreferences.translationFont
        translationViewMode = quranContentStatePreferences.translationViewMode
        selectedTranslations = selectedTranslationsPreferences.selectedTranslationIds
        highlights = highlightsService.highlights.versesByHighlights().mapValues { Color($0) }

        highlightsService.$highlights
            .sink { [weak self] in self?.highlights = $0.versesByHighlights().mapValues { Color($0) } }
            .store(in: &cancellables)

        highlightsService.scrolling
            .sink { [weak self] in
                self?.scrollToVerseIfNeeded()
            }
            .store(in: &cancellables)

        fontSizePreferences.$translationFontSize
            .sink { [weak self] in self?.translationFontSize = $0 }
            .store(in: &cancellables)

        fontSizePreferences.$translationFont
            .sink { [weak self] in self?.translationFont = $0 }
            .store(in: &cancellables)

        fontSizePreferences.$arabicFontSize
            .sink { [weak self] in self?.arabicFontSize = $0 }
            .store(in: &cancellables)

        quranContentStatePreferences.$translationViewMode
            .sink { [weak self] in self?.translationViewMode = $0 }
            .store(in: &cancellables)

        selectedTranslationsPreferences.$selectedTranslationIds
            .sink { [weak self] newIds in
                self?.selectedTranslations = newIds
            }
            .store(in: &cancellables)

        selectedTranslationsPreferences.$selectedTranslationIds
            .dropFirst()
            .sink { [weak self] newIds in
                guard let self else { return }
                if newIds.isEmpty {
                    if self.quranContentStatePreferences.translationViewMode == .translationOnly ||
                       self.quranContentStatePreferences.translationViewMode == .both {
                        self.quranContentStatePreferences.translationViewMode = .arabicOnly
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Public

    @Published public var showHeaderAndFooter = true
    @Published public var verses: [AyahNumber] = []

    // MARK: Internal

    let tracker = CollectionTracker<TranslationItemId>()

    @Published var selectedTranslations: [Translation.ID]
    @Published var translations: [Translation] = []
    @Published var hasLoaded = false
    @Published var verseTexts: [AyahNumber: VerseText] = [:]
    @Published var lookaheadVerseTexts: [AyahNumber: VerseText] = [:]
    @Published var expandedTranslations: [AyahNumber: [Translation: [Range<String.Index>]]] = [:]

    @Published var translationFontSize: FontSize
    @Published var translationFont: TranslationFont
    @Published var arabicFontSize: FontSize
    @Published var translationViewMode: TranslationViewMode

    @Published var highlights: [AyahNumber: Color]

    @Published var footnote: TranslationFootnote?

    @Published var scrollToItem: TranslationItemId?
    @Published var scrollTriggerCount: Int = 0

    var items: [TranslationItem] {
        guard let page = verseTexts.first?.key.page else {
            return []
        }
        guard verseTexts.first?.value.translations.count == translations.count else {
            return []
        }

        if translationViewMode == .translationOnly && translations.isEmpty {
            var emptyItems: [TranslationItem] = []
            if showHeaderAndFooter {
                emptyItems.append(.pageHeader(TranslationPageHeader(page: page)))
                emptyItems.append(.pageFooter(TranslationPageFooter(page: page)))
            }
            return emptyItems
        }

        let scrollingVerse = highlightsService.highlights.firstScrollingVerse()

        var items: [TranslationItem] = []
        var currentSuraVerses: [TranslationArabicText] = []
        var currentSura: Sura?

        let (combinedTargets, combinedRanges) = precomputeCombinedAyahs()

        let isFrontispiecePage = translationViewMode == .arabicOnly && (page.pageNumber == 1 || page.pageNumber == 2)

        for (verse, verseText) in verseTexts.sorted(by: { $0.key < $1.key }) {
            let verseHighlightColor = highlights[verse]
            var translationColor = verseHighlightColor
            if translationColor == nil, let rangeInfo = combinedRanges[0]?[verse] {
                for a in rangeInfo.startAyah ..< rangeInfo.endAyah {
                    if let emptyVerse = AyahNumber(quran: verse.quran, sura: verse.sura.suraNumber, ayah: a),
                       let emptyColor = highlights[emptyVerse] {
                        translationColor = emptyColor
                        break
                    }
                }
            }

            if translationViewMode == .arabicOnly {
                if isFrontispiecePage {
                    currentSura = verse.sura
                    let arabicVerseNumber = NumberFormatter.arabicNumberFormatter.format(verse.ayah)
                    let arabicText = verseText.arabicText + " " + arabicVerseNumber
                    currentSuraVerses.append(TranslationArabicText(verse: verse, text: arabicText, arabicFontSize: arabicFontSize, highlightColor: verseHighlightColor))
                } else {
                    if currentSura != verse.sura {
                        if let prevSura = currentSura, !currentSuraVerses.isEmpty {
                            items.append(.continuousArabic(TranslationContinuousArabic(sura: prevSura, verses: currentSuraVerses, arabicFontSize: arabicFontSize, scrollToVerse: scrollingVerse, scrollTriggerCount: scrollTriggerCount)))
                            currentSuraVerses = []
                        }
                        currentSura = verse.sura
                        // Add sura name, if a new sura
                        if verse.sura.firstVerse == verse {
                            items.append(.suraName(TranslationSuraName(sura: verse.sura, arabicFontSize: arabicFontSize), verseHighlightColor))
                        }
                    }

                    // Add arabic verse with number
                    let arabicVerseNumber = NumberFormatter.arabicNumberFormatter.format(verse.ayah)
                    let arabicText = verseText.arabicText + " " + arabicVerseNumber
                    currentSuraVerses.append(TranslationArabicText(verse: verse, text: arabicText, arabicFontSize: arabicFontSize, highlightColor: verseHighlightColor))
                }
            } else {
                // Add sura name, if a new sura
                if verse.sura.firstVerse == verse {
                    items.append(.suraName(TranslationSuraName(sura: verse.sura, arabicFontSize: arabicFontSize), verseHighlightColor))
                }

                // In translation-only mode, if this verse has no translation of its own because it is merged
                // into a future verse across all selected translations, skip it completely.
                let isMergedInAllTranslations = !translations.isEmpty && translations.indices.allSatisfy { index in
                    combinedTargets[index]?[verse] != nil
                }

                if translationViewMode == .translationOnly && isMergedInAllTranslations {
                    continue
                }

                // Add arabic quran text if in both mode
                if translationViewMode == .both {
                    let arabicVerseNumber = NumberFormatter.arabicNumberFormatter.format(verse.ayah)
                    let arabicText = verseText.arabicText + " " + arabicVerseNumber
                    // In both mode, the entire row container already receives `verseHighlightColor` background.
                    // Passing `highlightColor: nil` prevents double-layer alpha blending and inner glyph boxes.
                    items.append(.arabicText(TranslationArabicText(verse: verse, text: arabicText, arabicFontSize: arabicFontSize, highlightColor: nil), verseHighlightColor))
                } else if translationViewMode == .translationOnly {
                    // Ayah number badge is rendered inline at the start of the translation
                }

                if translationViewMode == .both || translationViewMode == .translationOnly {
                    for (index, translation) in translations.enumerated() {
                        let text = verseText.translations[index]
                        let isFirstTranslation = index == 0
                        let showAyahBadge = (translationViewMode == .translationOnly) && isFirstTranslation

                        // If this verse is merged into another verse for this translation:
                        if let targetVerse = combinedTargets[index]?[verse] {
                            items.append(
                                .translationReferenceVerse(
                                    TranslationReferenceVerse(
                                        verse: verse,
                                         translation: translation,
                                        reference: targetVerse,
                                        translationFontSize: translationFontSize,
                                        showAyahBadge: showAyahBadge
                                    ), translationColor
                                )
                            )
                        } else {
                            let combinedInfo = combinedRanges[index]?[verse]
                            let badgeStartAyah = combinedInfo?.startAyah

                            switch text {
                            case .reference(let reference):
                                items.append(
                                    .translationReferenceVerse(
                                        TranslationReferenceVerse(
                                            verse: verse,
                                            translation: translation,
                                            reference: reference,
                                            translationFontSize: translationFontSize,
                                            showAyahBadge: showAyahBadge
                                        ), translationColor
                                    )
                                )
                            case .string(let originalString):
                                let string: TranslationString
                                if translationViewMode == .translationOnly, let info = combinedInfo, info.prefixLength > 0 {
                                    string = originalString.strippingCombinedPrefix(info.prefixLength)
                                } else {
                                    string = originalString
                                }

                                let chunks: [Range<String.Index>]
                                let readMore: Bool
                                if let cutoffChunk = cutoffChunkIfTruncationNeeded(string.text) {
                                    if let expandedChunks = expandedChunks(verse: verse, translation: translation) {
                                        chunks = expandedChunks
                                        readMore = false
                                    } else {
                                        chunks = [cutoffChunk]
                                        readMore = true
                                    }
                                } else {
                                    chunks = [string.text.startIndex ..< string.text.endIndex]
                                    readMore = false
                                }

                                for chunkIndex in 0 ..< chunks.count {
                                    items.append(
                                        .translationTextChunk(
                                            TranslationTextChunk(
                                                verse: verse,
                                                translation: translation,
                                                text: string,
                                                chunks: chunks,
                                                chunkIndex: chunkIndex,
                                                readMore: chunkIndex == chunks.count - 1 ? readMore : false, // Add read more to the last chunk.
                                                translationFontSize: translationFontSize,
                                                translationFont: translationFont,
                                                showAyahBadge: showAyahBadge && chunkIndex == 0,
                                                badgeStartAyah: badgeStartAyah
                                            ), translationColor
                                        )
                                    )
                                }
                            }
                        }

                        // Show translator if showing more than a single translation.
                        if translations.count > 1 {
                            items.append(
                                .translatorText(
                                    TranslatorText(
                                        verse: verse,
                                        translation: translation,
                                        translationFontSize: translationFontSize
                                    ), translationColor
                                )
                            )
                        }
                    }
                }

                let isLastVerseInTheView = verses.last == verse
                if !isLastVerseInTheView {
                    items.append(.verseSeparator(TranslationVerseSeparator(verse: verse), verseHighlightColor))
                }
            }
        }

        if case .verseSeparator = items.last {
            items.removeLast()
        }

        if translationViewMode == .arabicOnly, !currentSuraVerses.isEmpty {
            let scrollingVerse = highlightsService.highlights.firstScrollingVerse()
            if isFrontispiecePage, let sura = currentSura ?? verses.first?.sura {
                items.append(.frontispieceArabic(TranslationFrontispieceArabic(page: page, sura: sura, verses: currentSuraVerses, arabicFontSize: arabicFontSize, scrollToVerse: scrollingVerse, scrollTriggerCount: scrollTriggerCount)))
            } else if let lastSura = currentSura {
                items.append(.continuousArabic(TranslationContinuousArabic(sura: lastSura, verses: currentSuraVerses, arabicFontSize: arabicFontSize, scrollToVerse: scrollingVerse, scrollTriggerCount: scrollTriggerCount)))
            }
        }

        if showHeaderAndFooter {
            items.insert(.pageHeader(TranslationPageHeader(page: page)), at: 0)
            items.append(.pageFooter(TranslationPageFooter(page: page)))
        }

        return items
    }

    func load() async {
        do {
            logger.info("Loading translations data; selectedTranslations='\(selectedTranslations)'; verses='\(verses)'")
            let localTranslations = try await localTranslationsRetriever.getLocalTranslations()
            translations = selectedTranslationsPreferences.selectedTranslations(from: localTranslations)

            // Deselect any translations that are not downloaded on disk
            let downloadedIds = Set(localTranslations.filter(\.isDownloaded).map(\.id))
            let uninstalledIds = selectedTranslationsPreferences.selectedTranslationIds.filter { !downloadedIds.contains($0) }
            for id in uninstalledIds {
                selectedTranslationsPreferences.deselect(id)
            }

            if downloadedIds.isEmpty && quranContentStatePreferences.translationViewMode == .both {
                quranContentStatePreferences.translationViewMode = .arabicOnly
            }

            let verses = verses
            let loadedVerseTexts = try await dataService.textForVerses(verses, translations: translations)

            // Detect if any verse on the page has an empty translation string in any translation
            var neededLookaheadVerses: Set<AyahNumber> = []
            for (verse, verseText) in loadedVerseTexts {
                for text in verseText.translations {
                    let isEmpty: Bool = switch text {
                    case .string(let s):
                        s.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    case .reference:
                        false
                    }
                    if isEmpty {
                        // Look ahead up to 5 verses in the same surah to find the combined target
                        for offset in 1...5 {
                            if let nextVerse = AyahNumber(quran: verse.quran, sura: verse.sura.suraNumber, ayah: verse.ayah + offset) {
                                if !verses.contains(nextVerse) {
                                    neededLookaheadVerses.insert(nextVerse)
                                }
                            }
                        }
                    }
                }
            }

            var extraTexts: [AyahNumber: VerseText] = [:]
            if !neededLookaheadVerses.isEmpty {
                let lookaheadList = Array(neededLookaheadVerses).sorted()
                extraTexts = (try? await dataService.textForVerses(lookaheadList, translations: translations)) ?? [:]
            }

            lookaheadVerseTexts = extraTexts
            verseTexts = loadedVerseTexts
            hasLoaded = true

            scrollToVerseIfNeeded()
        } catch {
            // TODO: should show error to the user
            crasher.recordError(error, reason: "Failed to retrieve quran page details")
            hasLoaded = true
        }
    }

    func openURL(_ url: TranslationURL) {
        switch url {
        case .footnote(let translationId, let sura, let ayah, let footnoteIndex):
            setFootnoteIfNeeded(translationId: translationId, sura: sura, ayah: ayah, footnoteIndex: footnoteIndex)

        case .readMore(let translationId, let sura, let ayah):
            expandTranslationIfNeeded(translationId: translationId, sura: sura, ayah: ayah)
        }
    }

    func ayahAtPoint(_ point: CGPoint) -> AyahNumber? {
        if let ayah = tracker.itemAtPoint(point)?.ayah {
            return ayah
        }
        // Fallback for touches outside tracked regions (e.g. Surah header banner or margins on Page 1 & 2)
        if let first = verses.first, (first.page.pageNumber == 1 || first.page.pageNumber == 2) {
            return first
        }
        return nil
    }

    var isTranslationOnlyEmpty: Bool {
        guard translationViewMode == .translationOnly else { return false }
        if selectedTranslations.isEmpty {
            return true
        }
        return hasLoaded && translations.isEmpty
    }

    func switchToArabicMode() {
        quranContentStatePreferences.translationViewMode = .arabicOnly
    }

    func increaseFontSizes() {
        let range = FontSize.supportedRange

        withAnimation(.easeInOut(duration: 0.16)) {
            // Increase translation font size
            let currentTranslation = translationFontSize.clampedToSupported
            if let index = range.firstIndex(of: currentTranslation), index < range.count - 1 {
                let newSize = range[index + 1]
                translationFontSize = newSize
                fontSizePreferences.translationFontSize = newSize
            } else if translationFontSize != currentTranslation {
                translationFontSize = currentTranslation
                fontSizePreferences.translationFontSize = currentTranslation
            }

            // Increase arabic font size
            let currentArabic = arabicFontSize.clampedToSupported
            if let index = range.firstIndex(of: currentArabic), index < range.count - 1 {
                let newSize = range[index + 1]
                arabicFontSize = newSize
                fontSizePreferences.arabicFontSize = newSize
            } else if arabicFontSize != currentArabic {
                arabicFontSize = currentArabic
                fontSizePreferences.arabicFontSize = currentArabic
            }
        }
    }

    func decreaseFontSizes() {
        let range = FontSize.supportedRange

        withAnimation(.easeInOut(duration: 0.16)) {
            // Decrease translation font size
            let currentTranslation = translationFontSize.clampedToSupported
            if let index = range.firstIndex(of: currentTranslation), index > 0 {
                let newSize = range[index - 1]
                translationFontSize = newSize
                fontSizePreferences.translationFontSize = newSize
            } else if translationFontSize != currentTranslation {
                translationFontSize = currentTranslation
                fontSizePreferences.translationFontSize = currentTranslation
            }

            // Decrease arabic font size
            let currentArabic = arabicFontSize.clampedToSupported
            if let index = range.firstIndex(of: currentArabic), index > 0 {
                let newSize = range[index - 1]
                arabicFontSize = newSize
                fontSizePreferences.arabicFontSize = newSize
            } else if arabicFontSize != currentArabic {
                arabicFontSize = currentArabic
            }
        }
    }

    func resetFontSizesToDefault() {
        withAnimation(.easeInOut(duration: 0.2)) {
            translationFontSize = FontSizePreferences.defaultTranslationValue
            fontSizePreferences.translationFontSize = FontSizePreferences.defaultTranslationValue
            arabicFontSize = FontSizePreferences.defaultArabicValue
            fontSizePreferences.arabicFontSize = FontSizePreferences.defaultArabicValue
        }
    }

    // MARK: Private

    private struct CombinedAyahInfo: Equatable {
        let startAyah: Int
        let endAyah: Int
        let prefixLength: Int
    }

    private static let combinedPrefixRegex = try! NSRegularExpression(
        pattern: #"^\s*[\(（\[【]?\s*(\d+)\s*[-–—]\s*(\d+)\s*[\)）\]】]\s*"#
    )

    private func parseCombinedInfo(for verse: AyahNumber, text: TranslationText) -> CombinedAyahInfo? {
        switch text {
        case .string(let translationString):
            let string = translationString.text
            let nsString = string as NSString
            guard let match = Self.combinedPrefixRegex.firstMatch(in: string, range: NSRange(location: 0, length: nsString.length)) else {
                return nil
            }
            guard match.numberOfRanges >= 3 else { return nil }
            let startStr = nsString.substring(with: match.range(at: 1))
            let endStr = nsString.substring(with: match.range(at: 2))
            guard let start = Int(startStr), let end = Int(endStr) else { return nil }
            guard start < end, end == verse.ayah else { return nil }
            return CombinedAyahInfo(startAyah: start, endAyah: end, prefixLength: match.range.length)
        case .reference:
            return nil
        }
    }

    private func precomputeCombinedAyahs() -> (targets: [Int: [AyahNumber: AyahNumber]], ranges: [Int: [AyahNumber: CombinedAyahInfo]]) {
        var combinedTargets: [Int: [AyahNumber: AyahNumber]] = [:]
        var combinedRanges: [Int: [AyahNumber: CombinedAyahInfo]] = [:]

        let allVerseTexts = verseTexts.merging(lookaheadVerseTexts) { current, _ in current }

        for (index, _) in translations.enumerated() {
            var targets: [AyahNumber: AyahNumber] = [:]
            var ranges: [AyahNumber: CombinedAyahInfo] = [:]

            for (verse, verseText) in allVerseTexts {
                guard index < verseText.translations.count else { continue }
                let text = verseText.translations[index]

                if case .reference(let target) = text {
                    targets[verse] = target
                }

                if let info = parseCombinedInfo(for: verse, text: text) {
                    ranges[verse] = info
                    for a in info.startAyah ..< info.endAyah {
                        if let emptyVerse = AyahNumber(quran: verse.quran, sura: verse.sura.suraNumber, ayah: a) {
                            targets[emptyVerse] = verse
                        }
                    }
                }
            }

            for (verse, _) in allVerseTexts {
                if ranges[verse] == nil {
                    let referencingAyahs = targets.filter { $0.value == verse }.map { $0.key.ayah }
                    if let minAyah = referencingAyahs.min(), minAyah < verse.ayah {
                        ranges[verse] = CombinedAyahInfo(startAyah: minAyah, endAyah: verse.ayah, prefixLength: 0)
                    }
                }
            }

            combinedTargets[index] = targets
            combinedRanges[index] = ranges
        }

        return (combinedTargets, combinedRanges)
    }

    private static let maxChunkSize = 800

    private var cancellables: Set<AnyCancellable> = []
    private let highlightsService: QuranHighlightsService
    private let dataService: QuranTextDataService
    private let localTranslationsRetriever: LocalTranslationsRetriever
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
    private let fontSizePreferences = FontSizePreferences.shared
    private let quranContentStatePreferences = QuranContentStatePreferences.shared

    private func cutoffChunkIfTruncationNeeded(_ string: String) -> Range<String.Index>? {
        guard let maxUntruncatedIndex = string.index(string.startIndex, offsetBy: Self.maxChunkSize, limitedBy: string.endIndex) else {
            return nil
        }
        let chunkEndIndex = string[..<maxUntruncatedIndex].lastIndex(of: " ") ?? maxUntruncatedIndex
        return string.startIndex ..< chunkEndIndex
    }

    private func expandedChunks(verse: AyahNumber, translation: Translation) -> [Range<String.Index>]? {
        expandedTranslations[verse]?[translation]
    }

    private func expandTranslationIfNeeded(translationId: Translation.ID, sura: Int, ayah: Int) {
        performOnTranslationText(translationId: translationId, sura: sura, ayah: ayah) { ayah, translation, originalString in
            let string: TranslationString
            if translationViewMode == .translationOnly,
               let info = parseCombinedInfo(for: ayah, text: .string(originalString)),
               info.prefixLength > 0 {
                string = originalString.strippingCombinedPrefix(info.prefixLength)
            } else {
                string = originalString
            }
            if let cutoffChunk = cutoffChunkIfTruncationNeeded(string.text) {
                let truncatedChunks = string.text.chunkRanges(range: cutoffChunk.upperBound ..< string.text.endIndex, maxChunkSize: Self.maxChunkSize)
                expandedTranslations[ayah, default: [:]][translation] = [cutoffChunk] + truncatedChunks
            }
        }
    }

    private func setFootnoteIfNeeded(translationId: Translation.ID, sura: Int, ayah: Int, footnoteIndex: Int) {
        performOnTranslationText(translationId: translationId, sura: sura, ayah: ayah) { ayah, translation, string in
            footnote = TranslationFootnote(
                string: string,
                footnoteIndex: footnoteIndex,
                translation: translation,
                translationFontSize: translationFontSize,
                translationFont: translationFont
            )
        }
    }

    private func performOnTranslationText(translationId: Translation.ID, sura: Int, ayah: Int, _ body: (AyahNumber, Translation, TranslationString) -> Void) {
        guard let quran = verses.first?.quran else {
            return
        }
        let ayah = AyahNumber(quran: quran, sura: sura, ayah: ayah)
        let translation = translations.first { $0.id == translationId }
        let translationIndex = translation.flatMap { translations.firstIndex(of: $0) }
        let verseText = ayah.flatMap { ayah in verseTexts[ayah] ?? lookaheadVerseTexts[ayah] }
        if let ayah, let translation, let translationIndex, let verseText {
            if case .string(let string) = verseText.translations[translationIndex] {
                body(ayah, translation, string)
            }
        }
    }

    private func scrollToVerseIfNeededSynchronously() {
        guard let ayah = highlightsService.highlights.firstScrollingVerse() else {
            return
        }

        scrollTriggerCount += 1

        if translationViewMode == .arabicOnly {
            logger.info("Quran Translation: scrollToVerseIfNeeded (continuous) \(ayah)")
            scrollToItem = nil
            return
        }

        for item in items {
            if item.matches(ayah: ayah) {
                logger.info("Quran Translation: scrollToVerseIfNeeded \(ayah)")
                scrollToItem = item.id
                break
            }
        }
    }

    private func scrollToVerseIfNeeded() {
        // Execute in the next runloop to allow the highlightsService value to load.
        DispatchQueue.main.async {
            self.scrollToVerseIfNeededSynchronously()
        }
    }
}
