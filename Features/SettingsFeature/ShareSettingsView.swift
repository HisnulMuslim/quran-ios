//
//  ShareSettingsView.swift
//  Quran
//
//
//

import Localization
import NoorUI
import QuranTextKit
import SwiftUI

struct ShareSettingsView: View {
    @StateObject private var viewModel = ShareSettingsViewModel()

    var body: some View {
        NoorList {
            NoorBasicSection {
                // Include Translation Toggle
                Toggle(isOn: $viewModel.includeTranslation) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lAndroid("prefs_include_translation_title"))
                            .font(.body)
                        Text(lAndroid("prefs_include_translation_summary"))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .appIdentity))

                if viewModel.includeTranslation {
                    // Inline Translation Toggle (Dependent on Include Translation)
                    Toggle(isOn: $viewModel.inlineTranslation) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lAndroid("prefs_inline_translation_title"))
                                .font(.body)
                            Text(viewModel.inlineTranslation ? lAndroid("prefs_inline_translation_summary_on") : lAndroid("prefs_inline_translation_summary_off"))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .appIdentity))
                }

                // Include Inline Ayah Numbers Toggle
                Toggle(isOn: $viewModel.includeInlineAyahNumbers) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lAndroid("prefs_include_inline_ayah_numbers_title"))
                            .font(.body)
                        Text(lAndroid("prefs_include_inline_ayah_numbers_summary"))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .appIdentity))

                // Include Footnotes Toggle
                Toggle(isOn: $viewModel.showNotes) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lAndroid("prefs_include_notes_title"))
                            .font(.body)
                        Text(lAndroid("prefs_include_notes_summary"))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .appIdentity))
            }
        }
        .themedBackground()
    }
}

@MainActor
final class ShareSettingsViewModel: ObservableObject {
    private let preferences = SharePreferences.shared

    @Published var includeTranslation: Bool {
        didSet {
            preferences.includeTranslation = includeTranslation
        }
    }

    @Published var inlineTranslation: Bool {
        didSet {
            preferences.inlineTranslation = inlineTranslation
        }
    }

    @Published var includeInlineAyahNumbers: Bool {
        didSet {
            preferences.includeInlineAyahNumbers = includeInlineAyahNumbers
        }
    }

    @Published var showNotes: Bool {
        didSet {
            preferences.showNotes = showNotes
        }
    }

    init() {
        includeTranslation = preferences.includeTranslation
        inlineTranslation = preferences.inlineTranslation
        includeInlineAyahNumbers = preferences.includeInlineAyahNumbers
        showNotes = preferences.showNotes
    }
}
