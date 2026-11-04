//
//  AyahShareImageModel.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import Localization
import SwiftUI

public enum AyahCardTheme: String, CaseIterable, Identifiable {
    case emerald = "emerald"
    case midnight = "midnight"
    case parchment = "parchment"
    case minimal = "minimal"

    public var id: String { rawValue }

    public var displayName: String {
        let isKannada = AppLanguage == .kannada || Locale.current.languageCode == "kn"
        switch self {
        case .emerald: return isKannada ? "ಪಚ್ಚೆ ಹಸಿರು" : "Emerald"
        case .midnight: return isKannada ? "ಮಧ್ಯರಾತ್ರಿ" : "Midnight"
        case .parchment: return isKannada ? "ಕಾಗದ" : "Parchment"
        case .minimal: return isKannada ? "ಶುಭ್ರ ಬಿಳಿ" : "Minimal"
        }
    }

    public var iconColor: Color {
        switch self {
        case .emerald: return Color(red: 0.02, green: 0.35, blue: 0.25)
        case .midnight: return Color(red: 0.08, green: 0.12, blue: 0.22)
        case .parchment: return Color(red: 0.95, green: 0.91, blue: 0.82)
        case .minimal: return Color.white
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
        }
    }

    public var borderColor: Color {
        switch self {
        case .emerald: return Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.4)
        case .midnight: return Color.white.opacity(0.15)
        case .parchment: return Color(red: 0.60, green: 0.45, blue: 0.25).opacity(0.3)
        case .minimal: return Color.black.opacity(0.08)
        }
    }

    public var innerBorderColor: Color {
        switch self {
        case .emerald: return Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.2)
        case .midnight: return Color.white.opacity(0.08)
        case .parchment: return Color(red: 0.60, green: 0.45, blue: 0.25).opacity(0.15)
        case .minimal: return Color.black.opacity(0.04)
        }
    }

    public var arabicTextColor: Color {
        switch self {
        case .emerald: return Color(red: 0.99, green: 0.94, blue: 0.75) // warm gold cream
        case .midnight: return Color(red: 0.93, green: 0.95, blue: 0.98)
        case .parchment: return Color(red: 0.12, green: 0.10, blue: 0.08)
        case .minimal: return Color(red: 0.08, green: 0.10, blue: 0.16)
        }
    }

    public var translationTextColor: Color {
        switch self {
        case .emerald: return Color.white.opacity(0.95)
        case .midnight: return Color.white.opacity(0.90)
        case .parchment: return Color(red: 0.20, green: 0.16, blue: 0.13)
        case .minimal: return Color(red: 0.20, green: 0.25, blue: 0.30)
        }
    }

    public var badgeBackground: Color {
        switch self {
        case .emerald: return Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.20)
        case .midnight: return Color.white.opacity(0.12)
        case .parchment: return Color(red: 0.60, green: 0.45, blue: 0.25).opacity(0.15)
        case .minimal: return Color.black.opacity(0.06)
        }
    }

    public var badgeTextColor: Color {
        switch self {
        case .emerald: return Color(red: 0.99, green: 0.88, blue: 0.55)
        case .midnight: return Color(red: 0.80, green: 0.85, blue: 0.95)
        case .parchment: return Color(red: 0.45, green: 0.30, blue: 0.15)
        case .minimal: return Color(red: 0.25, green: 0.30, blue: 0.40)
        }
    }

    public var dividerColor: Color {
        switch self {
        case .emerald: return Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.4)
        case .midnight: return Color.white.opacity(0.2)
        case .parchment: return Color(red: 0.60, green: 0.45, blue: 0.25).opacity(0.35)
        case .minimal: return Color.black.opacity(0.12)
        }
    }

    public var footerTextColor: Color {
        switch self {
        case .emerald: return Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.7)
        case .midnight: return Color.white.opacity(0.45)
        case .parchment: return Color(red: 0.50, green: 0.40, blue: 0.30).opacity(0.8)
        case .minimal: return Color.black.opacity(0.4)
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

    public init(
        suraName: String,
        suraNumber: Int,
        ayahRangeString: String,
        referenceText: String,
        arabicText: String,
        translationText: String,
        translator: String?
    ) {
        self.suraName = suraName
        self.suraNumber = suraNumber
        self.ayahRangeString = ayahRangeString
        self.referenceText = referenceText
        self.arabicText = arabicText
        self.translationText = translationText
        self.translator = translator
    }
}
