//
//  TranslationVerseView.swift
//
//
//  Created by Mohamed Afifi on 2024-02-01.
//

import Localization
import QuranText
import QuranTranslationFeature
import SwiftUI

struct TranslationVerseView: View {
    @ObservedObject var viewModel: TranslationVerseViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.availableTranslations.count > 1 {
                Picker("Translation", selection: Binding(
                    get: { viewModel.selectedFilterId },
                    set: { viewModel.selectFilter($0) }
                )) {
                    Text(compareTitle).tag(-1)
                    ForEach(viewModel.availableTranslations, id: \.id) { trans in
                        Text(shortName(for: trans)).tag(trans.id)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)
            }

            ContentTranslationView(viewModel: viewModel.translationViewModel)
        }
        .themedBackground()
        .themedForeground()
        .populateThemeStyle()
    }

    private var compareTitle: String {
        (AppLanguage == .kannada || Locale.current.languageCode == "kn") ? "ಹೋಲಿಕೆ (ಎಲ್ಲಾ)" : "Compare (All)"
    }

    private func shortName(for translation: Translation) -> String {
        switch translation.languageCode {
        case "kn": return "ಕನ್ನಡ"
        case "en": return "English"
        case "ta": return "தமிழ்"
        case "ml": return "മലയാളം"
        case "te": return "తెలుగు"
        case "ur": return "اردو"
        case "hi": return "हिन्दी"
        case "ar": return "العربية"
        default: return translation.displayName
        }
    }
}
