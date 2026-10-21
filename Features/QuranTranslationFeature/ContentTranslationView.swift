//
//  ContentTranslationView.swift
//
//
//  Created by Mohamed Afifi on 2023-12-29.
//

import Localization
import NoorUI
import QuranKit
import QuranPagesFeature
import QuranText
import SwiftUI
import UIx
import Utilities

public struct ContentTranslationView: View {
    @StateObject var viewModel: ContentTranslationViewModel

    public init(viewModel: @autoclosure @escaping () -> ContentTranslationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        ContentTranslationViewBody(
            items: viewModel.items,
            arabicFontSize: viewModel.arabicFontSize,
            translationFontSize: viewModel.translationFontSize,
            highlights: viewModel.highlights,
            scrollToItem: viewModel.scrollToItem,
            tracker: viewModel.tracker,
            footnote: $viewModel.footnote,
            isTranslationOnlyEmpty: viewModel.isTranslationOnlyEmpty,
            openURL: { viewModel.openURL($0) },
            onPinchOut: { viewModel.increaseFontSizes() },
            onPinchIn: { viewModel.decreaseFontSizes() },
            onDoubleTap: { viewModel.resetFontSizesToDefault() },
            onSwitchToArabic: { viewModel.switchToArabicMode() }
        )
        .geometryActions(
            PageGeometryActions(
                id: ObjectIdentifier(viewModel),
                word: { _ in nil },
                verse: { point in viewModel.ayahAtPoint(point) }
            )
        )
        .task(id: Pair(viewModel.verses, viewModel.selectedTranslations)) {
            await viewModel.load()
        }
    }
}

private class PinchGestureView: UIView, UIGestureRecognizerDelegate {
    var onPinchOut: (() -> Void)?
    var onPinchIn: (() -> Void)?
    var onDoubleTap: (() -> Void)?

    private var pinchGesture: UIPinchGestureRecognizer?
    private var doubleTapGesture: UITapGestureRecognizer?
    private weak var targetView: UIView?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private var lastStepTime: Date = .distantPast

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else {
            if let gesture = pinchGesture {
                targetView?.removeGestureRecognizer(gesture)
                pinchGesture = nil
            }
            if let gesture = doubleTapGesture {
                targetView?.removeGestureRecognizer(gesture)
                doubleTapGesture = nil
            }
            targetView = nil
            return
        }

        feedbackGenerator.prepare()

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.window != nil, self.pinchGesture == nil else { return }
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
            pinch.delegate = self
            self.pinchGesture = pinch

            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTap(_:)))
            doubleTap.numberOfTapsRequired = 2
            doubleTap.delegate = self
            self.doubleTapGesture = doubleTap

            let target = self.findTargetView() ?? self
            target.addGestureRecognizer(pinch)
            target.addGestureRecognizer(doubleTap)
            self.targetView = target
        }
    }

    private func findTargetView() -> UIView? {
        var current: UIView? = self
        while let view = current {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            if let parent = view.superview {
                for subview in parent.subviews {
                    if let scrollView = subview as? UIScrollView {
                        return scrollView
                    }
                }
            }
            current = view.superview
        }
        return superview
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.state == .changed else {
            if gesture.state == .began {
                feedbackGenerator.prepare()
            }
            return
        }

        let now = Date()
        guard now.timeIntervalSince(lastStepTime) >= 0.14 else { return }

        let scale = gesture.scale
        if scale >= 1.08 {
            lastStepTime = now
            feedbackGenerator.impactOccurred()
            feedbackGenerator.prepare()
            onPinchOut?()
            gesture.scale = 1.0
        } else if scale <= 0.92 {
            lastStepTime = now
            feedbackGenerator.impactOccurred()
            feedbackGenerator.prepare()
            onPinchIn?()
            gesture.scale = 1.0
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        feedbackGenerator.impactOccurred()
        feedbackGenerator.prepare()
        onDoubleTap?()
    }
}

private struct PinchGestureViewRepresentable: UIViewRepresentable {
    let onPinchOut: () -> Void
    let onPinchIn: () -> Void
    let onDoubleTap: () -> Void

    func makeUIView(context: Context) -> PinchGestureView {
        let view = PinchGestureView()
        view.onPinchOut = onPinchOut
        view.onPinchIn = onPinchIn
        view.onDoubleTap = onDoubleTap
        return view
    }

    func updateUIView(_ uiView: PinchGestureView, context: Context) {
        uiView.onPinchOut = onPinchOut
        uiView.onPinchIn = onPinchIn
        uiView.onDoubleTap = onDoubleTap
    }
}

private struct ContentTranslationViewBody: View {
    let items: [TranslationItem]

    let arabicFontSize: FontSize
    let translationFontSize: FontSize
    let highlights: [AyahNumber: Color]
    let scrollToItem: TranslationItemId?
    let tracker: CollectionTracker<TranslationItemId>

    @Binding var footnote: TranslationFootnote?
    let isTranslationOnlyEmpty: Bool

    let openURL: (TranslationURL) -> Void
    let onPinchOut: () -> Void
    let onPinchIn: () -> Void
    let onDoubleTap: () -> Void
    let onSwitchToArabic: () -> Void

    private var isFrontispiecePage: Bool {
        items.contains { if case .frontispieceArabic = $0 { return true }; return false }
    }

    private var headerItem: TranslationItem? {
        items.first { if case .pageHeader = $0 { return true }; return false }
    }

    private var footerItem: TranslationItem? {
        items.first { if case .pageFooter = $0 { return true }; return false }
    }

    private var frontispieceItem: TranslationItem? {
        items.first { if case .frontispieceArabic = $0 { return true }; return false }
    }

    var body: some View {
        Group {
            if isTranslationOnlyEmpty {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            if let header = headerItem {
                                header
                            }
                            Spacer(minLength: 32)

                            TranslationOnlyEmptyStateView(
                                onDownloadTapped: {
                                    NotificationCenter.default.post(name: .requestTranslationsSelection, object: nil)
                                },
                                onSwitchToArabicTapped: onSwitchToArabic
                            )

                            Spacer(minLength: 32)

                            if let footer = footerItem {
                                footer
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    }
                }
            } else if isFrontispiecePage {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            if let header = headerItem {
                                header
                            }
                            Spacer(minLength: 8)
                            if let frontispiece = frontispieceItem {
                                frontispiece
                            }
                            Spacer(minLength: 8)
                            if let footer = footerItem {
                                footer
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    }
                }
            } else {
                List {
                    ForEach(items) { item in
                        item
                    }
                }
                .listStyle(.plain)
                .environment(\.defaultMinListRowHeight, 1)
            }
        }
        .populateReadableInsets()
        .openTranslationURL(openURL)
        .trackCollection(with: tracker)
        .quranScrolling(scrollToValue: scrollToItem)
        .sheet(item: $footnote) { $0 }
        .background(PinchGestureViewRepresentable(onPinchOut: onPinchOut, onPinchIn: onPinchIn, onDoubleTap: onDoubleTap))
    }
}

private struct TranslationOnlyEmptyStateView: View {
    let onDownloadTapped: () -> Void
    let onSwitchToArabicTapped: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "character.book.closed.fill")
                    .font(.system(size: 38))
                    .foregroundColor(.accentColor)
            }
            .padding(.top, 8)

            VStack(spacing: 8) {
                Text(l("translation_only_empty_title"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(l("translation_only_empty_message"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineSpacing(3)
            }

            VStack(spacing: 12) {
                Button(action: onDownloadTapped) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(l("translation_only_empty_download_button"))
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onSwitchToArabicTapped) {
                    HStack(spacing: 8) {
                        Image(systemName: "text.alignright")
                            .font(.system(size: 16, weight: .semibold))
                        Text(l("translation_only_empty_switch_button"))
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        )
        .padding(.horizontal, 24)
    }
}
