//
//  FontSizeStepper.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-27.
//

import Localization
import NoorUI
import QuranText
import SwiftUI
import VLogging

struct FontSizeStepper: View {
    // MARK: Internal

    @Binding var fontSize: FontSize
    let range = FontSize.supportedRange

    @ScaledMetric var cornerRadius = Dimensions.cornerRadius
    @ScaledMetric var defaultSpacing = 5
    @ScaledMetric var dotsSpacing = 8

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                // Decrease button (minus)
                stepperButton(systemName: "minus") {
                    let index = currentSizeIndex
                    guard index > 0 else {
                        logger.error("FontSizeStepper: Cannot decrease font size beyond 0 index.")
                        return
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    fontSize = range[index - 1]
                }
                .disabled(currentSizeIndex == 0)

                Divider()

                // Increase button (plus)
                stepperButton(systemName: "plus") {
                    let index = currentSizeIndex
                    guard index < range.count - 1 else {
                        logger.error("FontSizeStepper: Cannot increase font size beyond \(range.count - 1) index.")
                        return
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    fontSize = range[index + 1]
                }
                .disabled(currentSizeIndex >= range.count - 1)
            }
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(uiColor: .tertiarySystemFill))
            )
            .fixedSize(horizontal: false, vertical: true)

            // 12-point step indicator (clearly visible in both light & dark mode)
            HStack(spacing: 6) {
                ForEach(range.indices, id: \.self) { stepIndex in
                    let isActive = stepIndex <= currentSizeIndex
                    let isCurrent = stepIndex == currentSizeIndex

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        fontSize = range[stepIndex]
                    } label: {
                        ZStack {
                            if isActive {
                                Circle()
                                    .fill(Color.appIdentity)
                                    .frame(width: isCurrent ? 7.5 : 5.5, height: isCurrent ? 7.5 : 5.5)
                            } else {
                                Circle()
                                    .fill(Color.primary.opacity(0.25))
                                    .frame(width: 5.5, height: 5.5)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary.opacity(0.20), lineWidth: 0.5)
                                    )
                            }
                        }
                        .frame(width: 10, height: 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 2)
            .animation(.easeInOut(duration: 0.18), value: currentSizeIndex)
        }
    }

    // MARK: Private

    private var currentSizeIndex: Int {
        if let index = range.firstIndex(of: fontSize) {
            return index
        }
        let clamped = fontSize.clampedToSupported
        if let index = range.firstIndex(of: clamped) {
            return index
        }
        logger.error("Couldn't find \(fontSize) in \(range)")
        return 0
    }

    @ViewBuilder
    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
        }
        .tint(.label)
    }
}

// MARK: - Preview

#Preview {
    struct FontSizeStepper_Previews: View {
        @State var size = FontSize.level1

        var body: some View {
            HStack {
                Text("Quran")
                FontSizeStepper(fontSize: $size)
            }
            .padding()
        }
    }

    return FontSizeStepper_Previews()
}
