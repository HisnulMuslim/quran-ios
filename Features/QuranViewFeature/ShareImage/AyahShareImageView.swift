//
//  AyahShareImageView.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import Localization
import SwiftUI

public struct AyahShareImageView: View {
    @ObservedObject var viewModel: AyahShareImageViewModel
    let onDismiss: () -> Void

    public init(viewModel: AyahShareImageViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    private var isKannada: Bool {
        AppLanguage == .kannada || Locale.current.languageCode == "kn"
    }

    public var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                } else if let cardData = viewModel.cardData {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Live Card Preview
                            AyahShareCardView(
                                data: cardData,
                                theme: viewModel.selectedTheme,
                                showArabic: viewModel.showArabic,
                                showTranslation: viewModel.showTranslation,
                                isExport: false
                            )
                            .padding(.top, 8)

                            // Theme Selector
                            VStack(alignment: .leading, spacing: 10) {
                                Text(isKannada ? "ಶೈಲಿ ಮತ್ತು ಹಿನ್ನೆಲೆ" : "Themes & Styles")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)

                                HStack(spacing: 8) {
                                    ForEach(AyahCardTheme.allCases) { theme in
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(theme.iconColor)
                                                .frame(width: 14, height: 14)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                                )
                                            Text(theme.displayName)
                                                .font(.system(size: 13, weight: viewModel.selectedTheme == theme ? .semibold : .regular))
                                        }
                                        .foregroundColor(viewModel.selectedTheme == theme ? .primary : .secondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(viewModel.selectedTheme == theme ? Color(UIColor.secondarySystemGroupedBackground) : Color.clear)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(viewModel.selectedTheme == theme ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: viewModel.selectedTheme == theme ? 1.5 : 1)
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                viewModel.selectedTheme = theme
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Customization Toggles
                            VStack(spacing: 0) {
                                Toggle(isKannada ? "ಅರೇಬಿಕ್ ಪಠ್ಯ ತೋರಿಸಿ" : "Show Arabic Text", isOn: $viewModel.showArabic)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)

                                Divider()
                                    .padding(.leading, 16)

                                Toggle(isKannada ? "ಅನುವಾದ ತೋರಿಸಿ" : "Show Translation", isOn: $viewModel.showTranslation)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)

                            // Action Buttons
                            VStack(spacing: 10) {
                                // WhatsApp / Share Button
                                Button {
                                    triggerShare()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text(isKannada ? "ವಾಟ್ಸಾಪ್ / ಹಂಚಿಕೊಳ್ಳಿ" : "Share / WhatsApp")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.12, green: 0.65, blue: 0.38)) // WhatsApp Green
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                // Save to Photos Button
                                Button {
                                    viewModel.saveToPhotos()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.down.to.line")
                                            .font(.system(size: 15, weight: .medium))
                                        Text(isKannada ? "ಫೋಟೋಗಳಿಗೆ ಉಳಿಸಿ" : "Save to Photos")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 30)
                        }
                    }
                }

                // Toast Banner
                if let toast = viewModel.saveSuccessToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(toast)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.85))
                        )
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(), value: toast)
                }
            }
            .navigationTitle(isKannada ? "ಚಿತ್ರ ಹಂಚಿಕೆ" : "Share Ayah")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    private func triggerShare() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController else {
            return
        }
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        viewModel.share(from: topVC, sourceView: nil)
    }
}
