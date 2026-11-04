//
//  SelectedTranslationsPreferencesTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-21.
//

import XCTest
@testable import TranslationService

class SelectedTranslationsPreferencesTests: XCTestCase {
    // MARK: Internal

    override func tearDown() {
        super.tearDown()
        preferences.reset()
    }

    func testPreferences() {
        preferences.selectedTranslationIds = []
        XCTAssertEqual(preferences.selectedTranslationIds, [])

        preferences.toggleSelection(45)
        XCTAssertEqual(preferences.selectedTranslationIds, [45])
        preferences.toggleSelection(10)
        XCTAssertEqual(preferences.selectedTranslationIds, [10])
        XCTAssertTrue(preferences.isSelected(10))

        preferences.toggleSelection(10)
        XCTAssertEqual(preferences.selectedTranslationIds, [])
        XCTAssertFalse(preferences.isSelected(10))

        preferences.select(20)
        XCTAssertEqual(preferences.selectedTranslationIds, [20])
        preferences.select(10)
        XCTAssertEqual(preferences.selectedTranslationIds, [10])
    }

    // MARK: Private

    private let preferences = SelectedTranslationsPreferences.shared
}
