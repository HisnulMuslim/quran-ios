//
//  TranslationItem+View.swift
//
//
//  Created by Mohamed Afifi on 2023-12-28.
//

import CoreText
import Localization
import NoorFont
import NoorUI
import QuranKit
import QuranText
import QuranTextKit
import SwiftUI
import UIKit
import UIx

extension TranslationPageHeader: View {
    var body: some View {
        QuranPageHeader(quarterName: page.localizedQuarterName, suraNames: page.suraNames())
    }
}

extension TranslationPageFooter: View {
    var body: some View {
        QuranPageFooter(page: page.localizedNumber)
    }
}

extension TranslationSuraName: View {
    var body: some View {
        QuranSuraName(
            suraName: sura.localizedName(withPrefix: false),
            besmAllah: sura.startsWithBesmAllah ? sura.quran.arabicBesmAllah : "",
            besmAllahFontSize: arabicFontSize
        )
    }
}

class BoundingBoxTextView: UITextView {
    // MARK: Lifecycle

    init() {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: .zero)
        layoutManager.addTextContainer(textContainer)
        super.init(frame: .zero, textContainer: textContainer)
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var onLayoutCompleted: (([AyahNumber: [CGRect]], CGFloat) -> Void)?

    var verses: [TranslationArabicText] = [] {
        didSet {
            isJustified = false
            setNeedsLayout()
        }
    }

    var fontSizeValue: CGFloat = 21 {
        didSet {
            if oldValue != fontSizeValue {
                isJustified = false
                setNeedsLayout()
            }
        }
    }

    var targetWidth: CGFloat = 300 {
        didSet {
            if oldValue != targetWidth {
                isJustified = false
                invalidateIntrinsicContentSize()
                setNeedsLayout()
            }
        }
    }

    private var lastScrolledVerse: AyahNumber?
    private var lastScrollTriggerCount: Int = -1
    private var scrollRequestVerse: AyahNumber?

    func setScrollRequest(_ verse: AyahNumber?, triggerCount: Int) {
        if triggerCount != lastScrollTriggerCount || verse != scrollRequestVerse {
            lastScrollTriggerCount = triggerCount
            scrollRequestVerse = verse
            lastScrolledVerse = nil
            setNeedsLayout()
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let width = size.width > 0 ? size.width : (targetWidth > 0 ? targetWidth : (bounds.width > 0 ? bounds.width : 300))
        guard width > 0 else { return .zero }

        if textContainer.size.width != width {
            isJustified = false
        }
        textContainer.size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        layoutManager.ensureLayout(for: textContainer)

        if !isJustified {
            isJustified = true
            justifySpaces()
            layoutManager.ensureLayout(for: textContainer)
        }

        let usedHeight = ceil(layoutManager.usedRect(for: textContainer).height)
        return CGSize(width: width, height: usedHeight)
    }

    override var intrinsicContentSize: CGSize {
        let width = targetWidth > 0 ? targetWidth : (bounds.width > 0 ? bounds.width : 300)
        return sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        sizeThatFits(targetSize)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let width = bounds.width > 0 ? bounds.width : (targetWidth > 0 ? targetWidth : 300)
        guard width > 0 else { return }

        if textContainer.size.width != width {
            isJustified = false
        }
        textContainer.size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        layoutManager.ensureLayout(for: textContainer)

        if !isJustified {
            isJustified = true
            justifySpaces()
            layoutManager.ensureLayout(for: textContainer)
        }

        var frames: [AyahNumber: [CGRect]] = [:]
        var location = 0

        for verse in verses {
            let verseText = verse.text + " "
            let length = verseText.utf16.count
            let range = NSRange(location: location, length: length)
            location += length

            let rects = rects(forCharacterRange: range)
            frames[verse.verse] = rects
        }

        let usedHeight = ceil(layoutManager.usedRect(for: textContainer).height)
        onLayoutCompleted?(frames, usedHeight)

        if let scrollToVerse = scrollRequestVerse, scrollToVerse != lastScrolledVerse, let rects = frames[scrollToVerse], !rects.isEmpty {
            lastScrolledVerse = scrollToVerse
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let parentScrollView = self.findParentScrollView() else { return }
                guard !parentScrollView.isDragging && !parentScrollView.isDecelerating else { return }
                var unionRect = rects[0]
                for rect in rects {
                    unionRect = unionRect.union(rect)
                }
                let convertedRect = parentScrollView.convert(unionRect, from: self)
                let targetY = convertedRect.minY - parentScrollView.contentInset.top - (parentScrollView.bounds.height * 0.2)
                let minY = -parentScrollView.contentInset.top
                let maxY = max(minY, parentScrollView.contentSize.height - parentScrollView.bounds.height + parentScrollView.contentInset.bottom)
                let clampedY = max(minY, min(targetY, maxY))
                parentScrollView.setContentOffset(CGPoint(x: parentScrollView.contentOffset.x, y: clampedY), animated: true)
            }
        }
    }

    // MARK: Private

    private var isJustified = false

    private func rects(forCharacterRange range: NSRange) -> [CGRect] {
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var rects: [CGRect] = []
        layoutManager.enumerateEnclosingRects(forGlyphRange: glyphRange, withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), in: textContainer) { rect, _ in
            rects.append(rect)
        }
        return rects
    }

    override var attributedText: NSAttributedString? {
        didSet {
            isJustified = false
        }
    }

    private func justifySpaces() {
        let textString = textStorage.string
        guard textStorage.length > 0 else { return }

        // Remove existing custom space kerning first
        textStorage.beginEditing()
        textStorage.removeAttribute(.kern, range: NSRange(location: 0, length: textStorage.length))
        textStorage.endEditing()

        // Ensure layout metrics are fresh after removing old kerning
        layoutManager.ensureLayout(for: textContainer)

        let glyphCount = layoutManager.numberOfGlyphs
        var glyphIndex = 0

        textStorage.beginEditing()

        while glyphIndex < glyphCount {
            var lineRange = NSRange(location: NSNotFound, length: 0)
            let lineRect = layoutManager.lineFragmentUsedRect(forGlyphAt: glyphIndex, effectiveRange: &lineRange)

            guard lineRange.length > 0 else { break }

            // Move glyphIndex to the next line
            glyphIndex = lineRange.location + lineRange.length

            let charRange = layoutManager.characterRange(forGlyphRange: lineRange, actualGlyphRange: nil)
            guard charRange.location != NSNotFound, charRange.length > 0 else { continue }

            let lineText = (textString as NSString).substring(with: charRange)

            let containerWidth = textContainer.size.width - textContainer.lineFragmentPadding * 2
            let unusedWidth = containerWidth - lineRect.width - 0.8

            guard unusedWidth > 0 else { continue }

            // Find inter-word spaces (ignoring leading/trailing line whitespace)
            let nsLineText = lineText as NSString
            var start = 0
            while start < nsLineText.length {
                if let scalar = UnicodeScalar(nsLineText.character(at: start)),
                   !CharacterSet.whitespacesAndNewlines.contains(scalar) {
                    break
                }
                start += 1
            }

            var end = nsLineText.length - 1
            while end >= start {
                if let scalar = UnicodeScalar(nsLineText.character(at: end)),
                   !CharacterSet.whitespacesAndNewlines.contains(scalar) {
                    break
                }
                end -= 1
            }

            guard end > start else { continue }

            var spaceRanges: [NSRange] = []
            for i in start ... end {
                let char = nsLineText.character(at: i)
                if char == 0x0020 || char == 0x00A0 {
                    spaceRanges.append(NSRange(location: charRange.location + i, length: 1))
                }
            }

            guard !spaceRanges.isEmpty else { continue }

            // Distribute remaining unused space evenly across all inter-word spaces
            // so text starts flush at the right edge and ends flush at the left edge.
            // Cap proportionally to font size (0.8 * fontSize) to scale naturally with zoom.
            let maxAllowedKern = max(18.0, fontSizeValue * 0.8)
            let extraKern = unusedWidth / CGFloat(spaceRanges.count)
            let appliedKern = min(extraKern, maxAllowedKern)
            for spaceRange in spaceRanges {
                textStorage.addAttribute(.kern, value: appliedKern, range: spaceRange)
            }
        }

        textStorage.endEditing()
    }
}

struct ContinuousArabicTextView: UIViewRepresentable {
    let verses: [TranslationArabicText]
    let arabicFontSize: FontSize
    var width: CGFloat = 0
    let scrollToVerse: AyahNumber?
    let scrollTriggerCount: Int
    var onLayoutCompleted: (([AyahNumber: [CGRect]], CGFloat) -> Void)? = nil

    func makeUIView(context: Context) -> BoundingBoxTextView {
        let textView = BoundingBoxTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.isUserInteractionEnabled = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .right
        textView.clipsToBounds = false
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.required, for: .vertical)
        return textView
    }

    func updateUIView(_ uiView: BoundingBoxTextView, context: Context) {
        uiView.verses = verses
        uiView.onLayoutCompleted = onLayoutCompleted
        if width > 0 {
            uiView.targetWidth = width
        }
        uiView.setScrollRequest(scrollToVerse, triggerCount: scrollTriggerCount)
        configureTextView(uiView)
        uiView.setNeedsLayout()
    }

    func configureTextView(_ uiView: BoundingBoxTextView) {
        let attributedString = NSMutableAttributedString()
        let fontSize = arabicFontSize.arabicFontSize()
        uiView.fontSizeValue = fontSize
        let font = UIFont(.quran, size: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        paragraphStyle.baseWritingDirection = .rightToLeft
        paragraphStyle.lineSpacing = max(6, fontSize * 0.16)

        for verse in verses {
            let verseText = verse.text + " "
            var attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.label,
                .paragraphStyle: paragraphStyle,
                NSAttributedString.Key(rawValue: kCTLanguageAttributeName as String): "ar",
            ]
            if let highlightColor = verse.highlightColor {
                attrs[.backgroundColor] = UIColor(highlightColor)
            }
            attributedString.append(NSAttributedString(string: verseText, attributes: attrs))
        }

        uiView.textAlignment = .right
        uiView.attributedText = attributedString
    }

    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: BoundingBoxTextView, context: Context) -> CGSize? {
        let width = proposal.width ?? (uiView.targetWidth > 0 ? uiView.targetWidth : 300)
        guard width > 0 else { return nil }
        uiView.targetWidth = width
        uiView.verses = verses
        configureTextView(uiView)
        return uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }
}


extension TranslationContinuousArabic: View {
    struct ContentView: View {
        let verses: [TranslationArabicText]
        let arabicFontSize: FontSize
        let scrollToVerse: AyahNumber?
        let scrollTriggerCount: Int

        @State private var verseFrames: [AyahNumber: [CGRect]] = [:]
        @State private var totalHeight: CGFloat

        init(verses: [TranslationArabicText], arabicFontSize: FontSize, scrollToVerse: AyahNumber?, scrollTriggerCount: Int) {
            self.verses = verses
            self.arabicFontSize = arabicFontSize
            self.scrollToVerse = scrollToVerse
            self.scrollTriggerCount = scrollTriggerCount

            let fontSize = arabicFontSize.arabicFontSize()
            let charPerLine = max(10.0, 45.0 / (fontSize / FontSize.defaultArabicMediumSize))
            let lineHeight = max(32.0, fontSize * 1.5)
            let totalChars = verses.reduce(0) { $0 + $1.text.count }
            let estimatedLines = max(1, ceil(CGFloat(totalChars) / charPerLine))
            _totalHeight = State(initialValue: max(100, estimatedLines * lineHeight))
        }

        var body: some View {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width

                ZStack(alignment: .topLeading) {
                    ContinuousArabicTextView(
                        verses: verses,
                        arabicFontSize: arabicFontSize,
                        width: availableWidth,
                        scrollToVerse: scrollToVerse,
                        scrollTriggerCount: scrollTriggerCount
                    ) { frames, height in
                        verseFrames = frames
                        if abs(totalHeight - height) > 0.5 {
                            totalHeight = height
                        }
                    }
                    .frame(width: availableWidth, height: totalHeight)

                    // Overlay transparent hit-test regions
                    ForEach(verses) { verse in
                        if let rects = verseFrames[verse.verse] {
                            ForEach(0 ..< rects.count, id: \.self) { i in
                                if i == 0 {
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .frame(width: rects[i].width, height: rects[i].height)
                                        .trackingTarget(item: TranslationItemId.arabic(verse.verse))
                                        .id(TranslationItemId.arabic(verse.verse))
                                        .position(x: rects[i].minX + rects[i].width / 2, y: rects[i].minY + rects[i].height / 2)
                                } else {
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .frame(width: rects[i].width, height: rects[i].height)
                                        .trackingTarget(item: TranslationItemId.arabic(verse.verse))
                                        .position(x: rects[i].minX + rects[i].width / 2, y: rects[i].minY + rects[i].height / 2)
                                }
                            }
                        }
                    }
                }
            }
            .environment(\.layoutDirection, .leftToRight)
            .frame(height: totalHeight)
        }
    }

    var body: some View {
        ContentView(verses: verses, arabicFontSize: arabicFontSize, scrollToVerse: scrollToVerse, scrollTriggerCount: scrollTriggerCount)
            .environment(\.layoutDirection, .leftToRight)
            .readableInsetsPadding(.horizontal)
    }
}

extension TranslationFrontispieceArabic: View {
    var body: some View {
        QuranFrontispieceView(
            suraName: sura.localizedName(withPrefix: false),
            besmAllah: sura.startsWithBesmAllah ? sura.quran.arabicBesmAllah : "",
            besmAllahFontSize: arabicFontSize
        ) {
            TranslationContinuousArabic.ContentView(
                verses: verses,
                arabicFontSize: arabicFontSize,
                scrollToVerse: scrollToVerse,
                scrollTriggerCount: scrollTriggerCount
            )
            .environment(\.layoutDirection, .leftToRight)
        }
    }
}

extension TranslationArabicText: View {
    var body: some View {
        ContinuousArabicTextView(
            verses: [self],
            arabicFontSize: arabicFontSize,
            scrollToVerse: nil,
            scrollTriggerCount: 0
        )
        .fixedSize(horizontal: false, vertical: true)
        .environment(\.layoutDirection, .rightToLeft)
        .padding(.bottom, 8)
        .padding(.top, 10)
        .readableInsetsPadding(.horizontal)
    }
}

extension TranslationAyahNumber: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(lFormat("translation.text.ayah-number", verse.sura.suraNumber, verse.ayah))
                .padding(8)
                .themedSecondaryForeground()
                .themedSecondaryBackground()
                .cornerRadius(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 5)
        .padding(.top, 10)
        .readableInsetsPadding(.horizontal)
    }
}

extension TranslationTextChunk {
    var readMoreURL: URL {
        TranslationURL.readMore(
            translationId: translation.id,
            sura: verse.sura.suraNumber,
            ayah: verse.ayah
        ).url
    }
}

extension TranslationTextChunk: View {
    var body: some View {
        TranslationTextChunkBody(
            verse: verse,
            showAyahBadge: showAyahBadge,
            badgeStartAyah: badgeStartAyah,
            text: text.text,
            chunk: chunks[chunkIndex],
            footnoteRanges: text.footnoteRanges,
            quranRanges: text.quranRanges,
            firstChunk: chunkIndex == 0,
            readMoreURL: readMore ? readMoreURL : nil,
            footnoteURL: { index in
                TranslationURL.footnote(
                    translationId: translation.id,
                    sura: verse.sura.suraNumber,
                    ayah: verse.ayah,
                    footnoteIndex: index
                ).url
            },
            translation: translation,
            translationFontSize: translationFontSize,
            translationFont: translationFont
        )
    }
}

private func translationUIFont(for translation: Translation, fontSize: FontSize, selection: TranslationFont) -> UIFont {
    let size = fontSize.translationFontSize
    if translation.languageCode == "ar" {
        return UIFont(.arabic, size: size)
    } else if translation.languageCode == "kn" || translation.languageCode == "kan" || translation.languageCode.hasPrefix("kn") {
        switch selection {
        case .kohinoor:
            return UIFont(name: "KohinoorKannada-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
        case .system:
            return UIFont.systemFont(ofSize: size)
        default: // notoSans
            return UIFont(.kannada, size: size)
        }
    } else {
        return UIFont.systemFont(ofSize: size)
    }
}



private func makeAyahBadgeImage(
    surah: Int,
    ayah: Int,
    startAyah: Int? = nil,
    font: UIFont,
    isRTL: Bool,
    backgroundColor: UIColor,
    textColor: UIColor
) -> (UIImage, CGRect) {
    let text = (startAyah != nil && startAyah != ayah) ? "\(surah):\(startAyah!)–\(ayah)" : "\(surah):\(ayah)"
    let maxBadgeSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 26 : 16
    let badgeFontSize = max(11, min(maxBadgeSize, font.pointSize * 0.62))
    let badgeFont = UIFont.monospacedDigitSystemFont(ofSize: badgeFontSize, weight: .semibold)
    let textSize = (text as NSString).size(withAttributes: [.font: badgeFont])

    let horizontalPadding: CGFloat = 6
    let verticalPadding: CGFloat = 2.5
    let badgeWidth = ceil(textSize.width + horizontalPadding * 2)
    let badgeHeight = ceil(textSize.height + verticalPadding * 2)
    let cornerRadius: CGFloat = 5

    let renderer = UIGraphicsImageRenderer(size: CGSize(width: badgeWidth, height: badgeHeight))
    let image = renderer.image { _ in
        let badgeRect = CGRect(x: 0, y: 0, width: badgeWidth, height: badgeHeight)
        let path = UIBezierPath(roundedRect: badgeRect, cornerRadius: cornerRadius)
        backgroundColor.setFill()
        path.fill()

        let textRect = CGRect(
            x: (badgeWidth - textSize.width) / 2,
            y: (badgeHeight - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        (text as NSString).draw(in: textRect, withAttributes: [
            .font: badgeFont,
            .foregroundColor: textColor,
        ])
    }

    let yOffset = round((font.capHeight - badgeHeight) / 2)
    let bounds = CGRect(x: 0, y: yOffset, width: badgeWidth, height: badgeHeight)
    return (image, bounds)
}

private struct TranslationTextChunkBody: View {
    @Environment(\.themeStyle) var themeStyle

    let verse: AyahNumber
    var showAyahBadge: Bool = false
    var badgeStartAyah: Int? = nil
    let text: String
    let chunk: Range<String.Index>
    let footnoteRanges: [Range<String.Index>]
    let quranRanges: [Range<String.Index>]
    let firstChunk: Bool
    let readMoreURL: URL?
    let footnoteURL: (Int) -> URL
    let translation: Translation
    let translationFontSize: FontSize
    let translationFont: TranslationFont

    @ScaledMetric var topPadding = 10
    private let baselineOffset: CGFloat = 5

    var body: some View {
        let isRTL = translation.characterDirection == .rightToLeft
        let font = translation.textFont(fontSize: translationFontSize, selection: translationFont.rawValue)
        let uiFont = translationUIFont(for: translation, fontSize: translationFontSize, selection: translationFont)

        textView(isRTL: isRTL, font: font, uiFont: uiFont)
            .textAlignment(follows: translation.characterDirection)
            .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
            .lineSpacing(max(5, translationFontSize.translationFontSize * 0.28))
            .padding(.top, firstChunk ? topPadding : 0)
            .readableInsetsPadding(.horizontal)
    }

    private static let translationTextColor = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.88, alpha: 1.0)
            : UIColor.label
    })

    @ViewBuilder
    private func textView(isRTL: Bool, font: Font, uiFont: UIFont) -> some View {
        if firstChunk && showAyahBadge {
            let (image, _) = makeAyahBadgeImage(
                surah: verse.sura.suraNumber,
                ayah: verse.ayah,
                startAyah: badgeStartAyah,
                font: uiFont,
                isRTL: isRTL,
                backgroundColor: themeStyle.secondaryBackgroundColor,
                textColor: themeStyle.secondaryTextColor
            )
            (Text(Image(uiImage: image)) + Text("  ") + Text(attributedString))
                .font(font)
                .foregroundColor(Self.translationTextColor)
        } else {
            (Text(verbatim: "") + Text(attributedString))
                .font(font)
                .foregroundColor(Self.translationTextColor)
        }
    }

    private var attributedString: AttributedString {
        let chunkText = text[chunk]

        var string = AttributedString(chunkText)
        string.foregroundColor = Self.translationTextColor
        let bodyFontSize = translationFontSize.translationFontSize
        let markerFontSize = max(13.0, round(bodyFontSize * 0.62))
        let markerFont = Font.system(size: markerFontSize, weight: .semibold)
        let markerOffset: CGFloat = max(5.0, round(bodyFontSize * 0.22))

        for (index, footnoteRange) in footnoteRanges.enumerated() {
            if let range = string.range(from: footnoteRange, overallRange: chunk, overallText: text) {
                string[range].link = footnoteURL(index)
                string[range].font = markerFont
                string[range].baselineOffset = markerOffset
            }
        }

        for quranRange in quranRanges {
            if let range = string.range(from: quranRange, overallRange: chunk, overallText: text) {
                string[range].foregroundColor = .accentColor
            }
        }

        if let readMoreURL {
            var readMore = AttributedString("\n\(l("translation.text.read-more"))")
            readMore.foregroundColor = .accentColor
            readMore.link = readMoreURL
            readMore.font = .body
            string.append(readMore)
        }

        return string
    }
}


extension TranslationReferenceVerse: View {
    var body: some View {
        QuranTranslationReferenceVerse(
            ayahNumber: showAyahBadge ? verse : nil,
            reference: reference,
            fontSize: translationFontSize,
            characterDirection: translation.characterDirection
        )
    }
}

extension TranslatorText: View {
    var body: some View {
        QuranTranslatorName(name: translation.translationName, fontSize: translationFontSize, characterDirection: translation.characterDirection)
    }
}

extension TranslationItem: View {
    @ViewBuilder
    private var content: some View {
        VStack {
            switch self {
            case .pageHeader(let pageHeader):
                pageHeader
            case .pageFooter(let pageFooter):
                pageFooter
            case .verseSeparator:
                QuranVerseSeparator()
            case .suraName(let suraName, _):
                suraName
            case .arabicText(let arabicText, _):
                arabicText
            case .continuousArabic(let continuousArabic):
                continuousArabic
            case .frontispieceArabic(let frontispieceArabic):
                frontispieceArabic
            case .translationAyahNumber(let translationAyahNumber, _):
                translationAyahNumber
            case .translationTextChunk(let translationTextChunk, _):
                translationTextChunk
            case .translationReferenceVerse(let translationReferenceVerse, _):
                translationReferenceVerse
            case .translatorText(let translatorText, _):
                translatorText
            }
        }
        .font(.footnote)
        .listRowSeparator(.hidden)
        .listRowInsets(.zero)
        .listRowBackground(Color.clear)
        .background(color)
    }

    var body: some View {
        if case .continuousArabic = id {
            content
        } else if case .frontispieceArabic = id {
            content
        } else {
            content.trackingTarget(item: id)
        }
    }
}

import NoorFont

#Preview {
    ContentTranslationPreview()
}

private struct ContentTranslationPreview: View {
    @State var readMore: Bool = true

    let quran = Quran.hafsMadani1405

    let fontSize = FontSize.large

    var translation: Translation {
        Translation(
            id: 1,
            displayName: "",
            translator: "",
            translatorForeign: "Khan & Hilai",
            fileURL: URL(validURL: "a"),
            fileName: "quran.en.khanhilali.db",
            languageCode: "",
            version: 5,
            installedVersion: 5
        )
    }

    var translationText: String {
        """
        Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
        """
    }

    var chunks: [Range<String.Index>] {
        translationText.chunkRanges(maxChunkSize: 70)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                TranslationItem.pageHeader(.init(page: quran.pages[0]))
                TranslationItem.suraName(.init(sura: quran.firstSura, arabicFontSize: fontSize), nil)
                TranslationItem.arabicText(.init(
                    verse: quran.firstVerse, text: quran.arabicBesmAllah, arabicFontSize: fontSize, highlightColor: nil
                ), nil)
                ForEach(0 ..< (readMore ? 1 : chunks.count), id: \.self) { chunkIndex in
                    TranslationItem.translationTextChunk(
                        .init(
                            verse: quran.firstVerse,
                            translation: translation,
                            text: .init(text: translationText, quranRanges: [], footnoteRanges: [], footnotes: []),
                            chunks: chunks,
                            chunkIndex: chunkIndex,
                            readMore: readMore && chunkIndex == 0,
                            translationFontSize: fontSize,
                            translationFont: .notoSans
                        ), nil
                    )
                }
                TranslationItem.translatorText(.init(verse: quran.firstVerse, translation: translation, translationFontSize: fontSize), nil)
                TranslationItem.verseSeparator(.init(verse: quran.firstVerse), nil)

                TranslationItem.translationReferenceVerse(.init(verse: quran.firstVerse, translation: translation, reference: quran.lastVerse, translationFontSize: .medium), nil)
                TranslationItem.verseSeparator(.init(verse: quran.firstVerse), nil)

                TranslationItem.pageFooter(.init(page: quran.firstVerse.page))
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 1)
            .populateReadableInsets()

            Button {
                readMore.toggle()
            } label: {
                Text("Toggle Read more")
            }
            .buttonStyle(.borderedProminent)
        }
        .ignoresSafeArea()
        .onAppear {
            FontName.registerFonts()
        }
    }
}

private extension UIView {
    func findParentScrollView() -> UIScrollView? {
        var current = superview
        while current != nil {
            if let scrollView = current as? UIScrollView {
                return scrollView
            }
            current = current?.superview
        }
        return nil
    }
}


