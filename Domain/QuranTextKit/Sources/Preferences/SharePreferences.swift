//
//  SharePreferences.swift
//  Quran
//
//  
//

import Preferences

public struct SharePreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = SharePreferences()

    @Preference(includeTranslation)
    public var includeTranslation: Bool

    @Preference(inlineTranslation)
    public var inlineTranslation: Bool

    @Preference(includeInlineAyahNumbers)
    public var includeInlineAyahNumbers: Bool

    @Preference(showNotes)
    public var showNotes: Bool

    // MARK: Private

    private static let includeTranslation = PreferenceKey<Bool>(key: "share_include_translation", defaultValue: true)
    private static let inlineTranslation = PreferenceKey<Bool>(key: "share_inline_translation", defaultValue: true)
    private static let includeInlineAyahNumbers = PreferenceKey<Bool>(key: "share_include_inline_ayah_numbers", defaultValue: false)
    private static let showNotes = PreferenceKey<Bool>(key: "share_show_notes", defaultValue: true)
}
