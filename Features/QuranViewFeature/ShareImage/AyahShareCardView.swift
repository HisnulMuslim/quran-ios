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
    let aspectRatio: AyahCardAspectRatio
    let showArabic: Bool
    let showTranslation: Bool
    let showFootnotes: Bool
    let showQRCode: Bool
    let showAppURL: Bool
    let fontSizeScale: CGFloat
    let textColorScheme: AyahCardTextColorScheme
    let customTextColor: Color?
    let translationTextColorScheme: AyahCardTextColorScheme
    let customTranslationTextColor: Color?
    let arabicFont: AyahCardArabicFont
    let translationFont: AyahCardTranslationFont
    let photoScale: CGFloat
    let customImage: UIImage?
    let isExport: Bool

    // Scaled dimensions: mathematically identical proportion between preview (330pt) and export (1080px)
    private static let baseCardWidth: CGFloat = 330
    private var cardWidth: CGFloat { isExport ? 1080 : Self.baseCardWidth }
    private var scale: CGFloat { cardWidth / Self.baseCardWidth }
    private var cardHeight: CGFloat { aspectRatio.height(for: cardWidth) }
    private var outerPadding: CGFloat {
        (aspectRatio == .story ? 28 : (aspectRatio == .portrait ? 24 : 22)) * scale
    }
    private var bottomPadding: CGFloat {
        (aspectRatio == .story ? 16 : (aspectRatio == .portrait ? 13 : 10)) * scale
    }
    private var cornerRadius: CGFloat { 22 * scale }

    public init(
        data: AyahCardData,
        theme: AyahCardTheme,
        aspectRatio: AyahCardAspectRatio = .square,
        showArabic: Bool = true,
        showTranslation: Bool = true,
        showFootnotes: Bool = false,
        showQRCode: Bool = true,
        showAppURL: Bool = true,
        fontSizeScale: CGFloat = 1.0,
        textColorScheme: AyahCardTextColorScheme = .themeDefault,
        customTextColor: Color? = nil,
        translationTextColorScheme: AyahCardTextColorScheme = .themeDefault,
        customTranslationTextColor: Color? = nil,
        arabicFont: AyahCardArabicFont = .uthmanic,
        translationFont: AyahCardTranslationFont = .notoSerif,
        photoScale: CGFloat = 1.0,
        customImage: UIImage? = nil,
        isExport: Bool = false
    ) {
        FontName.registerFonts()
        self.data = data
        self.theme = theme
        self.aspectRatio = aspectRatio
        self.showArabic = showArabic
        self.showTranslation = showTranslation
        self.showFootnotes = showFootnotes
        self.showQRCode = showQRCode
        self.showAppURL = showAppURL
        self.fontSizeScale = fontSizeScale
        self.textColorScheme = textColorScheme
        self.customTextColor = customTextColor
        self.translationTextColorScheme = translationTextColorScheme
        self.customTranslationTextColor = customTranslationTextColor
        self.arabicFont = arabicFont
        self.translationFont = translationFont
        self.photoScale = photoScale
        self.customImage = customImage
        self.isExport = isExport
    }

    private var isKannada: Bool {
        AppLanguage == .kannada || Locale.current.languageCode == "kn"
    }

    private var qrCodeImage: UIImage? {
        AyahCardRenderer.generateQRCode(from: "https://quran.hisnulmuslimdua.com/", size: isExport ? 200 : 70)
    }

    private var photoBackground: UIImage? {
        if theme == .customPhoto, let custom = customImage {
            return custom
        }
        guard let name = theme.imageName else {
            return customImage
        }
        if let img = UIImage(named: name) {
            return img
        }
        if let img = UIImage(named: name, in: .main, compatibleWith: nil) {
            return img
        }
        let testPath = "/Users/azhar/.gemini/antigravity/brain/bec757d9-597d-48e9-8d57-290aef403482/\(name).jpg"
        if FileManager.default.fileExists(atPath: testPath) {
            return UIImage(contentsOfFile: testPath)
        }
        return customImage
    }

    private func loadBadgeImage(name: String) -> UIImage? {
        if let img = UIImage(named: name) {
            return img
        }
        if let img = UIImage(named: name, in: .main, compatibleWith: nil) {
            return img
        }
        let testPath = "/Users/azhar/.gemini/antigravity/brain/bec757d9-597d-48e9-8d57-290aef403482/\(name)_clean.png"
        if FileManager.default.fileExists(atPath: testPath) {
            return UIImage(contentsOfFile: testPath)
        }
        return nil
    }

    private func loadAppLogo() -> UIImage? {
        if let img = UIImage(named: "app_logo") {
            return img
        }
        if let img = UIImage(named: "app_logo", in: .main, compatibleWith: nil) {
            return img
        }
        let testPath = "/Users/azhar/.gemini/antigravity/brain/bec757d9-597d-48e9-8d57-290aef403482/pavitra_quran_logo.png"
        if FileManager.default.fileExists(atPath: testPath) {
            return UIImage(contentsOfFile: testPath)
        }
        return nil
    }

    private var resolvedArabicColor: Color {
        if theme == .parchment || theme == .minimal {
            return theme.arabicTextColor
        }
        switch textColorScheme {
        case .themeDefault: return theme.arabicTextColor
        case .classicGold: return Color(red: 1.00, green: 0.92, blue: 0.70)
        case .pureWhite: return Color.white
        case .iceCyan: return Color(red: 0.65, green: 0.92, blue: 1.00)
        case .emeraldMint: return Color(red: 0.60, green: 0.96, blue: 0.80)
        case .sunsetAmber: return Color(red: 1.00, green: 0.80, blue: 0.48)
        case .roseGold: return Color(red: 1.00, green: 0.78, blue: 0.82)
        case .royalLavender: return Color(red: 0.88, green: 0.84, blue: 1.00)
        case .custom: return customTextColor ?? theme.arabicTextColor
        }
    }

    private var resolvedBadgeTextColor: Color {
        if theme == .parchment || theme == .minimal {
            return theme.badgeTextColor
        }
        switch textColorScheme {
        case .themeDefault: return theme.badgeTextColor
        case .classicGold: return Color(red: 1.00, green: 0.88, blue: 0.55)
        case .pureWhite: return Color.white
        case .iceCyan: return Color(red: 0.75, green: 0.94, blue: 1.00)
        case .emeraldMint: return Color(red: 0.70, green: 0.98, blue: 0.85)
        case .sunsetAmber: return Color(red: 1.00, green: 0.85, blue: 0.55)
        case .roseGold: return Color(red: 1.00, green: 0.85, blue: 0.88)
        case .royalLavender: return Color(red: 0.92, green: 0.88, blue: 1.00)
        case .custom: return customTextColor ?? theme.badgeTextColor
        }
    }

    private var resolvedTranslationColor: Color {
        if translationTextColorScheme == .custom {
            return customTranslationTextColor ?? (theme == .parchment || theme == .minimal ? theme.translationTextColor : Color.white)
        }
        switch translationTextColorScheme {
        case .classicGold: return Color(red: 1.00, green: 0.90, blue: 0.65)
        case .pureWhite: return Color.white
        case .iceCyan: return Color(red: 0.70, green: 0.94, blue: 1.00)
        case .emeraldMint: return Color(red: 0.68, green: 0.98, blue: 0.85)
        case .sunsetAmber: return Color(red: 1.00, green: 0.85, blue: 0.60)
        case .roseGold: return Color(red: 1.00, green: 0.82, blue: 0.86)
        case .royalLavender: return Color(red: 0.92, green: 0.88, blue: 1.00)
        case .custom: return customTranslationTextColor ?? Color.white
        case .themeDefault:
            if theme == .parchment || theme == .minimal {
                return theme.translationTextColor
            }
            return Color.white.opacity(0.95)
        }
    }

    private var resolvedDividerColor: Color {
        if theme == .parchment || theme == .minimal {
            return theme.dividerColor
        }
        switch textColorScheme {
        case .themeDefault: return theme.dividerColor
        case .classicGold: return Color(red: 1.00, green: 0.85, blue: 0.50).opacity(0.5)
        case .pureWhite: return Color.white.opacity(0.4)
        case .iceCyan: return Color(red: 0.65, green: 0.92, blue: 1.00).opacity(0.45)
        case .emeraldMint: return Color(red: 0.60, green: 0.96, blue: 0.80).opacity(0.45)
        case .sunsetAmber: return Color(red: 1.00, green: 0.80, blue: 0.48).opacity(0.5)
        case .roseGold: return Color(red: 1.00, green: 0.78, blue: 0.82).opacity(0.45)
        case .royalLavender: return Color(red: 0.88, green: 0.84, blue: 1.00).opacity(0.45)
        case .custom: return (customTextColor ?? theme.dividerColor).opacity(0.5)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 4 * scale)

            // Header: Citation Pill Badge
            HStack(spacing: 6 * scale) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 10 * scale))
                Text(data.referenceText)
                    .font(.system(size: 13 * scale, weight: .semibold))
            }
            .foregroundColor(resolvedBadgeTextColor)
            .padding(.horizontal, 14 * scale)
            .padding(.vertical, 6 * scale)
            .background(
                Capsule()
                    .fill(theme.badgeBackground)
            )
            .padding(.top, 2 * scale)

            Spacer(minLength: 8 * scale)

            // Arabic Text
            if showArabic && !data.arabicText.isEmpty {
                Text(data.arabicText)
                    .font(arabicFont.font(size: (arabicFont == .uthmanic ? 26 : 23) * scale * fontSizeScale))
                    .foregroundColor(resolvedArabicColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing((arabicFont == .uthmanic || arabicFont == .mishafi ? 12 : 9) * scale * fontSizeScale)
                    .padding(.horizontal, 8 * scale)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Decorative Divider
            if showArabic && showTranslation && !data.translationText.isEmpty {
                DecorativeDivider(color: resolvedDividerColor, scale: scale)
                    .padding(.vertical, 6 * scale)
            }

            // Translation Text
            if showTranslation && !data.translationText.isEmpty {
                Text(data.translationText)
                    .font(translationFont.font(size: 15.5 * scale * fontSizeScale))
                    .foregroundColor(resolvedTranslationColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6 * scale * fontSizeScale)
                    .padding(.horizontal, 6 * scale)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Footnotes Section
            if showFootnotes, let notes = data.footnotes, !notes.isEmpty {
                Spacer(minLength: 6 * scale)

                VStack(alignment: .leading, spacing: 4 * scale) {
                    HStack(spacing: 4 * scale) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 9 * scale))
                        Text(isKannada ? "ಟಿಪ್ಪಣಿಗಳು:" : "Footnotes:")
                            .font(.system(size: 10 * scale, weight: .semibold))
                    }
                    .foregroundColor(theme.footerTextColor)
                    .padding(.bottom, 1 * scale)

                    ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                        Text(cleanFootnote(note))
                            .font(.system(size: 10.5 * scale * fontSizeScale, weight: .regular))
                            .foregroundColor(theme.translationTextColor.opacity(0.85))
                            .lineSpacing(2 * scale)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(9 * scale)
                .background(
                    RoundedRectangle(cornerRadius: 10 * scale)
                        .fill(theme.badgeBackground.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10 * scale)
                        .stroke(theme.innerBorderColor, lineWidth: 1 * scale)
                )
                .padding(.horizontal, 6 * scale)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 8 * scale)

            // Footer:
            // When QR is ON: Left corner = Square Logo + URL, Right corner = QR code
            // When QR is OFF: Pure centered watermark (Square Logo + URL)
            if showQRCode, let qr = qrCodeImage {
                HStack(alignment: .center, spacing: 8 * scale) {
                    // Left Corner: Square App Logo + URL
                    HStack(alignment: .center, spacing: 6 * scale) {
                        if let logo = loadAppLogo() {
                            Image(uiImage: logo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22 * scale, height: 22 * scale)
                                .cornerRadius(4.5 * scale)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4.5 * scale)
                                        .stroke(Color.white.opacity(0.35), lineWidth: 0.75 * scale)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 1 * scale)
                        }

                        Text("quran.hisnulmuslimdua.com")
                            .font(.system(size: 9.5 * scale, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.footerTextColor.opacity(0.95))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 12 * scale)

                    // Right Corner: Clean QR Code
                    Image(uiImage: qr)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 32 * scale, height: 32 * scale)
                        .padding(2.5 * scale)
                        .background(Color.white)
                        .cornerRadius(5 * scale)
                        .shadow(color: Color.black.opacity(0.18), radius: 2 * scale)
                }
                .padding(.horizontal, 10 * scale)
                .padding(.bottom, 2 * scale)
            } else {
                // Centered Pure Watermark
                HStack(alignment: .center, spacing: 7 * scale) {
                    if let logo = loadAppLogo() {
                        Image(uiImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22 * scale, height: 22 * scale)
                            .cornerRadius(4.5 * scale)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4.5 * scale)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 0.75 * scale)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 1 * scale)
                    }

                    Text("quran.hisnulmuslimdua.com")
                        .font(.system(size: 10 * scale, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.footerTextColor.opacity(0.95))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, outerPadding)
        .padding(.top, outerPadding)
        .padding(.bottom, bottomPadding)
        .frame(width: cardWidth, height: cardHeight)
        .background(
            ZStack {
                if let bg = photoBackground {
                    Image(uiImage: bg)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(photoScale)
                        .frame(width: cardWidth, height: cardHeight)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.55),
                                    Color.black.opacity(0.40),
                                    Color.black.opacity(0.65)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    theme.backgroundGradient

                    // Subtle Islamic geometric lattice pattern
                    if theme != .minimal {
                        IslamicLatticeBackground(color: theme.innerBorderColor.opacity(0.22))
                            .opacity(0.4)
                            .clipped()
                    }
                }

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
        .clipped()
        .shadow(
            color: Color.black.opacity(theme == .minimal ? 0.08 : 0.25),
            radius: 12 * scale,
            x: 0,
            y: 6 * scale
        )
    }

    private func cleanFootnote(_ note: String) -> String {
        var text = note.trimmingCharacters(in: .whitespacesAndNewlines)
        text = text.replacingOccurrences(of: "^\\[\\d+\\]\\s*", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "^\\[[0-9\\u0CE6-\\u0CEF]+\\]\\s*", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "^[0-9\\u0CE6-\\u0CEF]+[\\.\\:\\-]\\s*", with: "", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct DecorativeDivider: View {
    let color: Color
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 8 * scale) {
            LinearGradient(
                colors: [color.opacity(0.0), color.opacity(0.75)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 75 * scale, height: 1.2 * scale)

            Text("❖")
                .font(.system(size: 11 * scale))
                .foregroundColor(color.opacity(0.85))

            LinearGradient(
                colors: [color.opacity(0.75), color.opacity(0.0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 75 * scale, height: 1.2 * scale)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 2 * scale)
    }
}

private struct IslamicLatticeBackground: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 36
            let half = step / 2

            for y in stride(from: 0, through: size.height + step, by: step) {
                for x in stride(from: 0, through: size.width + step, by: step) {
                    var path = Path()
                    // Diamond
                    path.move(to: CGPoint(x: x, y: y - half))
                    path.addLine(to: CGPoint(x: x + half, y: y))
                    path.addLine(to: CGPoint(x: x, y: y + half))
                    path.addLine(to: CGPoint(x: x - half, y: y))
                    path.closeSubpath()

                    // Mini inner diamond
                    let miniHalf = half * 0.4
                    path.move(to: CGPoint(x: x, y: y - miniHalf))
                    path.addLine(to: CGPoint(x: x + miniHalf, y: y))
                    path.addLine(to: CGPoint(x: x, y: y + miniHalf))
                    path.addLine(to: CGPoint(x: x - miniHalf, y: y))
                    path.closeSubpath()

                    context.stroke(path, with: .color(color), lineWidth: 0.75)
                }
            }
        }
    }
}
