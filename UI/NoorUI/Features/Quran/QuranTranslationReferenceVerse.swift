//
//  QuranTranslationReferenceVerse.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import Localization
import QuranKit
import QuranText
import SwiftUI
import UIx

public struct QuranTranslationReferenceVerse: View {
    @ScaledMetric var topPadding = 10

    let ayahNumber: AyahNumber?
    let reference: AyahNumber
    let fontSize: FontSize
    let characterDirection: Locale.LanguageDirection

    public init(ayahNumber: AyahNumber? = nil, reference: AyahNumber, fontSize: FontSize, characterDirection: Locale.LanguageDirection) {
        self.ayahNumber = ayahNumber
        self.reference = reference
        self.fontSize = fontSize
        self.characterDirection = characterDirection
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if let ayahNumber {
                let maxBadgeSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 26 : 16
                Text(lFormat("translation.text.ayah-number", ayahNumber.sura.suraNumber, ayahNumber.ayah))
                    .font(.system(size: max(11, min(maxBadgeSize, fontSize.translationFontSize * 0.62)), weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .themedSecondaryForeground()
                    .themedSecondaryBackground()
                    .cornerRadius(5)
            }
            Text(lFormat("translation.text.see-referenced-verse", reference.ayah))
                .font(.body)
                .dynamicTypeSize(fontSize.translationDynamicTypeSize)
                .themedSecondaryForeground()
        }
        .textAlignment(follows: characterDirection)
        .padding(.top, topPadding)
        .readableInsetsPadding(.horizontal)
    }
}
