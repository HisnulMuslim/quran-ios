//
//  RemoteBackgroundPickerView.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import Localization
import SwiftUI

public struct RemoteBackgroundPickerView: View {
    @ObservedObject var viewModel: AyahShareImageViewModel
    @Binding var isPresented: Bool

    @State private var catalog: [RemoteAyahBackgroundItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var downloadingId: String?
    @State private var downloadAlertMessage: String?

    private var isKannada: Bool {
        AppLanguage == .kannada || Locale.current.languageCode == "kn"
    }

    public init(viewModel: AyahShareImageViewModel, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._isPresented = isPresented
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(isKannada ? "ಹಿನ್ನೆಲೆಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ..." : "Loading backgrounds...")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 14) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button {
                            Task { await loadCatalog() }
                        } label: {
                            Text(isKannada ? "ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ" : "Try Again")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(catalog) { item in
                                Button {
                                    Task { await selectItem(item) }
                                } label: {
                                    ZStack(alignment: .bottomLeading) {
                                        // Background Image / Thumbnail
                                        RemoteThumbnailView(item: item)
                                            .frame(height: 120)
                                            .clipped()
                                            .cornerRadius(12)

                                        // Dark gradient overlay
                                        LinearGradient(
                                            colors: [Color.clear, Color.black.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .cornerRadius(12)

                                        // Title
                                        Text(item.localizedName)
                                            .font(.system(size: 11.5, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                            .padding(.horizontal, 10)
                                            .padding(.bottom, 8)

                                        // Downloading Spinner
                                        if downloadingId == item.id {
                                            ZStack {
                                                Color.black.opacity(0.55)
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            }
                                            .cornerRadius(12)
                                        } else if isCached(item.id) {
                                            // Subtle indicator that image is downloaded and available offline
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 15))
                                                .foregroundColor(.white)
                                                .shadow(color: Color.black.opacity(0.6), radius: 3, x: 0, y: 1)
                                                .padding(7)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                        }
                                    }
                                    .frame(height: 120)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle(isKannada ? "ಇನ್ನಷ್ಟು ಹಿನ್ನೆಲೆಗಳು" : "More Backgrounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isKannada ? "ಮುಚ್ಚಿ" : "Close") {
                        isPresented = false
                    }
                }
            }
            .alert(isPresented: Binding(
                get: { downloadAlertMessage != nil },
                set: { if !$0 { downloadAlertMessage = nil } }
            )) {
                Alert(
                    title: Text(isKannada ? "ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕ ಅಗತ್ಯವಿದೆ" : "Internet Connection Required"),
                    message: Text(downloadAlertMessage ?? ""),
                    dismissButton: .default(Text(isKannada ? "ಸರಿ" : "OK"))
                )
            }
        }
        .task {
            await loadCatalog()
        }
    }

    private func isCached(_ id: String) -> Bool {
        RemoteBackgroundService.shared.cachedImage(for: id) != nil
    }

    private func loadCatalog(forceRefresh: Bool = false) async {
        // Instant presentation: show previously cached catalog immediately if available
        if catalog.isEmpty {
            if let cached = RemoteBackgroundService.shared.cachedCatalog(), !cached.isEmpty {
                self.catalog = cached
                self.isLoading = false
            } else {
                self.isLoading = true
            }
        }
        errorMessage = nil

        do {
            let items = try await RemoteBackgroundService.shared.fetchCatalog(forceRefresh: forceRefresh)
            withAnimation(.easeInOut(duration: 0.2)) {
                self.catalog = items
            }
            self.isLoading = false
        } catch {
            if catalog.isEmpty {
                self.errorMessage = isKannada ? "ಹಿನ್ನೆಲೆಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕವನ್ನು ಪರಿಶೀಲಿಸಿ." : "Could not load cloud backgrounds. Please check your internet connection."
            }
            self.isLoading = false
        }
    }

    private func selectItem(_ item: RemoteAyahBackgroundItem) async {
        downloadingId = item.id
        defer { downloadingId = nil }

        do {
            let image = try await RemoteBackgroundService.shared.downloadAndCacheImage(for: item)
            viewModel.customBackgroundImage = image
            viewModel.selectedTheme = .customPhoto
            isPresented = false
        } catch {
            downloadAlertMessage = isKannada
                ? "ಈ ಹಿನ್ನೆಲೆಯನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡಲು ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕದ ಅಗತ್ಯವಿದೆ."
                : "An active internet connection is required to download this background."
        }
    }
}

private struct RemoteThumbnailView: View {
    let item: RemoteAyahBackgroundItem
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { proxy in
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                ZStack {
                    Color(UIColor.tertiarySystemGroupedBackground)
                    ProgressView()
                }
                .task {
                    if let cached = RemoteBackgroundService.shared.cachedThumbnail(for: item.id) {
                        self.image = cached
                    } else if let downloaded = await RemoteBackgroundService.shared.downloadAndCacheThumbnail(for: item) {
                        self.image = downloaded
                    }
                }
            }
        }
    }
}

