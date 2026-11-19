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

    @State private var catalog: [RemoteAyahBackgroundItem]
    @State private var isLoading: Bool
    @State private var errorMessage: String?
    @State private var downloadingId: String?
    @State private var downloadAlertMessage: String?
    @State private var selectedTab: Int // 0 = Photos, 1 = Videos
    @State private var videoFilter: RemoteVideoResolutionFilter = .all
    @State private var cachedIds: Set<String> = []

    public init(viewModel: AyahShareImageViewModel, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        let startWithVideo = viewModel.isVideoMode && viewModel.backgroundMode == 2
        self._selectedTab = State(initialValue: startWithVideo ? 1 : 0)
        let initialCatalog = viewModel.catalogItems.isEmpty
            ? (RemoteBackgroundService.shared.cachedCatalog() ?? [])
            : viewModel.catalogItems
        self._catalog = State(initialValue: initialCatalog)
        self._isLoading = State(initialValue: initialCatalog.isEmpty)
    }

    private var allVideos: [RemoteAyahBackgroundItem] {
        catalog.filter { $0.isVideo }
    }

    private var hdVideos: [RemoteAyahBackgroundItem] {
        allVideos.filter { $0.isHdVideo }
    }

    private var standardVideos: [RemoteAyahBackgroundItem] {
        allVideos.filter { !$0.isHdVideo }
    }

    private var displayedCatalog: [RemoteAyahBackgroundItem] {
        if viewModel.isVideoMode && selectedTab == 1 {
            switch videoFilter {
            case .all:
                return allVideos
            case .hd1080p:
                return hdVideos
            case .standard720p:
                return standardVideos
            }
        }
        return catalog.filter { !$0.isVideo }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                mainContent
            }
        } else {
            NavigationView {
                mainContent
            }
            .navigationViewStyle(.stack)
        }
    }

    private var mainContent: some View {
        ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(lChoice(kn: "ಹಿನ್ನೆಲೆಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...", en: "Loading backgrounds...", ar: "جارٍ تحميل الخلفيات..."))
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
                            Text(lChoice(kn: "ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ", en: "Try Again", ar: "إعادة المحاولة"))
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        if viewModel.isVideoMode {
                            Picker("", selection: $selectedTab) {
                                Text(lChoice(kn: "ಫೋಟೋಗಳು", en: "Photos", ar: "صور")).tag(0)
                                Text(lChoice(kn: "ವೀಡಿಯೊಗಳು", en: "Videos", ar: "فيديوهات")).tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)

                            if selectedTab == 1 && !allVideos.isEmpty {
                                Picker("", selection: $videoFilter) {
                                    Text("\(RemoteVideoResolutionFilter.all.displayName) (\(allVideos.count))")
                                        .tag(RemoteVideoResolutionFilter.all)
                                    Text("\(RemoteVideoResolutionFilter.hd1080p.displayName) (\(hdVideos.count))")
                                        .tag(RemoteVideoResolutionFilter.hd1080p)
                                    Text("\(RemoteVideoResolutionFilter.standard720p.displayName) (\(standardVideos.count))")
                                        .tag(RemoteVideoResolutionFilter.standard720p)
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                            }
                        }

                        if displayedCatalog.isEmpty {
                            let emptyText: String = {
                                if selectedTab == 1 && videoFilter == .hd1080p {
                                    return lChoice(
                                        kn: "1080p HD ವೀಡಿಯೊಗಳು ಶೀಘ್ರದಲ್ಲೇ ಬರಲಿವೆ.",
                                        en: "1080p HD videos coming soon.",
                                        ar: "فيديوهات 1080p HD قريباً."
                                    )
                                }
                                return selectedTab == 1
                                    ? lChoice(kn: "ಕ್ಲೌಡ್ ವೀಡಿಯೊಗಳು ಲಭ್ಯವಿಲ್ಲ.", en: "No cloud videos available right now.", ar: "لا توجد فيديوهات سحابية متاحة حالياً.")
                                    : lChoice(kn: "ಕ್ಲೌಡ್ ಫೋಟೋಗಳು ಲಭ್ಯವಿಲ್ಲ.", en: "No cloud photos available right now.", ar: "لا توجد صور سحابية متاحة حالياً.")
                            }()
                            VStack(spacing: 12) {
                                Image(systemName: selectedTab == 1 ? "video.slash" : "photo")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary)
                                Text(emptyText)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 14) {
                                    ForEach(displayedCatalog) { item in
                                        Button {
                                            Task { await selectItem(item) }
                                        } label: {
                                            ZStack(alignment: .bottomLeading) {
                                                // Background Image / Thumbnail
                                                RemoteThumbnailView(item: item)
                                                    .frame(maxWidth: .infinity)
                                                    .frame(height: 120)

                                                // Dark gradient overlay
                                                LinearGradient(
                                                    colors: [Color.clear, Color.black.opacity(0.78)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )

                                                // Title
                                                Text(item.localizedName)
                                                    .font(.system(size: 11.5, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                    .padding(.horizontal, 10)
                                                    .padding(.bottom, 8)

                                                // Video badge + HD + Size (top leading)
                                                if item.isVideo {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "video.fill")
                                                            .font(.system(size: 10, weight: .bold))
                                                        if let sec = item.durationSec, sec > 0 {
                                                            Text(formatDuration(sec))
                                                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                                        }
                                                        if item.isHdVideo {
                                                            Text("HD")
                                                                .font(.system(size: 8.5, weight: .heavy))
                                                                .padding(.horizontal, 4)
                                                                .padding(.vertical, 1)
                                                                .background(Color.accentColor)
                                                                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                                                        }
                                                        if let sizeText = item.formattedSizeLabel {
                                                            Text("· \(sizeText)")
                                                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                                        }
                                                    }
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 7)
                                                    .padding(.vertical, 3)
                                                    .background(Color.black.opacity(0.65))
                                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                                    .padding(7)
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                                }

                                                // Downloading Spinner
                                                if downloadingId == item.id {
                                                    ZStack {
                                                        Color.black.opacity(0.55)
                                                        ProgressView()
                                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    }
                                                } else if cachedIds.contains(item.id) {
                                                    // Subtle indicator that background is downloaded and available offline
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 15))
                                                        .foregroundColor(.white)
                                                        .padding(7)
                                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                                }
                                            }
                                            .frame(height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(Color.accentColor.opacity(0.28), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(16)
                            }
                        }
                    }
                }
            }
            .navigationTitle(lChoice(kn: "ಇನ್ನಷ್ಟು ಹಿನ್ನೆಲೆಗಳು", en: "More Backgrounds", ar: "المزيد من الخلفيات"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lChoice(kn: "ಮುಚ್ಚಿ", en: "Close", ar: "إغلاق")) {
                        isPresented = false
                    }
                }
            }
            .alert(isPresented: Binding(
                get: { downloadAlertMessage != nil },
                set: { if !$0 { downloadAlertMessage = nil } }
            )) {
                Alert(
                    title: Text(lChoice(kn: "ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕ ಅಗತ್ಯವಿದೆ", en: "Internet Connection Required", ar: "الاتصال بالإنترنت مطلوب")),
                    message: Text(downloadAlertMessage ?? ""),
                    dismissButton: .default(Text(lChoice(kn: "ಸರಿ", en: "OK", ar: "حسناً")))
                )
            }
        .task {
            await refreshCachedIds()
            await loadCatalog()
        }
    }

    @MainActor
    private func refreshCachedIds() async {
        let ids = await Task.detached(priority: .userInitiated) {
            RemoteBackgroundService.shared.cachedBackgroundIds()
        }.value
        cachedIds = ids
    }

    private func formatDuration(_ sec: Double) -> String {
        let total = max(0, Int(round(sec)))
        let mins = total / 60
        let rem = total % 60
        return String(format: "%d:%02d", mins, rem)
    }

    @MainActor
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
            self.catalog = items
            self.isLoading = false
            await refreshCachedIds()
        } catch {
            if catalog.isEmpty {
                self.errorMessage = lChoice(
                    kn: "ಹಿನ್ನೆಲೆಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕವನ್ನು ಪರಿಶೀಲಿಸಿ.",
                    en: "Could not load cloud backgrounds. Please check your internet connection.",
                    ar: "تعذر تحميل الخلفيات السحابية. يرجى التحقق من اتصال الإنترنت."
                )
            }
            self.isLoading = false
        }
    }

    @MainActor
    private func selectItem(_ item: RemoteAyahBackgroundItem) async {
        downloadingId = item.id
        defer { downloadingId = nil }

        do {
            if item.isVideo {
                if RemoteBackgroundService.shared.cachedVideoURL(for: item.id) == nil {
                    _ = try await RemoteBackgroundService.shared.downloadAndCacheVideo(for: item)
                }
                cachedIds.insert(item.id)
                viewModel.selectRemoteVideo(item)
                isPresented = false
            } else {
                let image = try await RemoteBackgroundService.shared.downloadAndCacheImage(for: item)
                cachedIds.insert(item.id)
                viewModel.applyDownloadedRemotePhoto(item, image: image)
                isPresented = false
            }
        } catch {
            downloadAlertMessage = lChoice(
                kn: "ಈ ಹಿನ್ನೆಲೆಯನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡಲು ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕದ ಅಗತ್ಯವಿದೆ.",
                en: "An active internet connection is required to download this background.",
                ar: "مطلوب اتصال نشط بالإنترنت لتنزيل هذه الخلفية."
            )
        }
    }
}

private struct RemoteThumbnailView: View {
    let item: RemoteAyahBackgroundItem
    @State private var image: UIImage?

    init(item: RemoteAyahBackgroundItem) {
        self.item = item
        self._image = State(initialValue: RemoteBackgroundService.shared.cachedMemoryThumbnail(for: item.id))
    }

    var body: some View {
        Color(UIColor.tertiarySystemGroupedBackground)
            .overlay(
                Group {
                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ProgressView()
                    }
                }
            )
            .clipped()
            .task(id: item.id) {
                if image == nil {
                    image = await RemoteBackgroundService.shared.loadThumbnail(for: item)
                }
            }
    }
}

