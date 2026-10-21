//
//  FontSizePreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-11-24.
//

import Preferences
import QuranText

#if canImport(UIKit)
import UIKit
#endif

public enum TranslationFont: String, CaseIterable {
    case notoSans
    case kohinoor
    case system
}

public struct FontSizePreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = FontSizePreferences()

    @TransformedPreference(translationFontSizeKey, transformer: PreferenceTransformer(
        rawToValue: { (FontSize(rawValue: $0) ?? defaultTranslationValue).clampedToSupported },
        valueToRaw: { $0.rawValue }
    ))
    public var translationFontSize: FontSize

    @TransformedPreference(arabicFontSizeKey, transformer: PreferenceTransformer(
        rawToValue: { (FontSize(rawValue: $0) ?? defaultArabicValue).clampedToSupported },
        valueToRaw: { $0.rawValue }
    ))
    public var arabicFontSize: FontSize

    @TransformedPreference(translationFontKey, transformer: .rawRepresentable(defaultValue: .notoSans))
    public var translationFont: TranslationFont

    private static var isPad13Inch: Bool {
        #if canImport(UIKit)
        guard UIDevice.current.userInterfaceIdiom == .pad else { return false }
        let bounds = UIScreen.main.bounds
        return max(bounds.width, bounds.height) >= 1300
        #else
        return false
        #endif
    }

    private static var isPadNon13Inch: Bool {
        #if canImport(UIKit)
        guard UIDevice.current.userInterfaceIdiom == .pad else { return false }
        let bounds = UIScreen.main.bounds
        return max(bounds.width, bounds.height) < 1300
        #else
        return false
        #endif
    }

    public static var defaultTranslationValue: FontSize {
        isPad13Inch ? .level2 : .level3
    }

    public static var defaultArabicValue: FontSize {
        if isPad13Inch || isPadNon13Inch {
            return .level2
        } else {
            return .level1
        }
    }

    public static let defaultTranslationFont = TranslationFont.notoSans

    public mutating func resetToDefaults() {
        translationFontSize = Self.defaultTranslationValue
        arabicFontSize = Self.defaultArabicValue
        translationFont = Self.defaultTranslationFont
    }

    // MARK: Private

    private static let translationFontSizeKey = PreferenceKey<Int>(key: "translationFontSize", defaultValue: defaultTranslationValue.rawValue)
    private static let arabicFontSizeKey = PreferenceKey<Int>(key: "arabicFont", defaultValue: defaultArabicValue.rawValue)
    private static let translationFontKey = PreferenceKey<String>(key: "translationFontSelection", defaultValue: defaultTranslationFont.rawValue)
}
