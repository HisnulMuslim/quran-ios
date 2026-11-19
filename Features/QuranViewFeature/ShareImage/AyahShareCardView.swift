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
    let transparentBackground: Bool
    let exportWidth: CGFloat?
    let isExport: Bool

    // Scaled dimensions: mathematically identical proportion between preview (330pt) and export (720px/1080px)
    private static let baseCardWidth: CGFloat = 330
    private var cardWidth: CGFloat { exportWidth ?? (isExport ? 1080 : Self.baseCardWidth) }
    private var scale: CGFloat { cardWidth / Self.baseCardWidth }
    private var cardHeight: CGFloat { aspectRatio.height(for: cardWidth) }
    private var outerPadding: CGFloat {
        (aspectRatio == .story ? 28 : (aspectRatio == .portrait ? 24 : 22)) * scale
    }
    private var bottomPadding: CGFloat {
        (aspectRatio == .story ? 16 : (aspectRatio == .portrait ? 13 : 10)) * scale
    }
    private var cornerRadius: CGFloat { 0 }

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
        transparentBackground: Bool = false,
        exportWidth: CGFloat? = nil,
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
        self.transparentBackground = transparentBackground
        self.exportWidth = exportWidth
        self.isExport = isExport
    }

    private var displayTheme: AyahCardTheme {
        if transparentBackground {
            return theme.isPhoto ? theme : .customPhoto
        }
        return theme
    }

    private var isDarkFooterText: Bool {
        !transparentBackground && !displayTheme.isPhoto && (displayTheme == .minimal || displayTheme == .parchment)
    }

    private var qrCodeImage: UIImage? {
        AyahCardRenderer.generateQRCode(from: "https://quran.hisnulmuslimdua.com/", size: isExport ? 220 : 80)
    }

    private var photoBackground: UIImage? {
        if transparentBackground || theme != .customPhoto {
            return nil
        }
        return customImage
    }

    private func loadAppLogo() -> UIImage? {
        UIImage(named: "app_logo") ?? UIImage(named: "app_logo", in: .main, compatibleWith: nil)
    }

    private var resolvedArabicColor: Color {
        if isDarkFooterText {
            return displayTheme.arabicTextColor
        }
        switch textColorScheme {
        case .themeDefault: return displayTheme.arabicTextColor
        case .classicGold: return Color(red: 1.00, green: 0.92, blue: 0.70)
        case .pureWhite: return Color.white
        case .iceCyan: return Color(red: 0.65, green: 0.92, blue: 1.00)
        case .emeraldMint: return Color(red: 0.60, green: 0.96, blue: 0.80)
        case .sunsetAmber: return Color(red: 1.00, green: 0.80, blue: 0.48)
        case .roseGold: return Color(red: 1.00, green: 0.78, blue: 0.82)
        case .royalLavender: return Color(red: 0.88, green: 0.84, blue: 1.00)
        case .custom: return customTextColor ?? displayTheme.arabicTextColor
        }
    }

    private var resolvedBadgeTextColor: Color {
        if isDarkFooterText {
            return displayTheme.badgeTextColor
        }
        switch textColorScheme {
        case .themeDefault: return displayTheme.badgeTextColor
        case .classicGold: return Color(red: 1.00, green: 0.88, blue: 0.55)
        case .pureWhite: return Color.white
        case .iceCyan: return Color(red: 0.75, green: 0.94, blue: 1.00)
        case .emeraldMint: return Color(red: 0.70, green: 0.98, blue: 0.85)
        case .sunsetAmber: return Color(red: 1.00, green: 0.85, blue: 0.55)
        case .roseGold: return Color(red: 1.00, green: 0.85, blue: 0.88)
        case .royalLavender: return Color(red: 0.92, green: 0.88, blue: 1.00)
        case .custom: return customTextColor ?? displayTheme.badgeTextColor
        }
    }

    private var resolvedTranslationColor: Color {
        if translationTextColorScheme == .custom {
            return customTranslationTextColor ?? (isDarkFooterText ? displayTheme.translationTextColor : Color.white)
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
            if isDarkFooterText {
                return displayTheme.translationTextColor
            }
            return Color.white.opacity(0.95)
        }
    }

    private var resolvedDividerColor: Color {
        if isDarkFooterText {
            return displayTheme.dividerColor
        }
        switch textColorScheme {
        case .themeDefault: return displayTheme.dividerColor
        case .classicGold: return Color(red: 1.00, green: 0.85, blue: 0.50).opacity(0.5)
        case .pureWhite: return Color.white.opacity(0.4)
        case .iceCyan: return Color(red: 0.65, green: 0.92, blue: 1.00).opacity(0.45)
        case .emeraldMint: return Color(red: 0.60, green: 0.96, blue: 0.80).opacity(0.45)
        case .sunsetAmber: return Color(red: 1.00, green: 0.80, blue: 0.48).opacity(0.5)
        case .roseGold: return Color(red: 1.00, green: 0.78, blue: 0.82).opacity(0.45)
        case .royalLavender: return Color(red: 0.88, green: 0.84, blue: 1.00).opacity(0.45)
        case .custom: return (customTextColor ?? displayTheme.dividerColor).opacity(0.5)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header: Citation Pill Badge (always pinned at top)
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
                    .fill(displayTheme.badgeBackground)
            )
            .padding(.top, 2 * scale)
            .layoutPriority(1)

            // Middle Content: Centered in remaining space and clipped so zoomed text
            // never pushes the header or footer (QR code, URL, logo) out of frame.
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .center) {
                    VStack(spacing: 0) {
                        // Arabic Text
                        if showArabic && !data.arabicText.isEmpty {
                            arabicFont.formattedArabicTextView(
                                data.arabicText,
                                size: (arabicFont == .uthmanic ? 26 : 23) * scale * fontSizeScale
                            )
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
                            let displayedTranslation = (showFootnotes ? data.translationTextWithFootnotes : nil) ?? data.translationText
                            Text(displayedTranslation)
                                .font(translationFont.font(size: 15.5 * scale * fontSizeScale))
                                .foregroundColor(resolvedTranslationColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4 * scale * fontSizeScale)
                                .padding(.horizontal, 6 * scale)
                                .frame(maxWidth: .infinity)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Footnotes Section
                        if showFootnotes, let notes = data.footnotes, !notes.isEmpty {
                            Spacer(minLength: 6 * scale)
                                .frame(height: 6 * scale)

                            VStack(alignment: .leading, spacing: 4 * scale) {
                                HStack(spacing: 4 * scale) {
                                    Image(systemName: "text.quote")
                                        .font(.system(size: 9 * scale))
                                    Text(lChoice(kn: "ಟಿಪ್ಪಣಿಗಳು:", en: "Footnotes:", ar: "الحواشي:"))
                                        .font(.system(size: 10 * scale, weight: .semibold))
                                }
                                .foregroundColor(displayTheme.footerTextColor)
                                .padding(.bottom, 1 * scale)

                                ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                                    Text("[\(index + 1)] \(cleanFootnote(note))")
                                        .font(.system(size: 10.5 * scale * fontSizeScale, weight: .regular))
                                        .foregroundColor(displayTheme.translationTextColor.opacity(0.85))
                                        .lineSpacing(2 * scale)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(9 * scale)
                            .background(
                                RoundedRectangle(cornerRadius: 10 * scale)
                                    .fill(displayTheme.badgeBackground.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10 * scale)
                                    .stroke(displayTheme.innerBorderColor, lineWidth: 1 * scale)
                            )
                            .padding(.horizontal, 6 * scale)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 4 * scale)
                }
                .clipped()

            // Permanent Footer (always pinned at bottom):
            // Left: Square App Logo + Store Badge Pill (App Store | Google Play) + domain sub-caption
            // Right: Crisp White Padded QR Code
            HStack(alignment: .center, spacing: 8 * scale) {
                HStack(alignment: .center, spacing: 6.5 * scale) {
                    if let logo = loadAppLogo() {
                        Image(uiImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24 * scale, height: 24 * scale)
                            .cornerRadius(5 * scale)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5 * scale)
                                    .stroke(
                                        isDarkFooterText ? Color.black.opacity(0.18) : Color.white.opacity(0.35),
                                        lineWidth: 0.75 * scale
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 1 * scale)
                    }

                    VStack(alignment: .leading, spacing: 3 * scale) {
                        // Store Badges Capsule: [Apple] App Store | [Google Play] Google Play
                        HStack(alignment: .center, spacing: 3.5 * scale) {
                            AppleLogoShape()
                                .fill(isDarkFooterText ? displayTheme.footerTextColor.opacity(0.95) : Color.white)
                                .frame(width: 8.5 * scale, height: 8.5 * scale)

                            Text(verbatim: "App Store")
                                .font(.system(size: 7.2 * scale, weight: .bold, design: .rounded))
                                .foregroundColor(isDarkFooterText ? displayTheme.footerTextColor.opacity(0.95) : .white)

                            Text(verbatim: "|")
                                .font(.system(size: 7.2 * scale, weight: .regular))
                                .foregroundColor(
                                    (isDarkFooterText ? displayTheme.footerTextColor : Color.white).opacity(0.55)
                                )
                                .padding(.horizontal, 1.5 * scale)

                            GooglePlayIconView()
                                .frame(width: 8.5 * scale, height: 8.5 * scale)

                            Text(verbatim: "Google Play")
                                .font(.system(size: 7.2 * scale, weight: .bold, design: .rounded))
                                .foregroundColor(isDarkFooterText ? displayTheme.footerTextColor.opacity(0.95) : .white)
                        }
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 6.5 * scale)
                        .padding(.vertical, 3.2 * scale)
                        .background(
                            Capsule()
                                .fill(
                                    isDarkFooterText
                                        ? Color(red: 15 / 255.0, green: 23 / 255.0, blue: 42 / 255.0).opacity(0.08)
                                        : Color.black.opacity(0.45)
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    isDarkFooterText
                                        ? Color(red: 15 / 255.0, green: 23 / 255.0, blue: 42 / 255.0).opacity(0.18)
                                        : Color.white.opacity(0.28),
                                    lineWidth: 0.7 * scale
                                )
                        )

                        Text(verbatim: "https://quran.hisnulmuslimdua.com")
                            .font(.system(size: 7.2 * scale, weight: .bold, design: .rounded))
                            .foregroundColor(displayTheme.footerTextColor.opacity(0.88))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .padding(.leading, 1.5 * scale)
                    }
                }

                Spacer(minLength: 6 * scale)

                if let qr = qrCodeImage {
                    Image(uiImage: qr)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 32 * scale, height: 32 * scale)
                        .padding(2.5 * scale)
                        .background(Color.white)
                        .cornerRadius(5 * scale)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5 * scale)
                                .stroke(
                                    isDarkFooterText
                                        ? Color(red: 15 / 255.0, green: 23 / 255.0, blue: 42 / 255.0).opacity(0.16)
                                        : Color.clear,
                                    lineWidth: 0.65 * scale
                                )
                        )
                        .shadow(color: Color.black.opacity(isDarkFooterText ? 0.08 : 0.18), radius: 2 * scale)
                }
            }
            .environment(\.layoutDirection, .leftToRight)
            .padding(.horizontal, 6 * scale)
            .padding(.bottom, 2 * scale)
            .padding(.top, 2 * scale)
            .layoutPriority(1)
        }
        .padding(.horizontal, outerPadding)
        .padding(.top, outerPadding)
        .padding(.bottom, bottomPadding)
        .frame(width: cardWidth, height: cardHeight)
        .background(
            ZStack {
                if transparentBackground {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.55),
                            Color.black.opacity(0.40),
                            Color.black.opacity(0.65)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else if let bg = photoBackground {
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
                    displayTheme.backgroundGradient

                    // Subtle Islamic geometric lattice pattern
                    if displayTheme != .minimal {
                        IslamicLatticeBackground(color: displayTheme.innerBorderColor.opacity(0.22))
                            .opacity(0.4)
                            .clipped()
                    }
                }

                // Inner ornate border
                RoundedRectangle(cornerRadius: max(0, cornerRadius - (4 * scale)))
                    .stroke(displayTheme.innerBorderColor, lineWidth: 1 * scale)
                    .padding(6 * scale)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    (transparentBackground && isExport) ? Color.clear : displayTheme.borderColor,
                    lineWidth: 1.5 * scale
                )
        )
        .cornerRadius(cornerRadius)
        .clipped()
        .shadow(
            color: isExport ? Color.clear : Color.black.opacity(displayTheme == .minimal ? 0.08 : 0.25),
            radius: isExport ? 0 : 12 * scale,
            x: 0,
            y: isExport ? 0 : 6 * scale
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
            guard size.width.isFinite, size.height.isFinite,
                  size.width > 0, size.height > 0,
                  size.width <= 4096, size.height <= 4096 else {
                return
            }
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

private struct AppleLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 24.0
        let sy = rect.height / 24.0
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }

        var path = Path()
        // Tilted leaf
        path.move(to: pt(15.6, 1.4))
        path.addCurve(to: pt(12.15, 4.95), control1: pt(14.15, 1.55), control2: pt(12.65, 2.55))
        path.addCurve(to: pt(15.6, 1.4), control1: pt(13.8, 5.05), control2: pt(15.35, 3.85))
        path.closeSubpath()

        // Bitten apple body
        path.move(to: pt(12.1, 6.2))
        path.addCurve(to: pt(16.5, 5.35), control1: pt(13.5, 6.2), control2: pt(14.95, 5.25))
        path.addCurve(to: pt(20.15, 7.5), control1: pt(17.95, 5.45), control2: pt(19.35, 6.2))
        path.addCurve(to: pt(20.6, 15.0), control1: pt(17.1, 9.35), control2: pt(17.6, 13.75))
        path.addCurve(to: pt(17.35, 20.4), control1: pt(19.95, 16.75), control2: pt(18.8, 18.95))
        path.addCurve(to: pt(13.65, 21.05), control1: pt(16.15, 21.6), control2: pt(15.05, 21.65))
        path.addCurve(to: pt(10.6, 21.05), control1: pt(12.6, 20.6), control2: pt(11.75, 20.6))
        path.addCurve(to: pt(7.05, 20.35), control1: pt(9.15, 21.65), control2: pt(8.2, 21.55))
        path.addCurve(to: pt(4.75, 9.5), control1: pt(4.65, 17.75), control2: pt(3.35, 13.3))
        path.addCurve(to: pt(9.8, 5.55), control1: pt(5.65, 7.0), control2: pt(7.7, 5.55))
        path.addCurve(to: pt(12.1, 6.2), control1: pt(11.05, 5.55), control2: pt(11.45, 6.2))
        path.closeSubpath()
        return path
    }
}

private struct GooglePlayIconView: View {
    var body: some View {
        Canvas { context, size in
            let sx = size.width / 24.0
            let sy = size.height / 24.0
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * sx, y: y * sy)
            }

            var clip = Path()
            clip.move(to: pt(3.5, 3.0))
            clip.addQuadCurve(to: pt(4.8, 2.2), control: pt(3.5, 1.5))
            clip.addLine(to: pt(20.6, 11.2))
            clip.addQuadCurve(to: pt(20.6, 12.8), control: pt(21.9, 12.0))
            clip.addLine(to: pt(4.8, 21.8))
            clip.addQuadCurve(to: pt(3.5, 21.0), control: pt(3.5, 22.5))
            clip.closeSubpath()

            context.clip(to: clip)

            var cyan = Path()
            cyan.move(to: pt(3.5, 1.5))
            cyan.addLine(to: pt(13.5, 12.0))
            cyan.addLine(to: pt(3.5, 22.5))
            cyan.closeSubpath()
            context.fill(cyan, with: .color(Color(red: 0, green: 210 / 255.0, blue: 1)))

            var green = Path()
            green.move(to: pt(3.5, 1.5))
            green.addLine(to: pt(16.6, 9.1))
            green.addLine(to: pt(13.5, 12.0))
            green.closeSubpath()
            context.fill(green, with: .color(Color(red: 0, green: 240 / 255.0, blue: 118 / 255.0)))

            var yellow = Path()
            yellow.move(to: pt(13.5, 12.0))
            yellow.addLine(to: pt(16.6, 9.1))
            yellow.addLine(to: pt(22.0, 12.0))
            yellow.addLine(to: pt(16.6, 14.9))
            yellow.closeSubpath()
            context.fill(yellow, with: .color(Color(red: 1, green: 196 / 255.0, blue: 0)))

            var red = Path()
            red.move(to: pt(3.5, 22.5))
            red.addLine(to: pt(13.5, 12.0))
            red.addLine(to: pt(16.6, 14.9))
            red.closeSubpath()
            context.fill(red, with: .color(Color(red: 1, green: 58 / 255.0, blue: 68 / 255.0)))
        }
    }
}
