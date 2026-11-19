//
//  AyahShareImageModel.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import Localization
import SwiftUI

public enum AyahCardAspectRatio: String, CaseIterable, Identifiable {
    case square = "1:1"
    case portrait = "4:5"
    case story = "9:16"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .square: return lChoice(kn: "ಚೌಕ (1:1)", en: "1:1 Square", ar: "مربع 1:1")
        case .portrait: return lChoice(kn: "ಭಾವಚಿತ್ರ (4:5)", en: "4:5 Portrait", ar: "عمودي 4:5")
        case .story: return lChoice(kn: "ಕಥೆ (9:16)", en: "9:16 Story", ar: "قصة 9:16")
        }
    }

    public var shortLabel: String {
        switch self {
        case .square: return "1:1"
        case .portrait: return "4:5"
        case .story: return "9:16"
        }
    }

    public func height(for width: CGFloat) -> CGFloat {
        switch self {
        case .square: return width // 1080 x 1080
        case .portrait: return width * 1.25 // 1080 x 1350
        case .story: return width * (16.0 / 9.0) // 1080 x 1920
        }
    }
}

public enum AyahVideoExportQuality: String, CaseIterable, Identifiable, Sendable {
    case standard720p = "720p"
    case high1080p = "1080p"

    public var id: String { rawValue }

    public var maxWidth: Int {
        switch self {
        case .standard720p: return 720
        case .high1080p: return 1080
        }
    }

    public var displayName: String {
        switch self {
        case .standard720p:
            return lChoice(kn: "ಸ್ಟ್ಯಾಂಡರ್ಡ್ · 720p", en: "Standard · 720p", ar: "قياسي · 720p")
        case .high1080p:
            return lChoice(kn: "ಹೈ · 1080p", en: "High · 1080p", ar: "عالي · 1080p")
        }
    }
}

public enum RemoteVideoResolutionFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case hd1080p = "hd_1080p"
    case standard720p = "standard_720p"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .all:
            return lChoice(kn: "ಎಲ್ಲಾ", en: "All", ar: "الكل")
        case .hd1080p:
            return "HD 1080p"
        case .standard720p:
            return "720p"
        }
    }
}

public enum AyahShareCaptionMode: String, CaseIterable, Identifiable {
    case imageOnly = "image_only"
    case linkOnly = "link_only"
    case fullText = "full_text"

    public var id: String { rawValue }

    public var displayName: String {
        displayName(isVideoMode: false)
    }

    public func displayName(isVideoMode: Bool) -> String {
        switch self {
        case .imageOnly:
            return isVideoMode
                ? lChoice(kn: "ಮಾಧ್ಯಮ ಮಾತ್ರ", en: "Video Only", ar: "الفيديو فقط")
                : lChoice(kn: "ಚಿತ್ರ ಮಾತ್ರ", en: "Image Only", ar: "الصورة فقط")
        case .linkOnly:
            return lChoice(kn: "ಲಿಂಕ್ ಮಾತ್ರ", en: "Link Only", ar: "الرابط فقط")
        case .fullText:
            return lChoice(kn: "ಸಂಪೂರ್ಣ ಪಠ್ಯ", en: "Full Text", ar: "النص الكامل")
        }
    }
}

public enum AyahCardTextColorTarget: String, CaseIterable, Identifiable {
    case arabic = "arabic"
    case translation = "translation"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .arabic: return lChoice(kn: "ಅರೇಬಿಕ್", en: "Arabic", ar: "العربية")
        case .translation: return lChoice(kn: "ಅನುವಾದ", en: "Translation", ar: "الترجمة")
        }
    }
}

public enum AyahCardArabicFont: String, CaseIterable, Identifiable {
    case uthmanic = "uthmanic"
    case kitab = "kitab"
    case geezaPro = "geeza_pro"
    case mishafi = "mishafi"
    case system = "system"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .uthmanic: return lChoice(kn: "ಉಸ್ಮಾನಿ", en: "Uthmanic", ar: "عثماني")
        case .kitab: return lChoice(kn: "ಕಿತಾಬ್", en: "Kitab", ar: "كتاب")
        case .geezaPro: return lChoice(kn: "ಗೀಝಾ", en: "Geeza Pro", ar: "جيزا برو")
        case .mishafi: return lChoice(kn: "ಮಿಶಫಿ", en: "Mishafi", ar: "مصحفي")
        case .system: return lChoice(kn: "ಸಿಸ್ಟಮ್", en: "System", ar: "النظام")
        }
    }

    public func font(size: CGFloat) -> Font {
        switch self {
        case .uthmanic:
            return .custom("KFGQPCHAFSUthmanicScript-Bold", size: size)
        case .kitab:
            return .custom("Kitab-Regular", size: size)
        case .geezaPro:
            return .custom("GeezaPro", size: size)
        case .mishafi:
            return .custom("DiwanMishafi", size: size)
        case .system:
            return .system(size: size, weight: .regular)
        }
    }

    public func formattedArabicTextView(_ text: String, size: CGFloat) -> Text {
        guard self != .uthmanic else {
            return Text(text).font(font(size: size))
        }
        let mainFont = font(size: size)
        let rosetteFont = AyahCardArabicFont.uthmanic.font(size: size)
        guard let regex = try? NSRegularExpression(pattern: "\u{00A0}([٠-٩]+)") else {
            return Text(text).font(mainFont)
        }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        if matches.isEmpty {
            return Text(text).font(mainFont)
        }
        var result = Text("")
        var currentLocation = 0
        for match in matches {
            let numRange = match.range(at: 1)
            if numRange.location > currentLocation {
                let prefixRange = NSRange(location: currentLocation, length: numRange.location - currentLocation)
                result = result + Text(nsText.substring(with: prefixRange)).font(mainFont)
            }
            result = result + Text(nsText.substring(with: numRange)).font(rosetteFont)
            currentLocation = numRange.location + numRange.length
        }
        if currentLocation < nsText.length {
            let suffixRange = NSRange(location: currentLocation, length: nsText.length - currentLocation)
            result = result + Text(nsText.substring(with: suffixRange)).font(mainFont)
        }
        return result
    }
}

public enum AyahCardTranslationFont: String, CaseIterable, Identifiable {
    case notoSerif = "noto_serif"
    case notoSans = "noto_sans"
    case bold = "bold"
    case system = "system"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .notoSerif: return lChoice(kn: "ಸೀರಿಫ್", en: "Serif", ar: "سيريف")
        case .notoSans: return lChoice(kn: "ಸಾನ್ಸ್", en: "Sans", ar: "سانس")
        case .bold: return lChoice(kn: "ದಪ್ಪ", en: "Bold", ar: "عريض")
        case .system: return lChoice(kn: "ಸಿಸ್ಟಮ್", en: "System", ar: "النظام")
        }
    }

    public func font(size: CGFloat) -> Font {
        switch self {
        case .notoSerif:
            return .custom("NotoSerifKannada-Regular", size: size)
        case .notoSans:
            return .custom("NotoSansKannada-Regular", size: size)
        case .bold:
            return .custom("NotoSansKannada-Bold", size: size)
        case .system:
            return .system(size: size, weight: .regular)
        }
    }
}

public enum AyahCardTextColorScheme: String, CaseIterable, Identifiable {
    case themeDefault = "default"
    case classicGold = "gold"
    case pureWhite = "white"
    case iceCyan = "cyan"
    case emeraldMint = "mint"
    case sunsetAmber = "amber"
    case roseGold = "rose"
    case royalLavender = "lavender"
    case custom = "custom"

    public var id: String { rawValue }

    public static var presets: [AyahCardTextColorScheme] {
        [.themeDefault, .classicGold, .pureWhite, .iceCyan, .emeraldMint, .sunsetAmber, .roseGold, .royalLavender]
    }

    public var displayName: String {
        switch self {
        case .themeDefault: return lChoice(kn: "ಸ್ವಯಂ", en: "Default", ar: "تلقائي")
        case .classicGold: return lChoice(kn: "ಚಿನ್ನ", en: "Gold", ar: "ذهبي")
        case .pureWhite: return lChoice(kn: "ಬಿಳಿ", en: "White", ar: "أبيض")
        case .iceCyan: return lChoice(kn: "ನೀಲಿ", en: "Ice Blue", ar: "سماوي")
        case .emeraldMint: return lChoice(kn: "ಪಚ್ಚೆ", en: "Mint", ar: "نعناعي")
        case .sunsetAmber: return lChoice(kn: "ಅಂಬರ್", en: "Amber", ar: "كهرماني")
        case .roseGold: return lChoice(kn: "ಗುಲಾಬಿ", en: "Rose", ar: "وردي")
        case .royalLavender: return lChoice(kn: "ನೇರಳೆ", en: "Lavender", ar: "أرجواني")
        case .custom: return lChoice(kn: "ಕಸ್ಟಮ್", en: "Custom", ar: "مخصص")
        }
    }

    public var previewColor: Color {
        switch self {
        case .themeDefault: return Color(red: 0.55, green: 0.58, blue: 0.65)
        case .classicGold: return Color(red: 1.00, green: 0.90, blue: 0.55)
        case .pureWhite: return Color.white
        case .iceCyan: return Color(red: 0.55, green: 0.88, blue: 1.00)
        case .emeraldMint: return Color(red: 0.52, green: 0.94, blue: 0.72)
        case .sunsetAmber: return Color(red: 1.00, green: 0.73, blue: 0.45)
        case .roseGold: return Color(red: 0.99, green: 0.65, blue: 0.69)
        case .royalLavender: return Color(red: 0.82, green: 0.78, blue: 0.98)
        case .custom: return Color.accentColor
        }
    }
}

public enum AyahCardTheme: String, CaseIterable, Identifiable {
    // Colors
    case emerald = "emerald"
    case midnight = "midnight"
    case royal = "royal"
    case sunset = "sunset"
    case olive = "olive"
    case parchment = "parchment"
    case minimal = "minimal"

    // Cloud / custom photo background
    case customPhoto = "custom_photo"

    public var id: String { rawValue }

    public static var colorThemes: [AyahCardTheme] {
        [.emerald, .midnight, .royal, .sunset, .olive, .parchment, .minimal]
    }

    public var isPhoto: Bool {
        self == .customPhoto
    }

    public var displayName: String {
        switch self {
        case .emerald: return lChoice(kn: "ಪಚ್ಚೆ ಹಸಿರು", en: "Emerald", ar: "زمردي")
        case .midnight: return lChoice(kn: "ಮಧ್ಯರಾತ್ರಿ", en: "Midnight", ar: "منتصف الليل")
        case .royal: return lChoice(kn: "ರಾಜ ನೀಲಿ", en: "Royal Blue", ar: "أزرق ملكي")
        case .sunset: return lChoice(kn: "ಸಂಧ್ಯಾ ಕೆಂಪು", en: "Sunset", ar: "الغروب")
        case .olive: return lChoice(kn: "ಆಲಿವ್ ಹಸಿರು", en: "Olive", ar: "زيتوني")
        case .parchment: return lChoice(kn: "ಕಾಗದ", en: "Parchment", ar: "رق")
        case .minimal: return lChoice(kn: "ಶುಭ್ರ ಬಿಳಿ", en: "Minimal", ar: "بسيط")
        case .customPhoto: return lChoice(kn: "ಕ್ಲೌಡ್ ಚಿತ್ರ", en: "Cloud Photo", ar: "صورة سحابية")
        }
    }

    public var iconColor: Color {
        switch self {
        case .emerald: return Color(red: 0.02, green: 0.35, blue: 0.25)
        case .midnight: return Color(red: 0.08, green: 0.12, blue: 0.22)
        case .royal: return Color(red: 0.08, green: 0.20, blue: 0.45)
        case .sunset: return Color(red: 0.45, green: 0.12, blue: 0.18)
        case .olive: return Color(red: 0.22, green: 0.30, blue: 0.18)
        case .parchment: return Color(red: 0.95, green: 0.91, blue: 0.82)
        case .minimal: return Color.white
        case .customPhoto: return Color.accentColor
        }
    }

    public var backgroundGradient: LinearGradient {
        switch self {
        case .emerald:
            return LinearGradient(
                colors: [Color(red: 0.03, green: 0.28, blue: 0.20), Color(red: 0.01, green: 0.15, blue: 0.11)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .midnight:
            return LinearGradient(
                colors: [Color(red: 0.07, green: 0.10, blue: 0.18), Color(red: 0.02, green: 0.03, blue: 0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .royal:
            return LinearGradient(
                colors: [Color(red: 0.06, green: 0.16, blue: 0.36), Color(red: 0.02, green: 0.06, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sunset:
            return LinearGradient(
                colors: [Color(red: 0.40, green: 0.10, blue: 0.18), Color(red: 0.18, green: 0.04, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .olive:
            return LinearGradient(
                colors: [Color(red: 0.20, green: 0.28, blue: 0.18), Color(red: 0.09, green: 0.14, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .parchment:
            return LinearGradient(
                colors: [Color(red: 0.98, green: 0.96, blue: 0.90), Color(red: 0.93, green: 0.89, blue: 0.79)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .minimal:
            return LinearGradient(
                colors: [Color.white, Color(red: 0.97, green: 0.97, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .customPhoto:
            return LinearGradient(
                colors: [Color(red: 0.10, green: 0.12, blue: 0.16), Color(red: 0.04, green: 0.05, blue: 0.07)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    public var borderColor: Color {
        switch self {
        case .emerald: return Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.4)
        case .midnight: return Color.white.opacity(0.15)
        case .royal: return Color(red: 0.65, green: 0.80, blue: 0.98).opacity(0.35)
        case .sunset: return Color(red: 0.95, green: 0.75, blue: 0.40).opacity(0.45)
        case .olive: return Color(red: 0.82, green: 0.75, blue: 0.45).opacity(0.35)
        case .parchment: return Color(red: 0.60, green: 0.45, blue: 0.25).opacity(0.3)
        case .minimal: return Color.black.opacity(0.08)
        case .customPhoto:
            return Color(red: 0.95, green: 0.80, blue: 0.45).opacity(0.45)
        }
    }

    public var innerBorderColor: Color {
        switch self {
        case .emerald: return Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.2)
        case .midnight: return Color.white.opacity(0.08)
        case .royal: return Color(red: 0.65, green: 0.80, blue: 0.98).opacity(0.18)
        case .sunset: return Color(red: 0.95, green: 0.75, blue: 0.40).opacity(0.22)
        case .olive: return Color(red: 0.82, green: 0.75, blue: 0.45).opacity(0.18)
        case .parchment: return Color(red: 0.60, green: 0.45, blue: 0.25).opacity(0.15)
        case .minimal: return Color.black.opacity(0.04)
        case .customPhoto:
            return Color(red: 0.95, green: 0.80, blue: 0.45).opacity(0.25)
        }
    }

    public var arabicTextColor: Color {
        switch self {
        case .emerald: return Color(red: 0.99, green: 0.94, blue: 0.75) // warm gold cream
        case .midnight: return Color(red: 0.93, green: 0.95, blue: 0.98)
        case .royal: return Color(red: 0.95, green: 0.97, blue: 1.00)
        case .sunset: return Color(red: 1.00, green: 0.94, blue: 0.82)
        case .olive: return Color(red: 0.98, green: 0.96, blue: 0.85)
        case .parchment: return Color(red: 0.12, green: 0.10, blue: 0.08)
        case .minimal: return Color(red: 0.08, green: 0.10, blue: 0.16)
        case .customPhoto:
            return Color(red: 1.00, green: 0.95, blue: 0.80)
        }
    }

    public var translationTextColor: Color {
        switch self {
        case .emerald: return Color.white.opacity(0.95)
        case .midnight: return Color.white.opacity(0.90)
        case .royal: return Color.white.opacity(0.92)
        case .sunset: return Color.white.opacity(0.95)
        case .olive: return Color.white.opacity(0.92)
        case .parchment: return Color(red: 0.20, green: 0.16, blue: 0.13)
        case .minimal: return Color(red: 0.20, green: 0.25, blue: 0.30)
        case .customPhoto:
            return Color.white.opacity(0.95)
        }
    }

    public var badgeBackground: Color {
        switch self {
        case .emerald: return Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.20)
        case .midnight: return Color.white.opacity(0.12)
        case .royal: return Color(red: 0.40, green: 0.65, blue: 0.95).opacity(0.22)
        case .sunset: return Color(red: 0.95, green: 0.75, blue: 0.40).opacity(0.25)
        case .olive: return Color(red: 0.82, green: 0.75, blue: 0.45).opacity(0.20)
        case .parchment: return Color(red: 0.60, green: 0.45, blue: 0.25).opacity(0.15)
        case .minimal: return Color.black.opacity(0.06)
        case .customPhoto:
            return Color.black.opacity(0.40)
        }
    }

    public var badgeTextColor: Color {
        switch self {
        case .emerald: return Color(red: 0.99, green: 0.88, blue: 0.55)
        case .midnight: return Color(red: 0.80, green: 0.85, blue: 0.95)
        case .royal: return Color(red: 0.80, green: 0.90, blue: 1.00)
        case .sunset: return Color(red: 1.00, green: 0.90, blue: 0.65)
        case .olive: return Color(red: 0.95, green: 0.90, blue: 0.65)
        case .parchment: return Color(red: 0.45, green: 0.30, blue: 0.15)
        case .minimal: return Color(red: 0.25, green: 0.30, blue: 0.40)
        case .customPhoto:
            return Color(red: 1.00, green: 0.88, blue: 0.55)
        }
    }

    public var dividerColor: Color {
        switch self {
        case .emerald: return Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.4)
        case .midnight: return Color.white.opacity(0.2)
        case .royal: return Color(red: 0.65, green: 0.80, blue: 0.98).opacity(0.35)
        case .sunset: return Color(red: 0.95, green: 0.75, blue: 0.40).opacity(0.4)
        case .olive: return Color(red: 0.82, green: 0.75, blue: 0.45).opacity(0.35)
        case .parchment: return Color(red: 0.60, green: 0.45, blue: 0.25).opacity(0.35)
        case .minimal: return Color.black.opacity(0.12)
        case .customPhoto:
            return Color(red: 1.00, green: 0.85, blue: 0.50).opacity(0.5)
        }
    }

    public var footerTextColor: Color {
        switch self {
        case .emerald: return Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.7)
        case .midnight: return Color.white.opacity(0.45)
        case .royal: return Color(red: 0.75, green: 0.85, blue: 1.00).opacity(0.65)
        case .sunset: return Color(red: 0.95, green: 0.80, blue: 0.60).opacity(0.75)
        case .olive: return Color(red: 0.85, green: 0.80, blue: 0.60).opacity(0.7)
        case .parchment: return Color(red: 0.50, green: 0.40, blue: 0.30).opacity(0.8)
        case .minimal: return Color.black.opacity(0.4)
        case .customPhoto:
            return Color.white.opacity(0.75)
        }
    }
}

public struct AyahSlideData: Equatable {
    public let suraNumber: Int
    public let ayahNumber: Int
    public let suraName: String
    public let ayahRangeString: String
    public let referenceText: String
    public let arabicText: String
    public let translationText: String
    public let translationTextWithFootnotes: String?
    public let footnotes: [String]?

    public init(
        suraNumber: Int,
        ayahNumber: Int,
        suraName: String,
        ayahRangeString: String,
        referenceText: String,
        arabicText: String,
        translationText: String,
        translationTextWithFootnotes: String? = nil,
        footnotes: [String]? = nil
    ) {
        self.suraNumber = suraNumber
        self.ayahNumber = ayahNumber
        self.suraName = suraName
        self.ayahRangeString = ayahRangeString
        self.referenceText = referenceText
        self.arabicText = arabicText
        self.translationText = translationText
        self.translationTextWithFootnotes = translationTextWithFootnotes
        self.footnotes = footnotes
    }

    public func toCardData(translator: String?) -> AyahCardData {
        AyahCardData(
            suraName: suraName,
            suraNumber: suraNumber,
            ayahRangeString: ayahRangeString,
            referenceText: referenceText,
            arabicText: arabicText,
            translationText: translationText,
            translationTextWithFootnotes: translationTextWithFootnotes,
            translator: translator,
            footnotes: footnotes,
            ayahSlides: [self]
        )
    }
}

public struct AyahCardData: Equatable {
    public let suraName: String
    public let suraNumber: Int
    public let ayahRangeString: String
    public let referenceText: String
    public let arabicText: String
    public let translationText: String
    public let translationTextWithFootnotes: String?
    public let translator: String?
    public let footnotes: [String]?
    public let ayahSlides: [AyahSlideData]

    public init(
        suraName: String,
        suraNumber: Int,
        ayahRangeString: String,
        referenceText: String,
        arabicText: String,
        translationText: String,
        translationTextWithFootnotes: String? = nil,
        translator: String?,
        footnotes: [String]? = nil,
        ayahSlides: [AyahSlideData] = []
    ) {
        self.suraName = suraName
        self.suraNumber = suraNumber
        self.ayahRangeString = ayahRangeString
        self.referenceText = referenceText
        self.arabicText = arabicText
        self.translationText = translationText
        self.translationTextWithFootnotes = translationTextWithFootnotes
        self.translator = translator
        self.footnotes = footnotes
        self.ayahSlides = ayahSlides
    }
}
