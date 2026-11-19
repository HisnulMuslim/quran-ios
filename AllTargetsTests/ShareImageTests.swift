//
//  ShareImageTests.swift
//

import NoorFont
import QuranKit
import QuranResources
import QuranText
import SwiftUI
import UIKit
import UIx
import XCTest
@testable import QuranViewFeature

@MainActor
final class ShareImageTests: XCTestCase {
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        FontName.registerFonts()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("share_img_test_\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testFontRegistrationRepeatedCallsAndRenderingAllFontsAndRatios() {
        for _ in 0..<25 {
            FontName.registerFonts()
        }

        let cardData = AyahCardData(
            suraName: "ಅಲ್-ಫಾತಿಹಾ",
            suraNumber: 1,
            ayahRangeString: "೧–೭",
            referenceText: "ಅಲ್-ಫಾತಿಹಾ : ೧–೭",
            arabicText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ١ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ٢",
            translationText: "ಅನಂತ ದಯಾಮಯನೂ ಕರುಣಾಮಯನೂ ಆದ ಅಲ್ಲಾಹನ ನಾಮದಿಂದ.\nಎಲ್ಲ ಪ್ರಶಂಸೆಯೂ ಸಕಲ ಲೋಕಗಳ ಒಡೆಯನಾದ ಅಲ್ಲಾಹನಿಗೆ ಮೀಸಲು.",
            translationTextWithFootnotes: "ಅನಂತ ದಯಾಮಯನೂ ಕರುಣಾಮಯನೂ ಆದ ಅಲ್ಲಾಹನ ನಾಮದಿಂದ.[1]\nಎಲ್ಲ ಪ್ರಶಂಸೆಯೂ ಸಕಲ ಲೋಕಗಳ ಒಡೆಯನಾದ ಅಲ್ಲಾಹನಿಗೆ ಮೀಸಲು.",
            translator: "Hamzah",
            footnotes: ["[1] ಪರಮ ದಯಾಮಯ ಎಂಬ ಅರ್ಥವಿದೆ."],
            ayahSlides: []
        )

        let bgImage = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1080)).image { ctx in
            UIColor.systemTeal.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1080, height: 1080))
        }

        for ratio in AyahCardAspectRatio.allCases {
            for arabicFont in AyahCardArabicFont.allCases {
                let view = AyahShareCardView(
                    data: cardData,
                    theme: arabicFont == .uthmanic ? .customPhoto : .emerald,
                    aspectRatio: ratio,
                    showArabic: true,
                    showTranslation: true,
                    showFootnotes: true,
                    showQRCode: true,
                    showAppURL: true,
                    fontSizeScale: 1.5,
                    textColorScheme: .classicGold,
                    translationTextColorScheme: .pureWhite,
                    arabicFont: arabicFont,
                    translationFont: .notoSerif,
                    photoScale: 1.5,
                    customImage: bgImage,
                    transparentBackground: false,
                    isExport: true
                )
                let image = AyahCardRenderer.render(view: view, targetWidth: 1080, isOpaque: true)
                XCTAssertNotNil(image, "Failed rendering \(ratio.rawValue) with \(arabicFont.rawValue)")
                if let image {
                    XCTAssertEqual(Int(image.size.width * image.scale), 1080)
                    XCTAssertEqual(Int(round(image.size.height * image.scale)), Int(round(ratio.height(for: 1080))))
                    XCTAssertNotNil(image.pngData())
                }
            }
        }
    }

    func testShareViewControllerConfigurationAndSheetInteractionSafety() {
        let quran = Reading.tajweed.quran
        let firstVerse = quran.suras[0].verses[0]

        let shareVC = AyahShareImageViewController(
            verses: [firstVerse],
            databasesURL: tempDir,
            quranFileURL: QuranResources.quranUthmaniV2Database,
            appHost: URL(string: "https://quran-files.hisnulmuslimdua.com/")!,
            isVideoMode: false
        )
        if let sheet = shareVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            XCTAssertFalse(sheet.prefersScrollingExpandsWhenScrolledToEdge)
            XCTAssertEqual(sheet.detents, [.large()])
        }

        shareVC.loadViewIfNeeded()
        shareVC.view.frame = CGRect(x: 0, y: 0, width: 440, height: 956)
        shareVC.view.layoutIfNeeded()
        XCTAssertNotNil(shareVC.view)
    }

    func testShareViewModelLoadRenderAndGuards() async throws {
        let quran = Reading.tajweed.quran
        let verses = Array(quran.suras[0].verses.prefix(3))

        let vm = AyahShareImageViewModel(
            verses: verses,
            databasesURL: tempDir,
            quranFileURL: QuranResources.quranUthmaniV2Database,
            appHost: URL(string: "https://quran-files.hisnulmuslimdua.com/")!,
            isVideoMode: false
        )
        await vm.loadData()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNotNil(vm.cardData)
        XCTAssertEqual(vm.cardData?.suraNumber, 1)

        // Generate export images in all aspect ratios
        for ratio in AyahCardAspectRatio.allCases {
            vm.selectedAspectRatio = ratio
            let exported = vm.generateExportImage()
            XCTAssertNotNil(exported)
            if let exported {
                let url = AyahCardRenderer.saveToTemporaryFile(image: exported, fileName: "test_\(ratio.shortLabel.replacingOccurrences(of: ":", with: "_")).png")
                XCTAssertNotNil(url)
            }
        }

        // Calling share from an unattached view controller must safely no-op and reset isExporting
        let detachedVC = UIViewController()
        vm.share(from: detachedVC, sourceView: nil)
        XCTAssertFalse(vm.isExporting)

        // Cached image check should reflect existence without full JPEG decoding crash
        let fakeItem = RemoteAyahBackgroundItem(
            id: "missing_bg_check",
            name: "Test",
            nameKn: nil,
            nameAr: nil,
            thumbnailUrl: "https://example.com/t.jpg",
            imageUrl: "https://example.com/f.jpg",
            type: "image",
            videoUrl: nil,
            durationSec: nil,
            sizeBytes: nil
        )
        XCTAssertFalse(vm.isPhotoDownloaded(fakeItem))
    }

    func testRemoteCatalogDecodingAndAtomicChecks() throws {
        let json = """
        {
          "version": 8,
          "backgrounds": [
            {
              "id": "bg_test",
              "name": "Test BG",
              "nameKn": "ಟೆಸ್ಟ್",
              "thumbnailUrl": "https://example.com/t.jpg",
              "imageUrl": "https://example.com/f.jpg"
            }
          ],
          "videos": [
            {
              "id": "vid_test",
              "name": "Test Video",
              "thumbnailUrl": "https://example.com/vt.jpg",
              "videoUrl": "https://example.com/v.mp4",
              "durationSec": 10.0
            }
          ]
        }
        """
        let catalog = try JSONDecoder().decode(RemoteAyahBackgroundCatalog.self, from: Data(json.utf8))
        XCTAssertEqual(catalog.backgrounds.count, 1)
        XCTAssertEqual(catalog.videos?.count, 1)
        XCTAssertEqual(catalog.allItems.count, 2)
        XCTAssertFalse(catalog.backgrounds[0].isVideo)
        XCTAssertTrue(catalog.videos?[0].isVideo ?? false)

        // Verify opaque = false video overlay render and canvas guard at 9:16
        let overlayCard = AyahShareCardView(
            data: AyahCardData(
                suraName: "ಅಲ್-ಫಾತಿಹಾ",
                suraNumber: 1,
                ayahRangeString: "1",
                referenceText: "1:1",
                arabicText: "بِسْمِ اللَّهِ ١",
                translationText: "In the name of Allah.",
                translator: nil
            ),
            theme: .emerald,
            aspectRatio: .story,
            photoScale: 2.0,
            transparentBackground: true,
            exportWidth: 720,
            isExport: true
        )
        let overlayImage = AyahCardRenderer.render(view: overlayCard, targetWidth: 720, isOpaque: false)
        XCTAssertNotNil(overlayImage)
        XCTAssertFalse(RemoteBackgroundService.shared.hasCachedImage(for: "non_existent_\(UUID().uuidString)"))

        // Verify opaque corner pixels on image export (square edges, zero rounded corner cutout)
        let squareImageCard = AyahShareCardView(
            data: overlayCard.data,
            theme: .emerald,
            aspectRatio: .square,
            transparentBackground: false,
            exportWidth: 330,
            isExport: true
        )
        let renderedSquare = AyahCardRenderer.render(view: squareImageCard, targetWidth: 330, isOpaque: false)
        XCTAssertNotNil(renderedSquare)
        if let cg = renderedSquare?.cgImage,
           let providerData = cg.dataProvider?.data,
           let bytes = CFDataGetBytePtr(providerData) {
            let alphaInfo = cg.alphaInfo
            let bpp = cg.bitsPerPixel / 8
            if bpp == 4 && (alphaInfo == .premultipliedLast || alphaInfo == .last) {
                XCTAssertEqual(bytes[3], 255)
            } else if bpp == 4 && (alphaInfo == .premultipliedFirst || alphaInfo == .first) {
                XCTAssertEqual(bytes[0], 255)
            }
        }
    }

    func testAdaptiveVideoQualitySelectionForPhonesMacsAndLongDurations() {
        // 4 GB+ iPhone / 8 GB+ Apple Silicon MacBook -> 1080p @ 6.2 Mbps
        let modernProfile = AyahVideoExporter.selectQualityProfile(
            hasVideoBackground: true,
            estimatedDurationSec: 20,
            physicalMemoryBytes: 8_000_000_000
        )
        XCTAssertEqual(modernProfile, AyahVideoQualityProfile(exportWidth: 1080, videoBitrate: 6_200_000))

        // Older < 4 GB device -> 720p @ 4.5 Mbps
        let olderProfile = AyahVideoExporter.selectQualityProfile(
            hasVideoBackground: true,
            estimatedDurationSec: 20,
            physicalMemoryBytes: 2_000_000_000
        )
        XCTAssertEqual(olderProfile, AyahVideoQualityProfile(exportWidth: 720, videoBitrate: 4_500_000))

        // Ultra-long 120s clip stays safely under ~55 MB ceiling by stepping to 720p
        let longClipProfile = AyahVideoExporter.selectQualityProfile(
            hasVideoBackground: true,
            estimatedDurationSec: 120,
            physicalMemoryBytes: 16_000_000_000
        )
        XCTAssertEqual(longClipProfile.exportWidth, 720)
        XCTAssertLessThan(longClipProfile.videoBitrate, 3_600_000)

        // Photo/solid background always stays 1080p unless explicitly set to Standard 720p
        let staticProfile = AyahVideoExporter.selectQualityProfile(
            hasVideoBackground: false,
            estimatedDurationSec: 20,
            physicalMemoryBytes: 2_000_000_000
        )
        XCTAssertEqual(staticProfile, AyahVideoQualityProfile(exportWidth: 1080, videoBitrate: 2_400_000))

        // Explicit 2-choice override: Standard 720p vs High 1080p
        let forced720p = AyahVideoExporter.selectQualityProfile(
            hasVideoBackground: true,
            estimatedDurationSec: 20,
            physicalMemoryBytes: 16_000_000_000,
            preferredQuality: .standard720p
        )
        XCTAssertEqual(forced720p, AyahVideoQualityProfile(exportWidth: 720, videoBitrate: 4_500_000))

        let forced1080p = AyahVideoExporter.selectQualityProfile(
            hasVideoBackground: true,
            estimatedDurationSec: 20,
            physicalMemoryBytes: 2_000_000_000,
            preferredQuality: .high1080p
        )
        XCTAssertEqual(forced1080p, AyahVideoQualityProfile(exportWidth: 1080, videoBitrate: 6_200_000))

        // HD catalog metadata & formatted size label
        let hdItem = RemoteAyahBackgroundItem(
            id: "hd_clip",
            name: "HD Mosque",
            thumbnailUrl: "https://example.com/t.jpg",
            videoUrl: "https://example.com/v_hd.mp4",
            sizeBytes: 5_400_000,
            resolution: "1080p"
        )
        let sdItem = RemoteAyahBackgroundItem(
            id: "sd_clip",
            name: "Clouds",
            thumbnailUrl: "https://example.com/t2.jpg",
            videoUrl: "https://example.com/v.mp4",
            sizeBytes: 2_680_000
        )
        XCTAssertTrue(hdItem.isHdVideo)
        XCTAssertEqual(hdItem.formattedSizeLabel, "5.4 MB")
        XCTAssertFalse(sdItem.isHdVideo)
        XCTAssertEqual(sdItem.formattedSizeLabel, "2.7 MB")
    }
}
