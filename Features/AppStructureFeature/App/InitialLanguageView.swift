//
//  InitialLanguageView.swift
//  Quran
//
//  Created by Antigravity on 9/30/26.
//

import Localization
import SwiftUI
import UIKit

// MARK: - Luxury Theme Palette

private enum LuxuryLanguageTheme {
    /// Specified primary green: #022B24 (Deep Islamic Pine/Forest Green)
    static let deepGreenBase = Color(red: 2 / 255.0, green: 43 / 255.0, blue: 36 / 255.0)

    /// Subtle gradient top to give the button a lustrous velvet finish
    static let deepGreenTop = Color(red: 8 / 255.0, green: 58 / 255.0, blue: 48 / 255.0)

    /// Subtle champagne gold for medallion highlight & luxury touch
    static let champagneGold = Color(red: 218 / 255.0, green: 180 / 255.0, blue: 112 / 255.0)

    /// Adaptive brand accent for strokes, icons, and indicators
    /// Light: #022B24 | Dark: #22C59E (luminous emerald)
    static let accent = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 34 / 255.0, green: 197 / 255.0, blue: 158 / 255.0, alpha: 1.0)
            : UIColor(red: 2 / 255.0, green: 43 / 255.0, blue: 36 / 255.0, alpha: 1.0)
    })

    /// Adaptive card background when selected
    static let cardSelectedBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 34 / 255.0, green: 197 / 255.0, blue: 158 / 255.0, alpha: 0.10)
            : UIColor(red: 2 / 255.0, green: 43 / 255.0, blue: 36 / 255.0, alpha: 0.06)
    })

    /// Adaptive script badge background when selected
    static let badgeSelectedBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 34 / 255.0, green: 197 / 255.0, blue: 158 / 255.0, alpha: 0.18)
            : UIColor(red: 2 / 255.0, green: 43 / 255.0, blue: 36 / 255.0, alpha: 0.10)
    })

    /// Outer ring stroke for button in dark mode
    static let buttonBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 34 / 255.0, green: 197 / 255.0, blue: 158 / 255.0, alpha: 0.35)
            : UIColor(white: 1.0, alpha: 0.12)
    })
}

// MARK: - Luxury Press Style

private struct LuxuryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Main View

public struct InitialLanguageView: View {
    @State private var selectedLanguage: Language = AppLanguage
    let onCompletion: (Language) -> Void

    public init(onCompletion: @escaping (Language) -> Void) {
        self.onCompletion = onCompletion
    }

    public var body: some View {
        VStack(spacing: 18) {
            // Luxury Header Medallion
            ZStack {
                // Outer subtle glowing aura ring
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                LuxuryLanguageTheme.champagneGold.opacity(0.55),
                                LuxuryLanguageTheme.accent.opacity(0.30)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 62, height: 62)

                // Inner velvet circular disc
                Circle()
                    .fill(LuxuryLanguageTheme.badgeSelectedBackground)
                    .frame(width: 52, height: 52)

                // Globe Icon
                Image(systemName: "globe")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundColor(LuxuryLanguageTheme.accent)
            }
            .padding(.top, 24)

            // Title & Subtitle
            VStack(spacing: 6) {
                Text("ಆ್ಯಪ್ ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Choose App Language")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .tracking(0.3)
            }
            .multilineTextAlignment(.center)

            // Language Cards
            VStack(spacing: 12) {
                languageCard(
                    language: .kannada,
                    primaryTitle: "ಕನ್ನಡ",
                    subtitle: "Kannada",
                    badge: "ಅ ಆ ಇ"
                )

                languageCard(
                    language: .english,
                    primaryTitle: "English",
                    subtitle: "ಇಂಗ್ಲಿಷ್",
                    badge: "A B C"
                )
            }
            .padding(.horizontal, 20)

            // Subtitle Note
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.8))

                Text("ನೀವು ಇದನ್ನು ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಯಾವಾಗ ಬೇಕಾದರೂ ಬದಲಾಯಿಸಬಹುದು\nYou can change this anytime in Settings")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            // Luxury "Get Started / ಪ್ರಾರಂಭಿಸಿ" Button
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onCompletion(selectedLanguage)
            } label: {
                HStack(spacing: 10) {
                    Text(selectedLanguage == .kannada ? "ಪ್ರಾರಂಭಿಸಿ" : "Get Started")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    ZStack {
                        // Deep emerald velvet gradient (anchored in #022B24)
                        LinearGradient(
                            colors: [
                                LuxuryLanguageTheme.deepGreenTop,
                                LuxuryLanguageTheme.deepGreenBase
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        // Top bevel specular highlight for enamel glass effect
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0.04),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(LuxuryLanguageTheme.buttonBorder, lineWidth: 1)
                )
                .shadow(
                    color: LuxuryLanguageTheme.deepGreenBase.opacity(0.4),
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .buttonStyle(LuxuryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
        .background(Color(UIColor.systemBackground))
    }

    private func languageCard(
        language: Language,
        primaryTitle: String,
        subtitle: String,
        badge: String
    ) -> some View {
        let isSelected = selectedLanguage == language

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                selectedLanguage = language
            }
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        } label: {
            HStack(spacing: 14) {
                // Script badge
                Text(badge)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? LuxuryLanguageTheme.accent : .secondary)
                    .frame(width: 48, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? LuxuryLanguageTheme.badgeSelectedBackground : Color(UIColor.tertiarySystemFill))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected ? LuxuryLanguageTheme.accent.opacity(0.25) : Color.clear,
                                lineWidth: 1
                            )
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(primaryTitle)
                        .font(.system(size: 17, weight: isSelected ? .bold : .medium, design: .rounded))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Luxury checkmark / radio indicator
                ZStack {
                    if isSelected {
                        // Outer glowing ring
                        Circle()
                            .stroke(LuxuryLanguageTheme.accent.opacity(0.25), lineWidth: 3)
                            .frame(width: 24, height: 24)

                        // Filled disc with checkmark
                        Circle()
                            .fill(LuxuryLanguageTheme.accent)
                            .frame(width: 20, height: 20)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected
                            ? LuxuryLanguageTheme.cardSelectedBackground
                            : Color(UIColor.secondarySystemBackground)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected
                            ? LuxuryLanguageTheme.accent
                            : Color.primary.opacity(0.06),
                        lineWidth: isSelected ? 1.75 : 1
                    )
            )
            .shadow(
                color: isSelected ? LuxuryLanguageTheme.accent.opacity(0.12) : Color.clear,
                radius: 8,
                x: 0,
                y: 3
            )
        }
        .buttonStyle(.plain)
    }
}
