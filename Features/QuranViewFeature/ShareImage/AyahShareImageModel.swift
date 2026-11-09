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
        let isKannada = AppLanguage == .kannada || Locale.current.languageCode == "kn"
        switch self {
        case .square: return isKannada ? "ಚೌಕ (1:1)" : "1:1 Square"
        case .portrait: return isKannada ? "ಭಾವಚಿತ್ರ (4:5)" : "4:5 Portrait"
        case .story: return isKannada ? "ಕಥೆ (9:16)" : "9:16 Story"
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

public enum AyahShareCaptionMode: String, CaseIterable, Identifiable {
    case imageOnly = "image_only"
    case linkOnly = "link_only"
    case fullText = "full_text"

    public var id: String { rawValue }

    public var displayName: String {
        let isKannada = AppLanguage == .kannada || Locale.current.languageCode == "kn"
        switch self {
        case .imageOnly: return isKannada ? "ಚಿತ್ರ ಮಾತ್ರ" : "Image Only"
        case .linkOnly: return isKannada ? "ಲಿಂಕ್ ಮಾತ್ರ" : "Link Only"
        case .fullText: return isKannada ? "ಸಂಪೂರ್ಣ ಪಠ್ಯ" : "Full Text"
        }
    }
}

public enum AyahCardTextColorTarget: String, CaseIterable, Identifiable {
    case arabic = "arabic"
    case translation = "translation"

    public var id: String { rawValue }

    public var displayName: String {
        let isKannada = AppLanguage == .kannada || Locale.current.languageCode == "kn"
        switch self {
        case .arabic: return isKannada ? "ಅರೇಬಿಕ್" : "Arabic"
        case .translation: return isKannada ? "ಅನುವಾದ" : "Translation"
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
        let isKannada = AppLanguage == .kannada || Locale.current.languageCode == "kn"
        switch self {
        case .uthmanic: return isKannada ? "ಉಸ್ಮಾನಿ" : "Uthmanic"
        case .kitab: return isKannada ? "ಕಿತಾಬ್" : "Kitab"
        case .geezaPro: return isKannada ? "ಗೀಝಾ" : "Geeza Pro"
        case .mishafi: return isKannada ? "ಮಿಶಫಿ" : "Mishafi"
        case .system: return isKannada ? "ಸಿಸ್ಟಮ್" : "System"
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
}

public enum AyahCardTranslationFont: String, CaseIterable, Identifiable {
    case notoSerif = "noto_serif"
    case notoSans = "noto_sans"
    case bold = "bold"
    case system = "system"

    public var id: String { rawValue }

    public var displayName: String {
        let isKannada = AppLanguage == .kannada || Locale.current.languageCode == "kn"
        switch self {
        case .notoSerif: return isKannada ? "ಸೀರಿಫ್" : "Serif"
        case .notoSans: return isKannada ? "ಸಾನ್ಸ್" : "Sans"
        case .bold: return isKannada ? "ದಪ್ಪ" : "Bold"
        case .system: return isKannada ? "ಸಿಸ್ಟಮ್" : "System"
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
        let isKannada = AppLanguage == .kannada || Locale.current.languageCode == "kn"
        switch self {
        case .themeDefault: return isKannada ? "ಸ್ವಯಂ" : "Default"
        case .classicGold: return isKannada ? "ಚಿನ್ನ" : "Gold"
        case .pureWhite: return isKannada ? "ಬಿಳಿ" : "White"
        case .iceCyan: return isKannada ? "ನೀಲಿ" : "Ice Blue"
        case .emeraldMint: return isKannada ? "ಪಚ್ಚೆ" : "Mint"
        case .sunsetAmber: return isKannada ? "ಅಂಬರ್" : "Amber"
        case .roseGold: return isKannada ? "ಗುಲಾಬಿ" : "Rose"
        case .royalLavender: return isKannada ? "ನೇರಳೆ" : "Lavender"
        case .custom: return isKannada ? "ಕಸ್ಟಮ್" : "Custom"
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

    // Photo backgrounds
    case mosqueDusk = "mosque_dusk"
    case makkahNight = "makkah_night"
    case nabawiEvening = "nabawi_evening"
    case desertSunset = "desert_sunset"
    case starryNight = "starry_night"
    case mistyMountains = "misty_mountains"
    case sacredArches = "sacred_arches"
    case oceanSunset = "ocean_sunset"
    case customPhoto = "custom_photo"

    public var id: String { rawValue }

    public static var colorThemes: [AyahCardTheme] {
        [.emerald, .midnight, .royal, .sunset, .olive, .parchment, .minimal]
    }

    public static var photoThemes: [AyahCardTheme] {
        [
            .mosqueDusk,
            .makkahNight,
            .nabawiEvening,
            .desertSunset,
            .starryNight,
            .mistyMountains,
            .sacredArches,
            .oceanSunset,
        ]
    }

    public var isPhoto: Bool {
        switch self {
        case .mosqueDusk, .makkahNight, .nabawiEvening, .desertSunset,
             .starryNight, .mistyMountains, .sacredArches, .oceanSunset, .customPhoto:
            return true
        default:
            return false
        }
    }

    public var imageName: String? {
        switch self {
        case .mosqueDusk: return "bg_mosque"
        case .makkahNight: return "bg_makkah"
        case .nabawiEvening: return "bg_nabawi"
        case .desertSunset: return "bg_desert"
        case .starryNight: return "bg_stars"
        case .mistyMountains: return "bg_mountains"
        case .sacredArches: return "bg_arches"
        case .oceanSunset: return "bg_ocean"
        case .customPhoto: return nil
        default: return nil
        }
    }

    public var displayName: String {
        let isKannada = AppLanguage == .kannada || Locale.current.languageCode == "kn"
        switch self {
        case .emerald: return isKannada ? "ಪಚ್ಚೆ ಹಸಿರು" : "Emerald"
        case .midnight: return isKannada ? "ಮಧ್ಯರಾತ್ರಿ" : "Midnight"
        case .royal: return isKannada ? "ರಾಜ ನೀಲಿ" : "Royal Blue"
        case .sunset: return isKannada ? "ಸಂಧ್ಯಾ ಕೆಂಪು" : "Sunset"
        case .olive: return isKannada ? "ಆಲಿವ್ ಹಸಿರು" : "Olive"
        case .parchment: return isKannada ? "ಕಾಗದ" : "Parchment"
        case .minimal: return isKannada ? "ಶುಭ್ರ ಬಿಳಿ" : "Minimal"
        case .mosqueDusk: return isKannada ? "ಮಸೀದಿ ಸಂಜೆ" : "Mosque Dusk"
        case .makkahNight: return isKannada ? "ಕಾಬಾ ಶರೀಫ್" : "Holy Kaaba"
        case .nabawiEvening: return isKannada ? "ಮಸ್ಜಿದುನ್ನಬವಿ" : "Prophet's Mosque"
        case .desertSunset: return isKannada ? "ಮರುಭೂಮಿ" : "Desert Dunes"
        case .starryNight: return isKannada ? "ನಕ್ಷತ್ರ ಲೋಕ" : "Starry Night"
        case .mistyMountains: return isKannada ? "ಪರ್ವತಗಳು" : "Mountains"
        case .sacredArches: return isKannada ? "ಕಮಾನುಗಳು" : "Sacred Arches"
        case .oceanSunset: return isKannada ? "ಸಮುದ್ರ ಸಂಜೆ" : "Ocean Sunset"
        case .customPhoto: return isKannada ? "ನಿಮ್ಮ ಫೋಟೋ" : "My Photo"
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
        case .mosqueDusk: return Color(red: 0.78, green: 0.40, blue: 0.12)
        case .makkahNight: return Color(red: 0.15, green: 0.18, blue: 0.22)
        case .nabawiEvening: return Color(red: 0.35, green: 0.25, blue: 0.40)
        case .desertSunset: return Color(red: 0.75, green: 0.52, blue: 0.25)
        case .starryNight: return Color(red: 0.20, green: 0.25, blue: 0.45)
        case .mistyMountains: return Color(red: 0.25, green: 0.35, blue: 0.40)
        case .sacredArches: return Color(red: 0.55, green: 0.38, blue: 0.25)
        case .oceanSunset: return Color(red: 0.70, green: 0.30, blue: 0.25)
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
        case .mosqueDusk, .makkahNight, .nabawiEvening, .desertSunset,
             .starryNight, .mistyMountains, .sacredArches, .oceanSunset, .customPhoto:
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
        case .starryNight: return Color.white.opacity(0.25)
        case .mosqueDusk, .makkahNight, .nabawiEvening, .desertSunset,
             .mistyMountains, .sacredArches, .oceanSunset, .customPhoto:
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
        case .starryNight: return Color.white.opacity(0.12)
        case .mosqueDusk, .makkahNight, .nabawiEvening, .desertSunset,
             .mistyMountains, .sacredArches, .oceanSunset, .customPhoto:
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
        case .starryNight: return Color(red: 0.98, green: 0.98, blue: 1.00)
        case .mosqueDusk, .makkahNight, .nabawiEvening, .desertSunset,
             .mistyMountains, .sacredArches, .oceanSunset, .customPhoto:
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
        case .mosqueDusk, .makkahNight, .nabawiEvening, .desertSunset,
             .starryNight, .mistyMountains, .sacredArches, .oceanSunset, .customPhoto:
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
        case .starryNight: return Color.white.opacity(0.15)
        case .mosqueDusk, .makkahNight, .nabawiEvening, .desertSunset,
             .mistyMountains, .sacredArches, .oceanSunset, .customPhoto:
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
        case .starryNight: return Color(red: 0.85, green: 0.92, blue: 1.00)
        case .mosqueDusk, .makkahNight, .nabawiEvening, .desertSunset,
             .mistyMountains, .sacredArches, .oceanSunset, .customPhoto:
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
        case .starryNight: return Color.white.opacity(0.35)
        case .mosqueDusk, .makkahNight, .nabawiEvening, .desertSunset,
             .mistyMountains, .sacredArches, .oceanSunset, .customPhoto:
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
        case .mosqueDusk, .makkahNight, .nabawiEvening, .desertSunset,
             .starryNight, .mistyMountains, .sacredArches, .oceanSunset, .customPhoto:
            return Color.white.opacity(0.75)
        }
    }
}

public struct AyahCardData: Equatable {
    public let suraName: String
    public let suraNumber: Int
    public let ayahRangeString: String
    public let referenceText: String
    public let arabicText: String
    public let translationText: String
    public let translator: String?
    public let footnotes: [String]?

    public init(
        suraName: String,
        suraNumber: Int,
        ayahRangeString: String,
        referenceText: String,
        arabicText: String,
        translationText: String,
        translator: String?,
        footnotes: [String]? = nil
    ) {
        self.suraName = suraName
        self.suraNumber = suraNumber
        self.ayahRangeString = ayahRangeString
        self.referenceText = referenceText
        self.arabicText = arabicText
        self.translationText = translationText
        self.translator = translator
        self.footnotes = footnotes
    }
}
