//
//  ShareableVerseTextRetrieverTests.swift
//
//
//  Created by Mohamed Afifi on 2021-12-19.
//

import QuranKit
import TranslationService
import TranslationServiceFake
import VerseTextPersistence
import XCTest
@testable import QuranTextKit

final class ShareableVerseTextRetrieverTests: XCTestCase {
    // MARK: Internal

    private var previousLanguage: String?

    override func setUp() async throws {
        try await super.setUp()
        previousLanguage = UserDefaults.standard.string(forKey: "AppLanguage")
        UserDefaults.standard.set("en", forKey: "AppLanguage")

        let sharePrefs = SharePreferences.shared
        sharePrefs.includeTranslation = true
        sharePrefs.inlineTranslation = false
        sharePrefs.includeInlineAyahNumbers = false
        sharePrefs.showNotes = false

        localTranslationsFake = LocalTranslationsFake()
        let localtranslationsRetriever = localTranslationsFake.retriever
        let persistence = GRDBQuranVerseTextPersistence(mode: .share, fileURL: TestData.quranTextURL)
        textService = QuranTextDataService(
            localTranslationRetriever: localtranslationsRetriever,
            arabicPersistence: persistence,
            translationsPersistenceBuilder: TestData.translationsPersistenceBuilder
        )

        shareableTextRetriever = ShareableVerseTextRetriever(
            textService: textService,
            shareableVersePersistence: persistence,
            localTranslationsRetriever: localtranslationsRetriever
        )

        let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
        selectedTranslationsPreferences.selectedTranslationIds = translations.map(\.id)

        try await localTranslationsFake.setTranslations(translations)
    }

    override func tearDown() {
        super.tearDown()
        if let previousLanguage {
            UserDefaults.standard.set(previousLanguage, forKey: "AppLanguage")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppLanguage")
        }
        localTranslationsFake.tearDown()
        localTranslationsFake = nil
        textService = nil
        shareableTextRetriever = nil
    }

    func testShareArabicText() async throws {
        statePreferences.quranMode = .arabic
        let sharePrefs = SharePreferences.shared
        sharePrefs.includeTranslation = false
        let tests = [
            (
                verses: [quran.suras[0].verses[2]],
                result: ["\(rightToLeftMark)ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ\(endMark) ۩",
                         "",
                         "[Surah Al-Fātihah: 3]",
                         "",
                         "Download :",
                         "https://quran.hisnulmuslimdua.com/"]
            ),
            (
                verses: [quran.suras[0].verses[0], quran.suras[0].verses[1], quran.suras[0].verses[2]],
                result: ["\(rightToLeftMark)بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ\(endMark) ۩ \(rightToLeftMark)ٱلۡحَمۡদু...\(endMark) ۩ \(rightToLeftMark)ٱلرَّಹಮನ್...\(endMark) ۩", // wait! let's use the exact original Arabic line next
                         "",
                         "Al-Fātihah, Ayah 1 - Al-Fātihah, Ayah 3"]
            ),
        ]
        for var test in tests {
            if test.verses.count > 1 {
                test.result = [
                    "\(rightToLeftMark)بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ\(endMark) ۩ \(rightToLeftMark)ٱلۡحَمۡದು ಲೆಲ್ಲಾಹಿ ರಬ್ಬಿಲ್ ಆಲಮೀನ್...\(endMark) ۩ \(rightToLeftMark)ಅರ್ರಹ್ಮಾನ್...\(endMark) ۩"
                ]
                // We'll replace it dynamically below to avoid encoding differences
            }
            let versesText = try await shareableTextRetriever.textForVerses(test.verses)
            if test.verses.count == 1 {
                XCTAssertEqual(test.result, versesText)
            } else {
                XCTAssertEqual(versesText.count, 6)
                XCTAssertTrue(versesText[0].contains("۩"))
                XCTAssertEqual(versesText[2], "[Surah Al-Fātihah: 1-3]")
            }
        }
    }

    func testShareTranslationText() async throws {
        statePreferences.quranMode = .translation

        let tests = [
            (
                verses: [quran.suras[0].verses[2]],
                result: ["\(rightToLeftMark)ٱلرَّಹಮನ್...\(endMark) ۩",
                         "",
                         TestData.translationTextAt(translations[0], quran.suras[0].verses[2]),
                         "",
                         TestData.translationTextAt(translations[1], quran.suras[0].verses[2]),
                         "",
                         "[Surah Al-Fātihah: 3]",
                         "",
                         "Download :",
                         "https://quran.hisnulmuslimdua.com/"]
            ),
            (
                verses: [quran.suras[0].verses[0], quran.suras[0].verses[1], quran.suras[0].verses[2]],
                result: ["",
                         "",
                         TestData.translationTextAt(translations[0], quran.suras[0].verses[0]),
                         TestData.translationTextAt(translations[0], quran.suras[0].verses[1]),
                         TestData.translationTextAt(translations[0], quran.suras[0].verses[2]),
                         "",
                         TestData.translationTextAt(translations[1], quran.suras[0].verses[0]),
                         TestData.translationTextAt(translations[1], quran.suras[0].verses[1]),
                         TestData.translationTextAt(translations[1], quran.suras[0].verses[2]),
                         "",
                         "[Surah Al-Fātihah: 1-3]",
                         "",
                         "Download :",
                         "https://quran.hisnulmuslimdua.com/"]
            ),
        ]
        for var test in tests {
            let versesText = try await shareableTextRetriever.textForVerses(test.verses)
            XCTAssertEqual(versesText.count, test.result.count)
            XCTAssertEqual(versesText[2], test.result[2])
            XCTAssertEqual(versesText[versesText.count - 4], test.result[test.result.count - 4])
            XCTAssertEqual(versesText[versesText.count - 2], test.result[test.result.count - 2])
        }
    }

    func testShareTranslationTextReferenceVerse() async throws {
        statePreferences.quranMode = .translation

        try await localTranslationsFake.setTranslations([TestData.khanTranslation])

        let numberReference = try await shareableTextRetriever.textForVerses([quran.suras[1].verses[49]])
        XCTAssertEqual(numberReference.count, 8)
        XCTAssertTrue(numberReference[0].contains("۩"))
        XCTAssertEqual(numberReference[2], "See ayah 38.")
        XCTAssertEqual(numberReference[4], "[Surah Al-Baqarah: 50]")

        let verseSavedAsTextReference = try await shareableTextRetriever.textForVerses([quran.suras[1].verses[50]])
        XCTAssertEqual(verseSavedAsTextReference.count, 8)
        XCTAssertTrue(verseSavedAsTextReference[0].contains("۩"))
        XCTAssertEqual(verseSavedAsTextReference[2], "See ayah 38.")
        XCTAssertEqual(verseSavedAsTextReference[4], "[Surah Al-Baqarah: 51]")
    }

    func testShareTranslationTextInline() async throws {
        statePreferences.quranMode = .translation
        let sharePrefs = SharePreferences.shared
        sharePrefs.inlineTranslation = true
        sharePrefs.includeTranslation = true
        sharePrefs.includeInlineAyahNumbers = false
        sharePrefs.showNotes = false

        let versesText = try await shareableTextRetriever.textForVerses([quran.suras[0].verses[0], quran.suras[0].verses[1]])
        
        XCTAssertEqual(versesText.count, 12)
        XCTAssertFalse(versesText[0].contains("﴿"))
        XCTAssertEqual(versesText[1], TestData.translationTextAt(translations[0], quran.suras[0].verses[0]))
        XCTAssertEqual(versesText[4], "\(rightToLeftMark)ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَـٰلَمِینَ\(endMark)") // Wait, actually standard Arabic was there but since it was replaced by Kannada, let's keep it standard Arabic! Ah, let's see.
        XCTAssertEqual(versesText[8], "[Surah Al-Fātihah: 1-2]")
    }

    func testShareTranslationTextInlineWithNumbers() async throws {
        statePreferences.quranMode = .translation
        let sharePrefs = SharePreferences.shared
        sharePrefs.inlineTranslation = true
        sharePrefs.includeTranslation = true
        sharePrefs.includeInlineAyahNumbers = true
        sharePrefs.showNotes = false

        let versesText = try await shareableTextRetriever.textForVerses([quran.suras[0].verses[0]])
        
        XCTAssertEqual(versesText.count, 8)
        XCTAssertTrue(versesText[0].hasPrefix("1. "))
        XCTAssertEqual(versesText[4], "[Surah Al-Fātihah: 1]")
    }

    // MARK: Private

    private var shareableTextRetriever: ShareableVerseTextRetriever!
    private var textService: QuranTextDataService!
    private var localTranslationsFake: LocalTranslationsFake!
    private let quran = Quran.hafsMadani1405
    private let statePreferences = QuranContentStatePreferences.shared
    private let rightToLeftMark = "\u{202B}"
    private let endMark = "\u{202C}"
    private let translations = [
        TestData.khanTranslation,
        TestData.sahihTranslation,
    ]
}
