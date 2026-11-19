//
//  ReadingTests.swift
//

import XCTest
@testable import QuranKit

final class ReadingTests: XCTestCase {
    func testPreservesHueInDarkMode() {
        XCTAssertTrue(Reading.tajweed.preservesHueInDarkMode)
        XCTAssertFalse(Reading.hafs_1405.preservesHueInDarkMode)
        XCTAssertFalse(Reading.hafs_1421.preservesHueInDarkMode)
        XCTAssertFalse(Reading.hafs_1439.preservesHueInDarkMode)
        XCTAssertFalse(Reading.hafs_1440.preservesHueInDarkMode)
        XCTAssertFalse(Reading.hafs_1441.preservesHueInDarkMode)
    }

    func testUsesInvertedQuranImageRenderingInDarkMode() {
        XCTAssertTrue(Reading.tajweed.usesInvertedQuranImageRenderingInDarkMode)
        XCTAssertTrue(Reading.hafs_1440.usesInvertedQuranImageRenderingInDarkMode)
        XCTAssertTrue(Reading.hafs_1439.usesInvertedQuranImageRenderingInDarkMode)
        XCTAssertTrue(Reading.hafs_1441.usesInvertedQuranImageRenderingInDarkMode)
        XCTAssertFalse(Reading.hafs_1405.usesInvertedQuranImageRenderingInDarkMode)
        XCTAssertFalse(Reading.hafs_1421.usesInvertedQuranImageRenderingInDarkMode)
    }
}
