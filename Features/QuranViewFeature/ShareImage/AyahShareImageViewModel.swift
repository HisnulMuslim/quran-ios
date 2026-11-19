//
//  AyahShareImageViewModel.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import AVFoundation
import Combine
import Foundation
import Localization
import Photos
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
    @Published public var selectedAspectRatio: AyahCardAspectRatio = .story
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

    // Video Mode & Sync State
    public let isVideoMode: Bool
    @Published public var backgroundMode: Int = 1 // 0 = Colors, 1 = Photos, 2 = Videos
    @Published public var availableReciters: [AyahReciterOption] = []
    @Published public var selectedReciterId: Int? = nil
    @Published public var syncAyahWithAudio: Bool = false
    @Published public var videoExportQuality: AyahVideoExportQuality = .high1080p
    @Published public var activePreviewSlideIndex: Int = 0
    @Published public var catalogItems: [RemoteAyahBackgroundItem] = []
    @Published public var selectedRemotePhotoItem: RemoteAyahBackgroundItem? = nil
    @Published public var isDownloadingBackgroundPhoto: Bool = false
    @Published public var selectedRemoteVideoItem: RemoteAyahBackgroundItem? = nil
    @Published public var selectedBackgroundVideoURL: URL? = nil
    @Published public var isDownloadingBackgroundVideo: Bool = false
    @Published public var exportProgress: AyahVideoProgress? = nil
    @Published public var isExporting: Bool = false
    @Published public var isLoadingAudioPreview: Bool = false
    @Published public var isPlayingAudioPreview: Bool = false
    @Published public var errorAlertMessage: String? = nil
    private var photoDownloadTask: Task<Void, Never>? = nil

    public var isLiveVideoBackground: Bool {
        isVideoMode && backgroundMode == 2 && selectedBackgroundVideoURL != nil
    }

    public var selectedReciterName: String? {
        availableReciters.first(where: { $0.id == selectedReciterId })?.name ?? availableReciters.first?.name
    }

    public var photoCatalogItems: [RemoteAyahBackgroundItem] {
        catalogItems.filter { !$0.isVideo }
    }

    public var videoCatalogItems: [RemoteAyahBackgroundItem] {
        catalogItems.filter { $0.isVideo }
    }

    public var downloadedPhotoCatalogItems: [RemoteAyahBackgroundItem] {
        let _ = (customBackgroundImage, isDownloadingBackgroundPhoto)
        return photoCatalogItems.filter { isPhotoDownloaded($0) }
    }

    public var downloadedVideoCatalogItems: [RemoteAyahBackgroundItem] {
        let _ = (selectedBackgroundVideoURL, isDownloadingBackgroundVideo)
        return videoCatalogItems.filter { isVideoDownloaded($0) }
    }

    /// Shows all downloaded photos plus up to 4 curated starter cloud photo thumbnails when fewer than 4 are downloaded.
    public var inlinePhotoCatalogItems: [RemoteAyahBackgroundItem] {
        inlineStarterItems(downloaded: downloadedPhotoCatalogItems, all: photoCatalogItems)
    }

    /// Shows all downloaded videos plus up to 4 curated starter video thumbnails when fewer than 4 are downloaded.
    public var inlineVideoCatalogItems: [RemoteAyahBackgroundItem] {
        inlineStarterItems(downloaded: downloadedVideoCatalogItems, all: videoCatalogItems)
    }

    private func inlineStarterItems(
        downloaded: [RemoteAyahBackgroundItem],
        all: [RemoteAyahBackgroundItem]
    ) -> [RemoteAyahBackgroundItem] {
        let minimumInlineCount = 4
        guard downloaded.count < minimumInlineCount else {
            return downloaded
        }
        let downloadedIds = Set(downloaded.map(\.id))
        let starters = all.filter { !downloadedIds.contains($0.id) }
            .prefix(minimumInlineCount - downloaded.count)
        return downloaded + starters
    }

    public func isPhotoDownloaded(_ item: RemoteAyahBackgroundItem) -> Bool {
        RemoteBackgroundService.shared.hasCachedImage(for: item.id)
    }

    public func isVideoDownloaded(_ item: RemoteAyahBackgroundItem) -> Bool {
        RemoteBackgroundService.shared.cachedVideoURL(for: item.id) != nil
    }

    public var displayedCardData: AyahCardData? {
        guard let data = cardData else { return nil }
        if isVideoMode && syncAyahWithAudio && data.ayahSlides.count > 1,
           data.ayahSlides.indices.contains(activePreviewSlideIndex) {
            return data.ayahSlides[activePreviewSlideIndex].toCardData(translator: data.translator)
        }
        return data
    }

    public let verses: [AyahNumber]
    private let databasesURL: URL
    private let quranFileURL: URL
    private let appHost: URL
    private let textService: QuranTextDataService
    private let localTranslationsRetriever: LocalTranslationsRetriever
    private let videoExporter: AyahVideoExporter

    private var previewPlayer: AVPlayer?
    private var previewTimeObserver: Any?
    private var previewEndObserver: NSObjectProtocol?

    public init(
        verses: [AyahNumber],
        databasesURL: URL,
        quranFileURL: URL,
        appHost: URL = URL(string: "https://quran-files.hisnulmuslimdua.com/")!,
        isVideoMode: Bool = false
    ) {
        self.verses = verses
        self.databasesURL = databasesURL
        self.quranFileURL = quranFileURL
        self.appHost = appHost
        self.isVideoMode = isVideoMode
        self.backgroundMode = isVideoMode ? 2 : 1
        let defaultProfile = AyahVideoExporter.selectQualityProfile(hasVideoBackground: true)
        self.videoExportQuality = defaultProfile.exportWidth >= 1080 ? .high1080p : .standard720p
        self.textService = QuranTextDataService(databasesURL: databasesURL, quranFileURL: quranFileURL)
        self.localTranslationsRetriever = LocalTranslationsRetriever(databasesURL: databasesURL)
        self.videoExporter = AyahVideoExporter(appHost: appHost)
    }

    public func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let localTranslations = try await localTranslationsRetriever.getLocalTranslations()
            let selectedTrans = SelectedTranslationsPreferences.shared.selectedTranslations(from: localTranslations)
            let versesTexts = try await textService.textForVerses(verses, translations: selectedTrans)

            guard let firstVerse = verses.first else { return }

            let suraName = firstVerse.sura.localizedName(language: AppLanguage)
            let suraNumber = firstVerse.sura.suraNumber

            let ayahRangeString: String
            let referenceText: String
            if verses.count == 1 {
                let ayahFormatted = AppLanguage == .kannada ? NumberFormatter.shared.format(firstVerse.ayah) : "\(firstVerse.ayah)"
                ayahRangeString = ayahFormatted
                referenceText = lChoice(
                    kn: "\(suraName) : \(ayahFormatted)",
                    en: "Surah \(suraName): \(ayahFormatted)",
                    ar: "\(suraName) : \(ayahFormatted)"
                )
            } else {
                let lastVerse = verses.last ?? firstVerse
                let startFormatted = AppLanguage == .kannada ? NumberFormatter.shared.format(firstVerse.ayah) : "\(firstVerse.ayah)"
                let endFormatted = AppLanguage == .kannada ? NumberFormatter.shared.format(lastVerse.ayah) : "\(lastVerse.ayah)"
                ayahRangeString = "\(startFormatted)–\(endFormatted)"
                referenceText = lChoice(
                    kn: "\(suraName) : \(startFormatted)–\(endFormatted)",
                    en: "Surah \(suraName): \(startFormatted)–\(endFormatted)",
                    ar: "\(suraName) : \(startFormatted)–\(endFormatted)"
                )
            }

            // Combine Arabic texts with numbered ayah markers
            let arabicLines = verses.compactMap { verse -> String? in
                guard let text = versesTexts[verse]?.arabicText.trimmingCharacters(in: .whitespacesAndNewlines),
                      !text.isEmpty else { return nil }
                return "\(text)\u{00A0}\(Self.arabicIndicNumber(verse.ayah))"
            }
            let arabicCombined = arabicLines.joined(separator: " ")

            // Combine Translation texts, footnotes, and per-ayah slides for synced video export
            var translationLines: [String] = []
            var translationWithFootnoteLines: [String] = []
            var extractedFootnotes: [String] = []
            var slides: [AyahSlideData] = []

            for verse in verses {
                var slideTranslation = ""
                var slideWithFootnotes: String? = nil
                var slideNotes: [String] = []

                if let verseText = versesTexts[verse], let firstTrans = verseText.translations.first {
                    let clean = cleanTranslationText(firstTrans)
                    if !clean.isEmpty {
                        translationLines.append(clean)
                        slideTranslation = clean
                    }
                    let startIndex = extractedFootnotes.count + 1
                    let withNotes = buildTranslationTextWithFootnotes(firstTrans, startingNumber: startIndex)
                    if !withNotes.isEmpty {
                        translationWithFootnoteLines.append(withNotes)
                    }
                    let slideWithNotes = buildTranslationTextWithFootnotes(firstTrans, startingNumber: 1)
                    if !slideWithNotes.isEmpty {
                        slideWithFootnotes = slideWithNotes
                    }
                    if case .string(let translationString) = firstTrans {
                        for fn in translationString.footnotes {
                            let cleanFn = cleanFootnoteString(String(fn))
                            if !cleanFn.isEmpty {
                                extractedFootnotes.append(cleanFn)
                                slideNotes.append(cleanFn)
                            }
                        }
                    }
                }

                let verseArabicRaw = versesTexts[verse]?.arabicText.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let verseArabic = verseArabicRaw.isEmpty ? "" : "\(verseArabicRaw)\u{00A0}\(Self.arabicIndicNumber(verse.ayah))"
                let verseSuraName = verse.sura.localizedName(language: AppLanguage)
                let verseNumStr = AppLanguage == .kannada ? NumberFormatter.shared.format(verse.ayah) : "\(verse.ayah)"
                let verseRef = lChoice(
                    kn: "\(verseSuraName) : \(verseNumStr)",
                    en: "Surah \(verseSuraName): \(verseNumStr)",
                    ar: "\(verseSuraName) : \(verseNumStr)"
                )
                slides.append(
                    AyahSlideData(
                        suraNumber: verse.sura.suraNumber,
                        ayahNumber: verse.ayah,
                        suraName: verseSuraName,
                        ayahRangeString: verseNumStr,
                        referenceText: verseRef,
                        arabicText: verseArabic,
                        translationText: slideTranslation,
                        translationTextWithFootnotes: slideWithFootnotes,
                        footnotes: slideNotes.isEmpty ? nil : slideNotes
                    )
                )
            }
            let translationCombined = translationLines.joined(separator: "\n")
            let translationWithFootnotesCombined = translationWithFootnoteLines.joined(separator: "\n")
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
                translationTextWithFootnotes: translationWithFootnotesCombined,
                translator: translatorName,
                footnotes: footnotesList,
                ayahSlides: slides
            )
            self.syncAyahWithAudio = isVideoMode && slides.count > 1

            if let cachedCatalog = RemoteBackgroundService.shared.cachedCatalog() {
                self.catalogItems = cachedCatalog
            }

            if isVideoMode {
                let reciters = await videoExporter.getAvailableReciters()
                self.availableReciters = reciters
                if self.selectedReciterId == nil {
                    self.selectedReciterId = videoExporter.getDefaultReciterId(from: reciters)
                }
                if self.backgroundMode == 2 && self.selectedRemoteVideoItem == nil,
                   let targetVideo = self.downloadedVideoCatalogItems.first ?? self.videoCatalogItems.first {
                    self.selectRemoteVideo(targetVideo)
                }
            } else if self.backgroundMode == 1 && self.selectedRemotePhotoItem == nil && self.customBackgroundImage == nil,
                      let targetPhoto = self.downloadedPhotoCatalogItems.first ?? self.photoCatalogItems.first {
                self.selectRemotePhoto(targetPhoto)
            }

            Task { [weak self] in
                if let latest = try? await RemoteBackgroundService.shared.fetchCatalog() {
                    await MainActor.run {
                        guard let self else { return }
                        self.catalogItems = latest
                        if self.backgroundMode == 1 && self.selectedRemotePhotoItem == nil && self.customBackgroundImage == nil,
                           let targetPhoto = self.downloadedPhotoCatalogItems.first ?? self.photoCatalogItems.first {
                            self.selectRemotePhoto(targetPhoto)
                        } else if self.isVideoMode && self.backgroundMode == 2 && self.selectedRemoteVideoItem == nil,
                                  let targetVideo = self.downloadedVideoCatalogItems.first ?? self.videoCatalogItems.first {
                            self.selectRemoteVideo(targetVideo)
                        }
                    }
                }
            }
        } catch {
            logger.error("AyahShareImageViewModel: Failed to load verses data: \(error)")
        }
    }

    // MARK: - Cloud Photo & Video Selection & Audio Preview

    public func applyDownloadedRemotePhoto(_ item: RemoteAyahBackgroundItem, image: UIImage) {
        photoDownloadTask?.cancel()
        isDownloadingBackgroundPhoto = false
        selectedRemotePhotoItem = item
        customBackgroundImage = image
        selectedTheme = .customPhoto
        if backgroundMode != 1 {
            backgroundMode = 1
        }
    }

    public func selectRemotePhoto(_ item: RemoteAyahBackgroundItem) {
        photoDownloadTask?.cancel()
        selectedRemotePhotoItem = item
        selectedTheme = .customPhoto
        backgroundMode = 1

        if let cached = RemoteBackgroundService.shared.cachedImage(for: item.id) {
            customBackgroundImage = cached
            isDownloadingBackgroundPhoto = false
            return
        }

        customBackgroundImage = nil
        isDownloadingBackgroundPhoto = true
        photoDownloadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let image = try await RemoteBackgroundService.shared.downloadAndCacheImage(for: item)
                guard !Task.isCancelled, self.selectedRemotePhotoItem?.id == item.id else { return }
                self.customBackgroundImage = image
            } catch is CancellationError {
                return
            } catch {
                guard self.selectedRemotePhotoItem?.id == item.id else { return }
                self.selectedRemotePhotoItem = nil
                if self.customBackgroundImage == nil && self.selectedTheme.isPhoto {
                    self.selectedTheme = .emerald
                }
                self.errorAlertMessage = lChoice(
                    kn: "ಈ ಹಿನ್ನೆಲೆ ಚಿತ್ರವನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡಲು ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕದ ಅಗತ್ಯವಿದೆ.",
                    en: "An active internet connection is required to download this background photo.",
                    ar: "يلزم توفر اتصال نشط بالإنترنت لتنزيل صورة الخلفية."
                )
            }
            if self.selectedRemotePhotoItem?.id == item.id {
                self.isDownloadingBackgroundPhoto = false
            }
        }
    }

    public func selectRemoteVideo(_ item: RemoteAyahBackgroundItem) {
        selectedRemoteVideoItem = item
        backgroundMode = 2

        if let cached = RemoteBackgroundService.shared.cachedVideoURL(for: item.id) {
            selectedBackgroundVideoURL = cached
            return
        }

        selectedBackgroundVideoURL = nil
        isDownloadingBackgroundVideo = true
        let downloadingLabel = lChoice(
            kn: "ಹಿನ್ನೆಲೆ ವೀಡಿಯೊ ಡೌನ್‌ಲೋಡ್ ಆಗುತ್ತಿದೆ...",
            en: "Downloading background video...",
            ar: "جارٍ تنزيل فيديو الخلفية..."
        )
        exportProgress = AyahVideoProgress(message: downloadingLabel, percent: 0)

        Task {
            do {
                let url = try await RemoteBackgroundService.shared.downloadAndCacheVideo(for: item) { pct in
                    Task { @MainActor [weak self] in
                        self?.exportProgress = AyahVideoProgress(message: downloadingLabel, percent: pct)
                    }
                }
                if selectedRemoteVideoItem?.id == item.id {
                    selectedBackgroundVideoURL = url
                }
            } catch {
                if selectedRemoteVideoItem?.id == item.id {
                    selectedRemoteVideoItem = nil
                }
                errorAlertMessage = lChoice(
                    kn: "ಈ ಹಿನ್ನೆಲೆ ವೀಡಿಯೊವನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡಲು ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕದ ಅಗತ್ಯವಿದೆ.",
                    en: "An active internet connection is required to download this background video.",
                    ar: "يلزم توفر اتصال نشط بالإنترنت لتنزيل فيديو الخلفية."
                )
            }
            isDownloadingBackgroundVideo = false
            if !isExporting && !isLoadingAudioPreview {
                exportProgress = nil
            }
        }
    }

    public func onBackgroundModeChanged(_ newMode: Int) {
        backgroundMode = newMode
        if newMode == 1 {
            selectedTheme = .customPhoto
            if let existing = selectedRemotePhotoItem {
                if customBackgroundImage == nil {
                    selectRemotePhoto(existing)
                }
            } else if let targetPhoto = downloadedPhotoCatalogItems.first ?? photoCatalogItems.first {
                selectRemotePhoto(targetPhoto)
            }
        } else if newMode == 0 && selectedTheme.isPhoto {
            selectedTheme = .emerald
        } else if newMode == 2 && isVideoMode {
            if let existing = selectedRemoteVideoItem {
                selectRemoteVideo(existing)
            } else if let targetVideo = downloadedVideoCatalogItems.first ?? videoCatalogItems.first {
                selectRemoteVideo(targetVideo)
            }
        }
    }

    public func toggleAudioPreview() {
        if isPlayingAudioPreview {
            stopAudioPreview()
            return
        }
        if isLoadingAudioPreview { return }

        isLoadingAudioPreview = true
        exportProgress = AyahVideoProgress(
            message: lChoice(kn: "ಆಡಿಯೋ ಲೋಡ್ ಆಗುತ್ತಿದೆ...", en: "Loading audio...", ar: "جارٍ تحميل التلاوة...")
        )

        Task {
            do {
                let segment = try await videoExporter.resolveAudio(
                    for: verses,
                    reciterId: selectedReciterId
                ) { [weak self] progress in
                    self?.exportProgress = progress
                }
                let session = try await videoExporter.buildPreviewSession(from: segment)
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)

                stopAudioPreview()
                let player = AVPlayer(playerItem: session.playerItem)
                self.previewPlayer = player

                let cues = session.cues
                let slideCount = cardData?.ayahSlides.count ?? 0
                let interval = CMTime(seconds: 0.08, preferredTimescale: 600)
                previewTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                    guard let self, self.syncAyahWithAudio, cues.count == slideCount, slideCount > 1 else { return }
                    let sec = CMTimeGetSeconds(time)
                    if let matchedIdx = cues.lastIndex(where: { sec >= $0.relativeStartSec }) {
                        if self.activePreviewSlideIndex != matchedIdx {
                            self.activePreviewSlideIndex = matchedIdx
                        }
                    }
                }

                previewEndObserver = NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: session.playerItem,
                    queue: .main
                ) { [weak self] _ in
                    self?.stopAudioPreview()
                }

                isLoadingAudioPreview = false
                exportProgress = nil
                isPlayingAudioPreview = true
                activePreviewSlideIndex = 0
                player.play()
            } catch {
                isLoadingAudioPreview = false
                exportProgress = nil
                errorAlertMessage = error.localizedDescription
            }
        }
    }

    public func stopAudioPreview() {
        if let observer = previewTimeObserver, let player = previewPlayer {
            player.removeTimeObserver(observer)
        }
        previewTimeObserver = nil
        if let endObs = previewEndObserver {
            NotificationCenter.default.removeObserver(endObs)
        }
        previewEndObserver = nil
        previewPlayer?.pause()
        previewPlayer = nil
        isPlayingAudioPreview = false
        activePreviewSlideIndex = 0
    }

    public func generateExportImage(
        data overrideData: AyahCardData? = nil,
        targetWidth: CGFloat = 1080,
        transparentBackground: Bool = false
    ) -> UIImage? {
        guard let data = overrideData ?? cardData else { return nil }
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
            transparentBackground: transparentBackground,
            exportWidth: targetWidth,
            isExport: true
        )
        return AyahCardRenderer.render(view: exportCard, targetWidth: targetWidth, isOpaque: !transparentBackground)
    }

    public func buildShortCompanionShareCaption() -> String {
        "https://quran.hisnulmuslimdua.com/"
    }

    public func buildCompanionShareCaption() -> String {
        var parts: [String] = []

        if let ref = cardData?.referenceText {
            parts.append("📖 \(ref)")
        }

        if showArabic, let arabic = cardData?.arabicText, !arabic.isEmpty {
            parts.append(arabic)
        }

        if showTranslation {
            let transText = (showFootnotes ? cardData?.translationTextWithFootnotes : nil) ?? cardData?.translationText
            if let trans = transText, !trans.isEmpty {
                parts.append(trans)
            }
        }

        if showFootnotes, let notes = cardData?.footnotes, !notes.isEmpty {
            let header = lChoice(kn: "ಟಿಪ್ಪಣಿಗಳು:", en: "Footnotes:", ar: "الحواشي:")
            let notesFormatted = notes.enumerated().map { "[\($0.offset + 1)] \($0.element)" }.joined(separator: "\n")
            parts.append("\(header)\n\(notesFormatted)")
        }

        parts.append("https://quran.hisnulmuslimdua.com/")
        return parts.joined(separator: "\n\n")
    }

    private func companionShareItems() -> [Any] {
        switch captionMode {
        case .imageOnly:
            return []
        case .linkOnly:
            let shortCaption = buildShortCompanionShareCaption()
            return shortCaption.isEmpty ? [] : [shortCaption]
        case .fullText:
            let fullCaption = buildCompanionShareCaption()
            return fullCaption.isEmpty ? [] : [fullCaption]
        }
    }

    private func asciiShareFileName() -> String {
        let suraNum = cardData?.suraNumber ?? verses.first?.sura.suraNumber ?? 1
        let startAyah = verses.first?.ayah ?? 1
        let endAyah = verses.last?.ayah ?? startAyah
        let rangeToken = verses.count > 1 ? "\(startAyah)-\(endAyah)" : "\(startAyah)"
        return "kannada_quran_\(suraNum)_\(rangeToken).png"
    }

    private func presentActivityController(
        items: [Any],
        from viewController: UIViewController,
        sourceView: UIView?,
        onPresented: (() -> Void)? = nil
    ) {
        guard !items.isEmpty,
              !viewController.isBeingDismissed,
              !viewController.isBeingPresented,
              viewController.viewIfLoaded?.window != nil else {
            onPresented?()
            return
        }

        // Resolve deepest active presenter in case another sheet is already above viewController.
        var presenter = viewController
        while let child = presenter.presentedViewController {
            if child.isBeingDismissed || child is UIAlertController || child is UIActivityViewController {
                onPresented?()
                return
            }
            presenter = child
        }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            let anchorView = sourceView ?? presenter.view
            popover.sourceView = anchorView
            let anchorRect = sourceView?.bounds ?? CGRect(
                x: anchorView?.bounds.midX ?? 0,
                y: anchorView?.bounds.midY ?? 0,
                width: 1,
                height: 1
            )
            popover.sourceRect = anchorRect
        }
        presenter.present(activityVC, animated: true) {
            onPresented?()
        }
    }

    public func share(from viewController: UIViewController, sourceView: UIView?) {
        if isVideoMode {
            shareVideo(from: viewController, sourceView: sourceView)
            return
        }
        guard !isExporting else { return }
        isExporting = true
        guard let image = generateExportImage() else {
            isExporting = false
            return
        }

        var items: [Any] = []
        if let fileURL = AyahCardRenderer.saveToTemporaryFile(image: image, fileName: asciiShareFileName()) {
            items.append(fileURL)
        } else {
            items.append(image)
        }
        items.append(contentsOf: companionShareItems())

        presentActivityController(items: items, from: viewController, sourceView: sourceView) { [weak self] in
            self?.isExporting = false
        }
    }

    private func shareVideo(from viewController: UIViewController, sourceView: UIView?) {
        guard !isExporting else { return }
        stopAudioPreview()
        isExporting = true
        exportProgress = AyahVideoProgress(
            message: lChoice(kn: "ತಯಾರಿಸಲಾಗುತ್ತಿದೆ...", en: "Preparing...", ar: "جارٍ التحضير...")
        )

        Task {
            do {
                let outURL = try await exportCurrentVideo()
                var items: [Any] = [outURL]
                items.append(contentsOf: companionShareItems())
                isExporting = false
                exportProgress = nil

                presentActivityController(items: items, from: viewController, sourceView: sourceView)
            } catch {
                logger.error("AyahShareImageViewModel: Video share failed: \(error)")
                isExporting = false
                exportProgress = nil
                errorAlertMessage = error.localizedDescription
            }
        }
    }

    private func ensurePhotoAddAuthorization(deniedMessage: String) async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            errorAlertMessage = deniedMessage
            return false
        }
        return true
    }

    private func showSavedToast(_ message: String) {
        saveSuccessToast = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            if self?.saveSuccessToast == message {
                self?.saveSuccessToast = nil
            }
        }
    }

    public func saveToPhotos() {
        if isVideoMode {
            saveVideoToPhotos()
            return
        }
        guard !isExporting else { return }
        guard let image = generateExportImage() else { return }
        isExporting = true

        Task {
            defer { isExporting = false }
            let authorized = await ensurePhotoAddAuthorization(
                deniedMessage: lChoice(
                    kn: "ಚಿತ್ರ ಉಳಿಸಲು ಫೋಟೋಗಳ ಅನುಮತಿ ಅಗತ್ಯವಿದೆ.",
                    en: "Photos permission is required to save images.",
                    ar: "يلزم إذن الصور لحفظ الصور."
                )
            )
            guard authorized else { return }

            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
                showSavedToast(
                    lChoice(
                        kn: "ಫೋಟೋಗಳಿಗೆ ಉಳಿಸಲಾಗಿದೆ! ✓",
                        en: "Saved to Photos! ✓",
                        ar: "تم الحفظ في الصور ✓"
                    )
                )
            } catch {
                logger.error("AyahShareImageViewModel: Save image failed: \(error)")
                errorAlertMessage = error.localizedDescription
            }
        }
    }

    private func saveVideoToPhotos() {
        guard !isExporting else { return }
        stopAudioPreview()
        isExporting = true
        exportProgress = AyahVideoProgress(
            message: lChoice(kn: "ತಯಾರಿಸಲಾಗುತ್ತಿದೆ...", en: "Preparing...", ar: "جارٍ التحضير...")
        )

        Task {
            do {
                let authorized = await ensurePhotoAddAuthorization(
                    deniedMessage: lChoice(
                        kn: "ವೀಡಿಯೊ ಉಳಿಸಲು ಫೋಟೋಗಳ ಅನುಮತಿ ಅಗತ್ಯವಿದೆ.",
                        en: "Photos permission is required to save videos.",
                        ar: "يلزم إذن الصور لحفظ الفيديو."
                    )
                )
                guard authorized else {
                    isExporting = false
                    exportProgress = nil
                    return
                }

                let outURL = try await exportCurrentVideo()
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outURL)
                }
                isExporting = false
                exportProgress = nil
                showSavedToast(
                    lChoice(
                        kn: "ವೀಡಿಯೊ ಉಳಿಸಲಾಗಿದೆ! ✓",
                        en: "Video saved to Photos! ✓",
                        ar: "تم حفظ الفيديو في الصور ✓"
                    )
                )
            } catch {
                logger.error("AyahShareImageViewModel: Save video failed: \(error)")
                isExporting = false
                exportProgress = nil
                errorAlertMessage = error.localizedDescription
            }
        }
    }

    private func exportCurrentVideo() async throws -> URL {
        var bgVideoURL: URL? = nil
        if backgroundMode == 2, let item = selectedRemoteVideoItem {
            if let cached = RemoteBackgroundService.shared.cachedVideoURL(for: item.id) {
                bgVideoURL = cached
            } else {
                let dlLabel = lChoice(
                    kn: "ಹಿನ್ನೆಲೆ ವೀಡಿಯೊ ಡೌನ್‌ಲೋಡ್ ಆಗುತ್ತಿದೆ...",
                    en: "Downloading background video...",
                    ar: "جارٍ تنزيل فيديو الخلفية..."
                )
                exportProgress = AyahVideoProgress(message: dlLabel, percent: 0)
                bgVideoURL = try await RemoteBackgroundService.shared.downloadAndCacheVideo(for: item) { pct in
                    Task { @MainActor [weak self] in
                        self?.exportProgress = AyahVideoProgress(message: dlLabel, percent: pct)
                    }
                }
                selectedBackgroundVideoURL = bgVideoURL
            }
        }

        let segment = try await videoExporter.resolveAudio(
            for: verses,
            reciterId: selectedReciterId
        ) { [weak self] progress in
            self?.exportProgress = progress
        }

        let qualityProfile = AyahVideoExporter.selectQualityProfile(
            hasVideoBackground: bgVideoURL != nil,
            preferredQuality: videoExportQuality
        )
        let exportW = CGFloat(qualityProfile.exportWidth)
        let exportH = selectedAspectRatio.height(for: exportW)
        let isTransparent = bgVideoURL != nil

        return try await videoExporter.exportVideo(
            segment: segment,
            backgroundVideoURL: bgVideoURL,
            backgroundVideoScale: photoScale,
            targetSize: CGSize(width: exportW, height: exportH),
            preferredQuality: videoExportQuality,
            slidesFactory: { cues, w, _ in
                let targetWidth = CGFloat(w)
                guard let rootData = self.cardData else { return [] }
                if self.syncAyahWithAudio && rootData.ayahSlides.count > 1 && cues.count == rootData.ayahSlides.count {
                    return zip(cues, rootData.ayahSlides).compactMap { cue, slideData in
                        let slideCard = slideData.toCardData(translator: rootData.translator)
                        guard let img = self.generateExportImage(
                            data: slideCard,
                            targetWidth: targetWidth,
                            transparentBackground: isTransparent
                        ) else {
                            return nil
                        }
                        return AyahTimedSlide(
                            startSec: cue.relativeStartSec,
                            endSec: cue.relativeEndSec,
                            overlayImage: img
                        )
                    }
                } else {
                    guard let img = self.generateExportImage(
                        data: rootData,
                        targetWidth: targetWidth,
                        transparentBackground: isTransparent
                    ) else {
                        return []
                    }
                    let endSec = cues.last?.relativeEndSec ?? 5.0
                    return [AyahTimedSlide(startSec: 0, endSec: max(1.0, endSec), overlayImage: img)]
                }
            },
            onProgress: { [weak self] progress in
                self?.exportProgress = progress
            }
        )
    }

    private func cleanFootnoteString(_ rawFootnote: String) -> String {
        var text = rawFootnote.trimmingCharacters(in: CharacterSet(charactersIn: "[] \t\n\r"))
        text = text.replacingOccurrences(of: "^\\[\\d+\\]\\s*", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "^\\[[0-9\\u0CE6-\\u0CEF]+\\]\\s*", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "^[0-9\\u0CE6-\\u0CEF]+[\\.\\:\\-]\\s*", with: "", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildTranslationTextWithFootnotes(_ translationText: TranslationText, startingNumber: Int) -> String {
        switch translationText {
        case .string(let translationString):
            var result = ""
            var currentIndex = translationString.text.startIndex
            var noteNumber = startingNumber
            for range in translationString.footnoteRanges {
                guard range.lowerBound >= currentIndex && range.upperBound <= translationString.text.endIndex else {
                    continue
                }
                result.append(contentsOf: translationString.text[currentIndex ..< range.lowerBound])
                result.append("[\(noteNumber)]")
                noteNumber += 1
                currentIndex = range.upperBound
            }
            result.append(contentsOf: translationString.text[currentIndex...])
            let normalized = result.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
            return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        case .reference(let verse):
            return lFormat("translation.text.see-referenced-verse", verse.ayah)
        }
    }

    private static func arabicIndicNumber(_ number: Int) -> String {
        let digits = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(number).map { char in
            if let d = Int(String(char)), d >= 0 && d < 10 {
                return digits[d]
            }
            return String(char)
        }.joined()
    }

    private func cleanTranslationText(_ translationText: TranslationText) -> String {
        switch translationText {
        case .string(let translationString):
            // Remove footnote markers using exact footnoteRanges
            var cleanText = ""
            var currentIndex = translationString.text.startIndex
            for range in translationString.footnoteRanges {
                guard range.lowerBound >= currentIndex && range.upperBound <= translationString.text.endIndex else {
                    continue
                }
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
