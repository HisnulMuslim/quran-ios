//
//  AyahShareCardView.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import Localization
import NoorFont
import SwiftUI

public struct AyahShareCardView: View {
    let data: AyahCardData
    let theme: AyahCardTheme
    let showArabic: Bool
    let showTranslation: Bool
    let isExport: Bool

    // Scaled dimensions
    private var scale: CGFloat { isExport ? 2.5 : 1.0 }
    private var cardWidth: CGFloat { isExport ? 1000 : 330 }
    private var outerPadding: CGFloat { 22 * scale }
    private var cornerRadius: CGFloat { 22 * scale }

    public init(
        data: AyahCardData,
        theme: AyahCardTheme,
        showArabic: Bool = true,
        showTranslation: Bool = true,
        isExport: Bool = false
    ) {
        self.data = data
        self.theme = theme
        self.showArabic = showArabic
        self.showTranslation = showTranslation
        self.isExport = isExport
    }

    public var body: some View {
        VStack(spacing: 16 * scale) {
            // Header: Bismillah & Citation Badge
            VStack(spacing: 10 * scale) {
                Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                    .font(.system(size: 16 * scale, weight: .medium))
                    .foregroundColor(theme.arabicTextColor.opacity(0.85))

                // Citation Pill Badge
                HStack(spacing: 6 * scale) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 10 * scale))
                    Text(data.referenceText)
                        .font(.system(size: 13 * scale, weight: .semibold))
                }
                .foregroundColor(theme.badgeTextColor)
                .padding(.horizontal, 14 * scale)
                .padding(.vertical, 6 * scale)
                .background(
                    Capsule()
                        .fill(theme.badgeBackground)
                )
            }
            .padding(.top, 4 * scale)

            // Arabic Text
            if showArabic && !data.arabicText.isEmpty {
                Text(data.arabicText)
                    .font(.system(size: 23 * scale, weight: .regular))
                    .foregroundColor(theme.arabicTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10 * scale)
                    .padding(.horizontal, 8 * scale)
                    .frame(maxWidth: .infinity)
            }

            // Decorative Divider
            if showArabic && showTranslation && !data.translationText.isEmpty {
                HStack(spacing: 12 * scale) {
                    Rectangle()
                        .fill(theme.dividerColor)
                        .frame(height: 1 * scale)
                    Text("❖")
                        .font(.system(size: 11 * scale))
                        .foregroundColor(theme.dividerColor)
                    Rectangle()
                        .fill(theme.dividerColor)
                        .frame(height: 1 * scale)
                }
                .padding(.horizontal, 24 * scale)
                .padding(.vertical, 2 * scale)
            }

            // Translation Text
            if showTranslation && !data.translationText.isEmpty {
                VStack(spacing: 6 * scale) {
                    Text(data.translationText)
                        .font(.system(size: 15.5 * scale, weight: .regular))
                        .foregroundColor(theme.translationTextColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5 * scale)
                        .padding(.horizontal, 6 * scale)
                        .frame(maxWidth: .infinity)

                    if let translator = data.translator, !translator.isEmpty {
                        Text("- \(translator)")
                            .font(.system(size: 11.5 * scale, weight: .light))
                            .foregroundColor(theme.translationTextColor.opacity(0.7))
                            .padding(.top, 2 * scale)
                    }
                }
            }

            // Footer / Watermark
            HStack(spacing: 6 * scale) {
                Text(brandingText)
                    .font(.system(size: 10 * scale, weight: .medium))
                    .foregroundColor(theme.footerTextColor)
            }
            .padding(.top, 4 * scale)
        }
        .padding(outerPadding)
        .frame(width: cardWidth)
        .background(
            ZStack {
                theme.backgroundGradient

                // Inner ornate border
                RoundedRectangle(cornerRadius: cornerRadius - (4 * scale))
                    .stroke(theme.innerBorderColor, lineWidth: 1 * scale)
                    .padding(6 * scale)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(theme.borderColor, lineWidth: 1.5 * scale)
        )
        .cornerRadius(cornerRadius)
        .shadow(
            color: Color.black.opacity(theme == .minimal ? 0.08 : 0.25),
            radius: 12 * scale,
            x: 0,
            y: 6 * scale
        )
    }

    private var brandingText: String {
        let isKannada = AppLanguage == .kannada || Locale.current.languageCode == "kn"
        return isKannada ? "ಕನ್ನಡ ಕುರ್ ಆನ್ • Kannada Quran App" : "Kannada Quran App"
    }
}
