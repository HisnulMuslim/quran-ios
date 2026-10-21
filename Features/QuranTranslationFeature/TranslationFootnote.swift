//
//  TranslationFootnote.swift
//
//
//  Created by Mohamed Afifi on 2024-01-20.
//

import Localization
import QuranText
import QuranTextKit
import SwiftUI
import UIKit
import UIx

struct TranslationFootnote: View, Identifiable {
    struct Id: Hashable {
        let string: TranslationString
        let footnoteIndex: Int

        let translation: Translation
        let translationFontSize: FontSize
        let translationFont: TranslationFont
    }

    var id: Id { Id(string: string, footnoteIndex: footnoteIndex, translation: translation, translationFontSize: translationFontSize, translationFont: translationFont) }

    var text: String {
        let text = string.footnotes[footnoteIndex]
        return text.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
    }

    let string: TranslationString
    let footnoteIndex: Int

    let translation: Translation
    let translationFontSize: FontSize
    let translationFont: TranslationFont

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(text)
                    .font(translation.textFont(fontSize: translationFontSize, selection: translationFont.rawValue))
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .themedForeground()
            .themedBackground()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(lFormat("translation.text.footnote-title", footnoteIndex + 1))
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Text(l("button.done"))
                        .bold()
                        .foregroundStyle(Color.appIdentity)
                }
            }
        }
        .frame(
            minWidth: preferredSheetSize.width > 0 ? preferredSheetSize.width : nil,
            idealWidth: preferredSheetSize.width > 0 ? preferredSheetSize.width : nil,
            minHeight: preferredSheetSize.height > 0 ? preferredSheetSize.height : nil,
            idealHeight: preferredSheetSize.height > 0 ? preferredSheetSize.height : nil
        )
        .sheetPresentationDetents(detents)
        .background(SheetPreferredContentSizeModifier(size: preferredSheetSize))
    }

    private var preferredSheetSize: CGSize {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return .zero
        }
        let bounds = UIScreen.main.bounds
        let screenWidth = bounds.width
        let screenHeight = bounds.height
        let width = min(screenWidth - 120, min(750, max(620, round(screenWidth * 0.70))))
        let height = min(screenHeight - 160, min(850, max(580, round(screenHeight * 0.60))))
        return CGSize(width: width, height: height)
    }

    private var detents: [SheetPresentationDetent] {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return []
        } else {
            return [.medium, .large]
        }
    }
}

private struct SheetPreferredContentSizeModifier: UIViewRepresentable {
    let size: CGSize

    func makeUIView(context: Context) -> SizingView {
        let view = SizingView()
        view.targetSize = size
        return view
    }

    func updateUIView(_ uiView: SizingView, context: Context) {
        uiView.targetSize = size
        uiView.applySize()
    }

    final class SizingView: UIView {
        var targetSize: CGSize = .zero

        override func didMoveToWindow() {
            super.didMoveToWindow()
            applySize()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            applySize()
        }

        func applySize() {
            guard targetSize != .zero else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                var responder: UIResponder? = self
                while let r = responder {
                    if let vc = r as? UIViewController {
                        var current: UIViewController? = vc
                        while let c = current {
                            if let sheet = c.sheetPresentationController {
                                sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
                                sheet.animateChanges {
                                    c.preferredContentSize = self.targetSize
                                }
                            } else if c.preferredContentSize != self.targetSize {
                                c.preferredContentSize = self.targetSize
                            }
                            current = c.parent
                        }
                        break
                    }
                    responder = r.next
                }
            }
        }
    }
}

private struct TranslationFootnotePreview: View {
    static let string = TranslationString(
        text: "",
        quranRanges: [],
        footnoteRanges: [],
        footnotes: ["Footnote # 1", "Footnote # 2"]
    )

    static var translation: Translation {
        Translation(
            id: 1,
            displayName: "",
            translator: "",
            translatorForeign: "Khan & Hilai",
            fileURL: URL(validURL: "a"),
            fileName: "quran.en.khanhilali.db",
            languageCode: "",
            version: 5,
            installedVersion: 5
        )
    }

    @State var footnote: TranslationFootnote? = buildFootnote(index: 0)

    var body: some View {
        List {
            ForEach(0 ..< Self.string.footnotes.count, id: \.self) { index in
                Button {
                    footnote = Self.buildFootnote(index: index)
                } label: {
                    Text("Footnote \(index + 1)")
                }
            }
        }
        .sheet(item: $footnote) { $0 }
    }

    private static func buildFootnote(index: Int) -> TranslationFootnote {
        TranslationFootnote(string: string, footnoteIndex: index, translation: translation, translationFontSize: .medium, translationFont: .notoSans)
    }
}

#Preview {
    TranslationFootnotePreview()
        .environment(\.themeStyle, .calm)
}
