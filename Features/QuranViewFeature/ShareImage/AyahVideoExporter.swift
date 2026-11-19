//
//  AyahVideoExporter.swift
//  Quran
//
//  Created for Kannada Quran App.
//

@preconcurrency import AVFoundation
import AudioTimingService
import CoreImage
import Foundation
import Localization
import QuranAudio
import QuranKit
import ReciterService
import UIKit
import Utilities
import VLogging

public struct AyahReciterOption: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let isGapped: Bool
    public let reciter: Reciter
}

public struct AyahAudioTrackPart: Sendable {
    public let fileURL: URL
    public let startSec: Double
    public let endSec: Double?
}

public struct AyahAudioCue: Equatable, Sendable {
    public let suraNumber: Int
    public let ayahNumber: Int
    public let relativeStartSec: Double
    public let relativeEndSec: Double
    public let partIndex: Int
}

public struct AyahAudioSegment: Sendable {
    public let qariName: String
    public let parts: [AyahAudioTrackPart]
    public let ayahCues: [AyahAudioCue]
}

public struct AyahTimedSlide: Sendable {
    public let startSec: Double
    public let endSec: Double
    public let overlayImage: UIImage
}

public struct AyahVideoProgress: Equatable, Sendable {
    public let message: String
    public let percent: Int?

    public init(message: String, percent: Int? = nil) {
        self.message = message
        self.percent = percent
    }
}

public struct AyahVideoQualityProfile: Equatable, Sendable {
    public let exportWidth: Int
    public let videoBitrate: Int

    public init(exportWidth: Int, videoBitrate: Int) {
        self.exportWidth = exportWidth
        self.videoBitrate = videoBitrate
    }
}

public struct AyahAudioPreviewSession {
    public let playerItem: AVPlayerItem
    public let durationSec: Double
    public let cues: [AyahAudioCue]
    public let qariName: String
}

public final class AyahVideoExporter {
    public static let whatsappSlowSafeMaxBytes: Double = 55_000_000
    public static let highTierMinRamBytes: UInt64 = 3_800_000_000 // 4 GB+ iPhones (11+), iPads, and all 8 GB+ Apple Silicon Macs

    public static func selectQualityProfile(
        hasVideoBackground: Bool,
        estimatedDurationSec: Double = 15.0,
        physicalMemoryBytes: UInt64 = ProcessInfo.processInfo.physicalMemory,
        preferredQuality: AyahVideoExportQuality? = nil
    ) -> AyahVideoQualityProfile {
        let safeDuration = max(1.0, estimatedDurationSec)
        let totalBudgetBps = Int((whatsappSlowSafeMaxBytes * 8.0) / safeDuration)
        let videoBudgetBps = max(1_500_000, totalBudgetBps - 160_000)

        guard hasVideoBackground else {
            if preferredQuality == .standard720p {
                return AyahVideoQualityProfile(
                    exportWidth: 720,
                    videoBitrate: min(1_800_000, max(900_000, videoBudgetBps))
                )
            }
            return AyahVideoQualityProfile(
                exportWidth: 1080,
                videoBitrate: min(2_400_000, max(900_000, videoBudgetBps))
            )
        }

        let memoryAllows1080p: Bool
        switch preferredQuality {
        case .standard720p:
            memoryAllows1080p = false
        case .high1080p:
            memoryAllows1080p = true
        case nil:
            memoryAllows1080p = physicalMemoryBytes >= highTierMinRamBytes
        }

        if memoryAllows1080p && videoBudgetBps >= 3_600_000 {
            return AyahVideoQualityProfile(
                exportWidth: 1080,
                videoBitrate: min(6_200_000, videoBudgetBps)
            )
        }
        return AyahVideoQualityProfile(
            exportWidth: 720,
            videoBitrate: min(4_500_000, videoBudgetBps)
        )
    }

    private let appHost: URL

    public init(appHost: URL) {
        self.appHost = appHost
    }

    public func getAvailableReciters() async -> [AyahReciterOption] {
        let reciters = await ReciterDataRetriever().getReciters()
        return reciters.map { reciter in
            let isGapped: Bool
            if case .gapped = reciter.audioType {
                isGapped = true
            } else {
                isGapped = false
            }
            let suffix = isGapped ? " (gapped)" : ""
            return AyahReciterOption(
                id: reciter.id,
                name: "\(reciter.localizedName)\(suffix)",
                isGapped: isGapped,
                reciter: reciter
            )
        }
    }

    public func getDefaultReciterId(from options: [AyahReciterOption]) -> Int {
        let prefId = ReciterPreferences.shared.lastSelectedReciterId
        if let exact = options.first(where: { $0.id == prefId }) {
            return exact.id
        }
        return options.first?.id ?? 0
    }

    // MARK: - Audio & Timing Resolution

    public func resolveAudio(
        for verses: [AyahNumber],
        reciterId: Int?,
        onProgress: (@MainActor @Sendable (AyahVideoProgress) -> Void)? = nil
    ) async throws -> AyahAudioSegment {
        guard !verses.isEmpty else {
            throw NSError(domain: "AyahVideoExporter", code: 1, userInfo: [
                NSLocalizedDescriptionKey: lChoice(
                    kn: "ಕನಿಷ್ಠ ಒಂದು ಆಯತ್ ಆಯ್ಕೆಮಾಡಿ.",
                    en: "At least one ayah is required.",
                    ar: "مطلوب آية واحدة على الأقل."
                )
            ])
        }

        let options = await getAvailableReciters()
        let targetId = reciterId ?? getDefaultReciterId(from: options)
        guard let reciter = options.first(where: { $0.id == targetId })?.reciter ?? options.first?.reciter else {
            throw NSError(domain: "AyahVideoExporter", code: 2, userInfo: [
                NSLocalizedDescriptionKey: lChoice(
                    kn: "ಯಾವುದೇ ವಾಚಕರು ಲಭ್ಯವಿಲ್ಲ.",
                    en: "No reciters available.",
                    ar: "لا يوجد قراء متاحون."
                )
            ])
        }

        try FileManager.default.createDirectory(at: reciter.localFolder().url, withIntermediateDirectories: true)

        switch reciter.audioType {
        case .gapless:
            return try await resolveGaplessAudio(reciter: reciter, verses: verses, onProgress: onProgress)
        case .gapped:
            return try await resolveGappedAudio(reciter: reciter, verses: verses, onProgress: onProgress)
        }
    }

    private func resolveGaplessAudio(
        reciter: Reciter,
        verses: [AyahNumber],
        onProgress: (@MainActor @Sendable (AyahVideoProgress) -> Void)?
    ) async throws -> AyahAudioSegment {
        guard let dbURL = reciter.localDatabasePath?.url,
              let zipURL = reciter.localZipPath?.url,
              let remoteZipURL = reciter.databaseRemoteURL(baseURL: appHost) else {
            throw NSError(domain: "AyahVideoExporter", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Missing timing database configuration for \(reciter.localizedName)"
            ])
        }

        if !dbURL.isReachable || fileByteSize(dbURL) <= 0 {
            let timingLabel = lChoice(
                kn: "ಟೈಮಿಂಗ್‌ಗಳನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...",
                en: "Downloading timings...",
                ar: "جارٍ تنزيل التوقيتات..."
            )
            await notifyProgress(onProgress, AyahVideoProgress(message: timingLabel, percent: 0))

            if !zipURL.isReachable || fileByteSize(zipURL) <= 0 {
                try await downloadFile(from: remoteZipURL, to: zipURL) { pct in
                    await self.notifyProgress(onProgress, AyahVideoProgress(message: timingLabel, percent: pct))
                }
            }
            try await AudioUnzipper().unzip(reciter: reciter)
        }

        // Group consecutive verses by sura so single-sura and cross-sura ranges work seamlessly.
        var suraRuns: [(sura: Sura, ayahs: [AyahNumber])] = []
        for verse in verses {
            if let last = suraRuns.last, last.sura == verse.sura {
                suraRuns[suraRuns.count - 1].ayahs.append(verse)
            } else {
                suraRuns.append((sura: verse.sura, ayahs: [verse]))
            }
        }

        let timingRetriever = ReciterTimingRetriever()
        var parts: [AyahAudioTrackPart] = []
        var cues: [AyahAudioCue] = []
        var cumulativeOffsetSec: Double = 0

        for (runIdx, run) in suraRuns.enumerated() {
            let suraURL = reciter.localURL(sura: run.sura).url
            if !suraURL.isReachable || fileByteSize(suraURL) <= 0 {
                let label: String
                if suraRuns.count > 1 {
                    label = lChoice(
                        kn: "ಸೂರಾ ಡೌನ್‌ಲೋಡ್ ಆಗುತ್ತಿದೆ (\(runIdx + 1)/\(suraRuns.count))...",
                        en: "Downloading surah \(runIdx + 1)/\(suraRuns.count)...",
                        ar: "جارٍ تنزيل السورة (\(runIdx + 1)/\(suraRuns.count))..."
                    )
                } else {
                    label = lChoice(
                        kn: "ಸೂರಾ ಡೌನ್‌ಲೋಡ್ ಆಗುತ್ತಿದೆ...",
                        en: "Downloading surah...",
                        ar: "جارٍ تنزيل السورة..."
                    )
                }
                await notifyProgress(onProgress, AyahVideoProgress(message: label, percent: 0))
                try await downloadFile(from: reciter.remoteURL(sura: run.sura), to: suraURL) { pct in
                    await self.notifyProgress(onProgress, AyahVideoProgress(message: label, percent: pct))
                }
            }

            let startAyah = run.ayahs.first!
            let endAyah = run.ayahs.last!
            let range = try await timingRetriever.timing(for: reciter, from: startAyah, to: endAyah)
            guard let suraTiming = range.timings[run.sura], !suraTiming.verses.isEmpty else {
                throw NSError(domain: "AyahVideoExporter", code: 4, userInfo: [
                    NSLocalizedDescriptionKey: "Timings unavailable for \(run.sura.suraNumber):\(startAyah.ayah)"
                ])
            }

            let audioDuration = try await readAudioDurationSec(suraURL)
            let includeLeadingBasmala = run.sura.startsWithBesmAllah && startAyah.ayah == 1
            let firstAyahStartSec = max(0, suraTiming.verses.first!.time.seconds)
            let partStartSec = includeLeadingBasmala ? 0.0 : firstAyahStartSec
            let rawRangeEndSec = range.endTime?.seconds ?? suraTiming.endTime?.seconds
            let resolvedPartEndSec: Double
            if let rawEnd = rawRangeEndSec, rawEnd > partStartSec {
                resolvedPartEndSec = min(audioDuration ?? rawEnd, rawEnd)
            } else {
                resolvedPartEndSec = audioDuration ?? (partStartSec + 5.0)
            }

            let partIndex = parts.count
            parts.append(AyahAudioTrackPart(fileURL: suraURL, startSec: partStartSec, endSec: resolvedPartEndSec))

            for (idx, verseTiming) in suraTiming.verses.enumerated() {
                let ayahStartSec = (idx == 0 && includeLeadingBasmala)
                    ? partStartSec
                    : max(partStartSec, verseTiming.time.seconds)
                let ayahEndSec: Double
                if idx + 1 < suraTiming.verses.count {
                    ayahEndSec = max(ayahStartSec + 0.1, suraTiming.verses[idx + 1].time.seconds)
                } else {
                    ayahEndSec = max(ayahStartSec + 0.1, resolvedPartEndSec)
                }

                cues.append(
                    AyahAudioCue(
                        suraNumber: verseTiming.ayah.sura.suraNumber,
                        ayahNumber: verseTiming.ayah.ayah,
                        relativeStartSec: cumulativeOffsetSec + (ayahStartSec - partStartSec),
                        relativeEndSec: cumulativeOffsetSec + (ayahEndSec - partStartSec),
                        partIndex: partIndex
                    )
                )
            }

            cumulativeOffsetSec += max(0.1, resolvedPartEndSec - partStartSec)
        }

        return AyahAudioSegment(qariName: reciter.localizedName, parts: parts, ayahCues: cues)
    }

    private func resolveGappedAudio(
        reciter: Reciter,
        verses: [AyahNumber],
        onProgress: (@MainActor @Sendable (AyahVideoProgress) -> Void)?
    ) async throws -> AyahAudioSegment {
        var parts: [AyahAudioTrackPart] = []
        var cues: [AyahAudioCue] = []
        var cumulativeSec: Double = 0

        for (idx, ayah) in verses.enumerated() {
            let prevSura = idx > 0 ? verses[idx - 1].sura : nil
            if ayah == ayah.sura.firstVerse && ayah.sura.startsWithBesmAllah && prevSura != ayah.sura {
                let basmalaURL = reciter.localURL(ayah: ayah.quran.firstVerse).url
                if !basmalaURL.isReachable || fileByteSize(basmalaURL) <= 0 {
                    try? await downloadFile(from: reciter.remoteURL(ayah: ayah.quran.firstVerse), to: basmalaURL, onPercent: nil)
                }
                if basmalaURL.isReachable && fileByteSize(basmalaURL) > 0 {
                    let basmalaDuration = max(0.5, try await readAudioDurationSec(basmalaURL) ?? 4.0)
                    let basmalaPartIndex = parts.count
                    parts.append(AyahAudioTrackPart(fileURL: basmalaURL, startSec: 0, endSec: basmalaDuration))
                    cues.append(
                        AyahAudioCue(
                            suraNumber: ayah.sura.suraNumber,
                            ayahNumber: ayah.ayah,
                            relativeStartSec: cumulativeSec,
                            relativeEndSec: cumulativeSec + basmalaDuration,
                            partIndex: basmalaPartIndex
                        )
                    )
                    cumulativeSec += basmalaDuration
                }
            }

            let ayahURL = reciter.localURL(ayah: ayah).url
            if !ayahURL.isReachable || fileByteSize(ayahURL) <= 0 {
                let label: String
                if verses.count > 1 {
                    label = lChoice(
                        kn: "ಆಡಿಯೋ ಡೌನ್‌ಲೋಡ್ ಆಗುತ್ತಿದೆ (\(idx + 1)/\(verses.count))...",
                        en: "Downloading audio \(idx + 1)/\(verses.count)...",
                        ar: "جارٍ تنزيل التلاوة (\(idx + 1)/\(verses.count))..."
                    )
                } else {
                    label = lChoice(
                        kn: "ಆಡಿಯೋ ಡೌನ್‌ಲೋಡ್ ಆಗುತ್ತಿದೆ...",
                        en: "Downloading audio...",
                        ar: "جارٍ تنزيل التلاوة..."
                    )
                }
                await notifyProgress(onProgress, AyahVideoProgress(message: label, percent: 0))
                try await downloadFile(from: reciter.remoteURL(ayah: ayah), to: ayahURL) { pct in
                    await self.notifyProgress(onProgress, AyahVideoProgress(message: label, percent: pct))
                }
            }

            let partDuration = max(0.5, try await readAudioDurationSec(ayahURL) ?? 4.0)
            let partIndex = parts.count
            parts.append(AyahAudioTrackPart(fileURL: ayahURL, startSec: 0, endSec: partDuration))
            cues.append(
                AyahAudioCue(
                    suraNumber: ayah.sura.suraNumber,
                    ayahNumber: ayah.ayah,
                    relativeStartSec: cumulativeSec,
                    relativeEndSec: cumulativeSec + partDuration,
                    partIndex: partIndex
                )
            )
            cumulativeSec += partDuration
        }

        return AyahAudioSegment(qariName: reciter.localizedName, parts: parts, ayahCues: cues)
    }

    // MARK: - Preview Composition

    public func buildPreviewSession(from segment: AyahAudioSegment) async throws -> AyahAudioPreviewSession {
        let (composition, durationSec) = try await buildAudioComposition(from: segment)
        let item = await MainActor.run {
            AVPlayerItem(asset: composition)
        }
        return AyahAudioPreviewSession(
            playerItem: item,
            durationSec: durationSec,
            cues: segment.ayahCues,
            qariName: segment.qariName
        )
    }

    // MARK: - MP4 Video Export

    public func exportVideo(
        segment: AyahAudioSegment,
        backgroundVideoURL: URL?,
        backgroundVideoScale: CGFloat,
        targetSize: CGSize,
        preferredQuality: AyahVideoExportQuality? = nil,
        slidesFactory: @MainActor ([AyahAudioCue], Int, Int) -> [AyahTimedSlide],
        onProgress: (@MainActor @Sendable (AyahVideoProgress) -> Void)? = nil
    ) async throws -> URL {
        let width = makeEven(Int(targetSize.width.rounded()))
        let height = makeEven(Int(targetSize.height.rounded()))

        await notifyProgress(
            onProgress,
            AyahVideoProgress(
                message: lChoice(
                    kn: "ವೀಡಿಯೊ ರಚಿಸಲಾಗುತ್ತಿದೆ...",
                    en: "Creating video...",
                    ar: "جارٍ إنشاء الفيديو..."
                ),
                percent: 0
            )
        )

        let (audioComposition, rawDurationSec) = try await buildAudioComposition(from: segment)
        let durationSec = max(1.0, rawDurationSec)
        let qualityProfile = Self.selectQualityProfile(
            hasVideoBackground: backgroundVideoURL != nil,
            estimatedDurationSec: durationSec,
            preferredQuality: preferredQuality
        )
        let resolvedWidth = makeEven(min(width, qualityProfile.exportWidth))
        let aspectScale = Double(resolvedWidth) / Double(max(2, width))
        let resolvedHeight = makeEven(Int((Double(height) * aspectScale).rounded()))

        let slides = await MainActor.run {
            slidesFactory(segment.ayahCues, resolvedWidth, resolvedHeight)
        }
        guard !slides.isEmpty else {
            throw NSError(domain: "AyahVideoExporter", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "No video slides generated."
            ])
        }

        let shareDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("shared_exports", isDirectory: true)
        try FileManager.default.createDirectory(at: shareDir, withIntermediateDirectories: true)
        if let existing = try? FileManager.default.contentsOfDirectory(at: shareDir, includingPropertiesForKeys: nil) {
            for file in existing where file.pathExtension.lowercased() == "mp4" {
                try? FileManager.default.removeItem(at: file)
            }
        }
        let outURL = shareDir.appendingPathComponent("Quran_Ayah_\(Int(Date().timeIntervalSince1970 * 1000)).mp4")
        try? FileManager.default.removeItem(at: outURL)

        try await writeMP4(
            audioComposition: audioComposition,
            durationSec: durationSec,
            slides: slides,
            backgroundVideoURL: backgroundVideoURL,
            backgroundVideoScale: backgroundVideoScale,
            width: resolvedWidth,
            height: resolvedHeight,
            videoBitrate: qualityProfile.videoBitrate,
            outURL: outURL,
            onProgress: onProgress
        )

        return outURL
    }

    // MARK: - AVFoundation Rendering & Muxing

    private func buildAudioComposition(from segment: AyahAudioSegment) async throws -> (AVMutableComposition, Double) {
        let composition = AVMutableComposition()
        guard let compAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw NSError(domain: "AyahVideoExporter", code: 6, userInfo: [
                NSLocalizedDescriptionKey: "Unable to create audio composition track."
            ])
        }

        var cursor = CMTime.zero
        for part in segment.parts {
            let asset = AVURLAsset(url: part.fileURL)
            let tracks = try await asset.loadTracks(withMediaType: .audio)
            guard let srcTrack = tracks.first else { continue }

            let assetDuration = try await asset.load(.duration)
            let assetDurationSec = CMTimeGetSeconds(assetDuration)
            let startSec = max(0, min(part.startSec, max(0, assetDurationSec - 0.05)))
            let endSec = min(assetDurationSec, part.endSec ?? assetDurationSec)
            guard endSec > startSec else { continue }

            let startCM = CMTime(seconds: startSec, preferredTimescale: 44_100)
            let spanCM = CMTime(seconds: endSec - startSec, preferredTimescale: 44_100)
            try compAudioTrack.insertTimeRange(CMTimeRange(start: startCM, duration: spanCM), of: srcTrack, at: cursor)
            cursor = CMTimeAdd(cursor, spanCM)
        }

        let totalSec = max(0.5, CMTimeGetSeconds(cursor))
        return (composition, totalSec)
    }

    private func writeMP4(
        audioComposition: AVMutableComposition,
        durationSec: Double,
        slides: [AyahTimedSlide],
        backgroundVideoURL: URL?,
        backgroundVideoScale: CGFloat,
        width: Int,
        height: Int,
        videoBitrate: Int,
        outURL: URL,
        onProgress: (@MainActor @Sendable (AyahVideoProgress) -> Void)?
    ) async throws {
        let writer = try AVAssetWriter(outputURL: outURL, fileType: .mp4)

        var compressionProps: [String: Any] = [
            AVVideoAverageBitRateKey: videoBitrate,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
        ]
        if backgroundVideoURL != nil {
            compressionProps[AVVideoExpectedSourceFrameRateKey] = 30
            compressionProps[AVVideoMaxKeyFrameIntervalKey] = 60
        }
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: compressionProps,
        ]
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false

        let pixelBufferAttrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: pixelBufferAttrs
        )
        guard writer.canAdd(videoInput) else {
            throw NSError(domain: "AyahVideoExporter", code: 7, userInfo: [NSLocalizedDescriptionKey: "Cannot add video writer input."])
        }
        writer.add(videoInput)

        let audioTracks = try await audioComposition.loadTracks(withMediaType: .audio)
        var audioInput: AVAssetWriterInput?
        var audioReader: AVAssetReader?
        var audioOutput: AVAssetReaderAudioMixOutput?

        if !audioTracks.isEmpty {
            let aacSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 128_000,
            ]
            let aInput = AVAssetWriterInput(mediaType: .audio, outputSettings: aacSettings)
            aInput.expectsMediaDataInRealTime = false
            if writer.canAdd(aInput) {
                writer.add(aInput)
                audioInput = aInput

                let aReader = try AVAssetReader(asset: audioComposition)
                let pcmSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: 44_100,
                    AVNumberOfChannelsKey: 2,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsNonInterleaved: false,
                    AVLinearPCMIsBigEndianKey: false,
                ]
                let aOut = AVAssetReaderAudioMixOutput(audioTracks: audioTracks, audioSettings: pcmSettings)
                if aReader.canAdd(aOut) {
                    aReader.add(aOut)
                    audioReader = aReader
                    audioOutput = aOut
                }
            }
        }

        guard writer.startWriting() else {
            throw writer.error ?? NSError(domain: "AyahVideoExporter", code: 8, userInfo: [NSLocalizedDescriptionKey: "Failed to start MP4 writer."])
        }
        writer.startSession(atSourceTime: .zero)

        let ciContext = CIContext(options: [.useSoftwareRenderer: false])
        let slideCGs: [(startSec: Double, endSec: Double, ciImage: CIImage, cgImage: CGImage?)] = slides.compactMap { slide in
            let cg = slide.overlayImage.cgImage
            let ci = (cg.map { CIImage(cgImage: $0) } ?? CIImage(image: slide.overlayImage)) ?? CIImage()
            return (slide.startSec, slide.endSec, ci, cg)
        }

        let totalDurationSec = durationSec
        let creatingMsg = lChoice(kn: "ವೀಡಿಯೊ ರಚಿಸಲಾಗುತ್ತಿದೆ...", en: "Creating video...", ar: "جارٍ إنشاء الفيديو...")

        // Preload background video metadata on async path before pumping synchronously.
        var bgContext: BackgroundVideoContext?
        if let bgURL = backgroundVideoURL {
            bgContext = try await BackgroundVideoContext.load(url: bgURL)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let group = DispatchGroup()
            var pumpError: Error?
            let errLock = NSLock()

            func recordError(_ error: Error) {
                errLock.lock()
                if pumpError == nil { pumpError = error }
                errLock.unlock()
            }

            if let aInput = audioInput, let aReader = audioReader, let aOut = audioOutput {
                group.enter()
                let audioQueue = DispatchQueue(label: "quran.ayahvideo.audio")
                aReader.startReading()
                aInput.requestMediaDataWhenReady(on: audioQueue) {
                    while aInput.isReadyForMoreMediaData {
                        if let sample = aOut.copyNextSampleBuffer() {
                            if !aInput.append(sample) {
                                recordError(writer.error ?? NSError(domain: "AyahVideoExporter", code: 9))
                                aReader.cancelReading()
                                aInput.markAsFinished()
                                group.leave()
                                return
                            }
                        } else {
                            if aReader.status == .failed {
                                recordError(aReader.error ?? NSError(domain: "AyahVideoExporter", code: 10))
                            }
                            aInput.markAsFinished()
                            group.leave()
                            return
                        }
                    }
                }
            }

            group.enter()
            let videoQueue = DispatchQueue(label: "quran.ayahvideo.video")

            if let bgCtx = bgContext {
                // Moving video background: composite 30fps using GPU CIContext
                let fps: Int32 = 30
                let totalFrames = max(1, Int(ceil(totalDurationSec * Double(fps))))
                var frameIndex = 0
                var loopLoopReader = try? bgCtx.createReader()
                var lastDecodedBG: CIImage?
                var currentLoopDurationOffset: Double = 0
                var lastReportedPct = -1

                videoInput.requestMediaDataWhenReady(on: videoQueue) {
                    while videoInput.isReadyForMoreMediaData {
                        if frameIndex > totalFrames {
                            loopLoopReader?.reader.cancelReading()
                            videoInput.markAsFinished()
                            group.leave()
                            return
                        }

                        let ptsSec = min(totalDurationSec, Double(frameIndex) / Double(fps))
                        let pts = CMTime(value: CMTimeValue(frameIndex), timescale: fps)

                        // Advance or loop background frames until source frame timestamp reaches loop-local time.
                        let localTargetSec = ptsSec - currentLoopDurationOffset
                        if loopLoopReader == nil {
                            loopLoopReader = try? bgCtx.createReader()
                        }

                        while let activeReader = loopLoopReader {
                            if lastDecodedBG != nil,
                               let nextSample = activeReader.nextFrame(upToLoopTimeSec: localTargetSec) {
                                lastDecodedBG = nextSample
                                break
                            } else if lastDecodedBG == nil, let nextSample = activeReader.pullNextFrame() {
                                lastDecodedBG = nextSample
                                break
                            } else if activeReader.didReachEnd {
                                currentLoopDurationOffset = ptsSec
                                activeReader.reader.cancelReading()
                                loopLoopReader = try? bgCtx.createReader()
                                if loopLoopReader?.pullNextFrame().map({ lastDecodedBG = $0 }) == nil {
                                    break
                                }
                                break
                            } else {
                                break
                            }
                        }

                        let activeSlide = slideCGs.first(where: { ptsSec >= $0.startSec && ptsSec < $0.endSec })
                            ?? slideCGs.last!

                        guard let pool = adaptor.pixelBufferPool,
                              let outPB = Self.makePixelBuffer(from: pool) else {
                            recordError(NSError(domain: "AyahVideoExporter", code: 11, userInfo: [NSLocalizedDescriptionKey: "Pixel buffer pool exhausted"]))
                            videoInput.markAsFinished()
                            group.leave()
                            return
                        }

                        let composed: CIImage
                        if let bgCI = lastDecodedBG {
                            let scaledBG = Self.aspectFillCIImage(bgCI, width: width, height: height, zoom: backgroundVideoScale)
                            composed = activeSlide.ciImage.composited(over: scaledBG)
                        } else {
                            composed = activeSlide.ciImage
                        }

                        ciContext.render(composed, to: outPB, bounds: CGRect(x: 0, y: 0, width: width, height: height), colorSpace: CGColorSpaceCreateDeviceRGB())

                        if !adaptor.append(outPB, withPresentationTime: pts) {
                            recordError(writer.error ?? NSError(domain: "AyahVideoExporter", code: 12))
                            loopLoopReader?.reader.cancelReading()
                            videoInput.markAsFinished()
                            group.leave()
                            return
                        }

                        let pct = min(99, Int((Double(frameIndex) / Double(totalFrames)) * 100.0))
                        if pct != lastReportedPct, pct % 5 == 0 || pct == 99 {
                            lastReportedPct = pct
                            if let onProgress {
                                Task { @MainActor in
                                    onProgress(AyahVideoProgress(message: creatingMsg, percent: pct))
                                }
                            }
                        }

                        frameIndex += 1
                    }
                }
            } else {
                // Static color/photo slides: sparse crisp frames at 1s intervals + slide boundaries
                var frameTimestamps: [(ptsSec: Double, cgImage: CGImage?, uiImage: UIImage)] = []
                for (sIdx, slide) in slides.enumerated() {
                    let sStart = max(0, min(slide.startSec, totalDurationSec))
                    let sEnd = max(sStart + 0.05, sIdx == slides.count - 1 ? totalDurationSec : min(slide.endSec, totalDurationSec))
                    var t = sStart
                    while t < sEnd - 0.04 {
                        frameTimestamps.append((t, slide.overlayImage.cgImage, slide.overlayImage))
                        t += 1.0
                    }
                    if sIdx == slides.count - 1 {
                        frameTimestamps.append((totalDurationSec, slide.overlayImage.cgImage, slide.overlayImage))
                    }
                }

                var fIdx = 0
                let totalCount = max(1, frameTimestamps.count)
                videoInput.requestMediaDataWhenReady(on: videoQueue) {
                    while videoInput.isReadyForMoreMediaData {
                        if fIdx >= frameTimestamps.count {
                            videoInput.markAsFinished()
                            group.leave()
                            return
                        }

                        let item = frameTimestamps[fIdx]
                        guard let pool = adaptor.pixelBufferPool,
                              let outPB = Self.makePixelBuffer(from: pool) else {
                            recordError(NSError(domain: "AyahVideoExporter", code: 13))
                            videoInput.markAsFinished()
                            group.leave()
                            return
                        }

                        Self.drawCGImage(item.cgImage, fallbackUIImage: item.uiImage, into: outPB, width: width, height: height)
                        let pts = CMTime(seconds: item.ptsSec, preferredTimescale: 600)
                        if !adaptor.append(outPB, withPresentationTime: pts) {
                            recordError(writer.error ?? NSError(domain: "AyahVideoExporter", code: 14))
                            videoInput.markAsFinished()
                            group.leave()
                            return
                        }

                        let pct = min(99, Int((Double(fIdx + 1) / Double(totalCount)) * 100.0))
                        if let onProgress {
                            Task { @MainActor in
                                onProgress(AyahVideoProgress(message: creatingMsg, percent: pct))
                            }
                        }
                        fIdx += 1
                    }
                }
            }

            group.notify(queue: .global(qos: .userInitiated)) {
                errLock.lock()
                let err = pumpError
                errLock.unlock()
                if let err {
                    writer.cancelWriting()
                    continuation.resume(throwing: err)
                    return
                }
                writer.finishWriting {
                    if writer.status == .completed {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: writer.error ?? NSError(domain: "AyahVideoExporter", code: 15, userInfo: [NSLocalizedDescriptionKey: "MP4 export failed."]))
                    }
                }
            }
        }

        await notifyProgress(onProgress, AyahVideoProgress(message: creatingMsg, percent: 100))
    }

    // MARK: - Helpers

    private static func makePixelBuffer(from pool: CVPixelBufferPool) -> CVPixelBuffer? {
        var pb: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pb)
        return pb
    }

    private static func drawCGImage(_ cg: CGImage?, fallbackUIImage: UIImage, into pixelBuffer: CVPixelBuffer, width: Int, height: Int) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let baseAddr = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: baseAddr,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return }

        if let cgImage = cg ?? fallbackUIImage.cgImage {
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    private static func aspectFillCIImage(_ image: CIImage, width: Int, height: Int, zoom: CGFloat) -> CIImage {
        let extent = image.extent
        guard extent.width > 0, extent.height > 0 else { return image }

        let targetW = CGFloat(width)
        let targetH = CGFloat(height)
        let fillScale = max(targetW / extent.width, targetH / extent.height) * max(1.0, zoom)

        let scaledW = extent.width * fillScale
        let scaledH = extent.height * fillScale
        let tx = (targetW - scaledW) / 2.0 - extent.origin.x * fillScale
        let ty = (targetH - scaledH) / 2.0 - extent.origin.y * fillScale

        return image
            .transformed(by: CGAffineTransform(translationX: tx, y: ty).scaledBy(x: fillScale, y: fillScale))
            .cropped(to: CGRect(x: 0, y: 0, width: targetW, height: targetH))
    }

    private func makeEven(_ value: Int) -> Int {
        let safe = max(2, value)
        return (safe % 2 == 0) ? safe : (safe - 1)
    }

    private func fileByteSize(_ url: URL) -> Int64 {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
    }

    private func readAudioDurationSec(_ url: URL) async throws -> Double? {
        let asset = AVURLAsset(url: url)
        let dur = try await asset.load(.duration)
        let sec = CMTimeGetSeconds(dur)
        return sec.isFinite && sec > 0 ? sec : nil
    }

    private func notifyProgress(
        _ handler: (@MainActor @Sendable (AyahVideoProgress) -> Void)?,
        _ progress: AyahVideoProgress
    ) async {
        guard let handler else { return }
        await handler(progress)
    }

    private func downloadFile(
        from remoteURL: URL,
        to destinationURL: URL,
        onPercent: (@Sendable (Int) async -> Void)? = nil
    ) async throws {
        try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let tmpURL = destinationURL.appendingPathExtension("tmp")
        try? FileManager.default.removeItem(at: tmpURL)

        let request = URLRequest(url: remoteURL, timeoutInterval: 60)
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let totalExpected = response.expectedContentLength
        FileManager.default.createFile(atPath: tmpURL.path, contents: nil)
        let handle = try FileHandle(forWritingTo: tmpURL)
        defer { try? handle.close() }

        var buffer = [UInt8]()
        buffer.reserveCapacity(32_768)
        var downloaded: Int64 = 0
        var lastPct = -1

        for try await byte in bytes {
            buffer.append(byte)
            if buffer.count >= 32_768 {
                try handle.write(contentsOf: Data(buffer))
                downloaded += Int64(buffer.count)
                buffer.removeAll(keepingCapacity: true)
                if totalExpected > 0, let onPercent {
                    let pct = min(99, Int((Double(downloaded) / Double(totalExpected)) * 100.0))
                    if pct != lastPct {
                        lastPct = pct
                        await onPercent(pct)
                    }
                }
            }
        }
        if !buffer.isEmpty {
            try handle.write(contentsOf: Data(buffer))
            downloaded += Int64(buffer.count)
        }
        try handle.synchronize()
        try handle.close()

        guard downloaded > 0 else {
            try? FileManager.default.removeItem(at: tmpURL)
            throw URLError(.cannotDecodeContentData)
        }
        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.moveItem(at: tmpURL, to: destinationURL)
        await onPercent?(100)
    }
}

private struct BackgroundVideoContext {
    let asset: AVURLAsset
    let videoTrack: AVAssetTrack
    let composition: AVMutableVideoComposition

    static func load(url: URL) async throws -> BackgroundVideoContext {
        let asset = AVURLAsset(url: url)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let track = tracks.first else {
            throw NSError(domain: "AyahVideoExporter", code: 20, userInfo: [NSLocalizedDescriptionKey: "No video track in background MP4."])
        }
        let videoComposition: AVMutableVideoComposition
        if #available(iOS 16.0, *) {
            videoComposition = try await AVMutableVideoComposition.videoComposition(withPropertiesOf: asset)
        } else {
            videoComposition = AVMutableVideoComposition(propertiesOf: asset)
        }
        return BackgroundVideoContext(asset: asset, videoTrack: track, composition: videoComposition)
    }

    func createReader() throws -> BackgroundVideoReader {
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderVideoCompositionOutput(
            videoTracks: [videoTrack],
            videoSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        )
        output.videoComposition = composition
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else {
            throw NSError(domain: "AyahVideoExporter", code: 21, userInfo: [NSLocalizedDescriptionKey: "Cannot attach background video reader output."])
        }
        reader.add(output)
        reader.startReading()
        return BackgroundVideoReader(reader: reader, output: output)
    }
}

private final class BackgroundVideoReader {
    let reader: AVAssetReader
    let output: AVAssetReaderVideoCompositionOutput
    var lastFrameTimeSec: Double = -1
    var lastImage: CIImage?
    var didReachEnd = false

    init(reader: AVAssetReader, output: AVAssetReaderVideoCompositionOutput) {
        self.reader = reader
        self.output = output
    }

    func pullNextFrame() -> CIImage? {
        guard !didReachEnd else { return nil }
        guard let sample = output.copyNextSampleBuffer(),
              let pb = CMSampleBufferGetImageBuffer(sample) else {
            didReachEnd = true
            return nil
        }
        let pts = CMSampleBufferGetPresentationTimeStamp(sample)
        lastFrameTimeSec = CMTimeGetSeconds(pts)
        let ci = CIImage(cvPixelBuffer: pb)
        lastImage = ci
        return ci
    }

    func nextFrame(upToLoopTimeSec targetSec: Double) -> CIImage? {
        while lastFrameTimeSec < targetSec {
            guard let next = pullNextFrame() else {
                return nil
            }
            if lastFrameTimeSec >= targetSec {
                return next
            }
        }
        return lastImage ?? pullNextFrame()
    }
}
