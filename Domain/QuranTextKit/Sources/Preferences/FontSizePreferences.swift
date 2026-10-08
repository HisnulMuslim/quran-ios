//
//  FontSizePreferences.swift
//
//
//  Created by Mohamed Afifi on 2021-11-24.
//

import Preferences
import QuranText

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

    public static let defaultTranslationValue = FontSize.level3
    public static let defaultArabicValue = FontSize.level1
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
