//
//  QuranFrontispieceView.swift
//
//
//  Created by Mohamed Afifi on 2026-10-04.
//

import NoorFont
import QuranKit
import QuranText
import SwiftUI
import UIx

public struct QuranFrontispieceView<Content: View>: View {
    let suraName: String
    let besmAllah: String
    let besmAllahFontSize: FontSize
    let content: Content

    public init(
        suraName: String,
        besmAllah: String = "",
        besmAllahFontSize: FontSize = .level1,
        @ViewBuilder content: () -> Content
    ) {
        self.suraName = suraName
        self.besmAllah = besmAllah
        self.besmAllahFontSize = besmAllahFontSize
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Surah Header Banner
            NoorImage.suraHeader.image
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .overlay {
                    Text(suraName)
                        .font(.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)

            // Bismillah if applicable (e.g. Surah Al-Baqarah)
            if !besmAllah.isEmpty {
                Text(besmAllah)
                    .font(.quran())
                    .dynamicTypeSize(besmAllahFontSize.dynamicTypeSize)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            } else {
                Spacer().frame(height: 12)
            }

            // Arabic text content
            content
                .padding(.horizontal, 4)
                .padding(.vertical, 6)

            // Bottom decorative footer ornament
            footerOrnament
                .padding(.top, 14)
                .padding(.bottom, 12)
        }
        .padding(8)
        .overlay {
            FrontispieceFrameBorder()
        }
        .readableInsetsPadding(.horizontal)
    }

    private var footerOrnament: some View {
        HStack(spacing: 12) {
            Rectangle()
                .frame(height: 1)
                .opacity(0.25)

            NoorImage.ayahEnd.image
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .opacity(0.65)

            Rectangle()
                .frame(height: 1)
                .opacity(0.25)
        }
        .padding(.horizontal, 24)
        .themedSecondaryForeground()
    }
}

private struct FrontispieceFrameBorder: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                // Outer border
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(lineWidth: 1)
                    .opacity(0.28)

                // Inner border inset by 4 pt
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(lineWidth: 1.5)
                    .padding(4)
                    .opacity(0.55)

                // Four corner accents
                cornerAccent(x: 12, y: 12)
                cornerAccent(x: w - 12, y: 12)
                cornerAccent(x: 12, y: h - 12)
                cornerAccent(x: w - 12, y: h - 12)
            }
        }
        .themedSecondaryForeground()
    }

    private func cornerAccent(x: CGFloat, y: CGFloat) -> some View {
        Image(systemName: "diamond.fill")
            .font(.system(size: 5))
            .position(x: x, y: y)
            .opacity(0.7)
    }
}
