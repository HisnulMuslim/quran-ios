//
//  JumpDestinationView.swift
//  Quran
//
//  Created by Antigravity on 10/4/26.
//

import Localization
import NoorFont
import NoorUI
import QuranKit
import QuranTextKit
import SwiftUI
import UIKit

// MARK: - Luxury Palette

private enum JumpTheme {
    static let deepGreenBase = Color(red: 2 / 255.0, green: 43 / 255.0, blue: 36 / 255.0)
    static let deepGreenTop = Color(red: 8 / 255.0, green: 58 / 255.0, blue: 48 / 255.0)
    static let champagneGold = Color(red: 218 / 255.0, green: 180 / 255.0, blue: 112 / 255.0)

    static let accent = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 34 / 255.0, green: 197 / 255.0, blue: 158 / 255.0, alpha: 1.0)
            : UIColor(red: 2 / 255.0, green: 43 / 255.0, blue: 36 / 255.0, alpha: 1.0)
    })

    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let cardBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.black.withAlphaComponent(0.06)
    })

    static let badgeBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 34 / 255.0, green: 197 / 255.0, blue: 158 / 255.0, alpha: 0.16)
            : UIColor(red: 2 / 255.0, green: 43 / 255.0, blue: 36 / 255.0, alpha: 0.08)
    })
}

// MARK: - Main Jump Destination View

public struct JumpDestinationView: View {
    // MARK: Lifecycle

    public init(
        quran: Quran,
        initialPage: Page? = nil,
        initialAyah: AyahNumber? = nil,
        onJump: @escaping (Page, AyahNumber) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.quran = quran
        self.onJump = onJump
        self.onDismiss = onDismiss

        let startPageNum = initialAyah?.page.pageNumber ?? initialPage?.pageNumber ?? 1
        let clampedPageNum = min(max(1, startPageNum), quran.pages.count)
        let resolvedPage = Page(quran: quran, pageNumber: clampedPageNum) ?? quran.pages.first!

        let startSura = initialAyah?.sura ?? resolvedPage.startSura
        let startAyah = initialAyah?.ayah ?? resolvedPage.firstVerse.ayah

        _pageNumber = State(initialValue: clampedPageNum)
        _pageInputText = State(initialValue: "\(clampedPageNum)")
        _selectedSura = State(initialValue: startSura)
        _selectedAyah = State(initialValue: startAyah)
        _ayahInputText = State(initialValue: "\(startAyah)")
    }

    // MARK: Public

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Page Number Section
                    pageNumberSection

                    // Subtle OR Separator
                    orSeparator

                    // Surah & Ayah Section
                    surahAndAyahSection

                    // Live Target Preview Card
                    previewCard

                    Spacer(minLength: 16)

                    // Luxury "Go / ಹೋಗಿ" Button
                    goButton
                }
                .padding(.top, 12)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrowshape.turn.up.right.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(JumpTheme.accent)
                        Text(l("jump.title"))
                            .font(.system(size: 17, weight: .bold))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(l("button.done")) {
                        focusedField = nil
                    }
                    .font(.body.weight(.semibold))
                }
            }
            .onChange(of: focusedField) { newFocus in
                if newFocus == nil {
                    if parseDigits(ayahInputText) == nil {
                        ayahInputText = "\(selectedAyah)"
                    }
                    if parseDigits(pageInputText) == nil {
                        pageInputText = "\(pageNumber)"
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingSurahPicker) {
            SurahPickerSheet(
                quran: quran,
                selectedSura: $selectedSura,
                onSelect: { newSura in
                    onSuraSelected(newSura)
                }
            )
        }
    }

    // MARK: Internal

    let quran: Quran
    let onJump: (Page, AyahNumber) -> Void
    let onDismiss: () -> Void

    // MARK: Private

    private enum FocusedField: Hashable {
        case page
        case ayah
    }

    @State private var pageNumber: Int
    @State private var pageInputText: String
    @State private var selectedSura: Sura
    @State private var selectedAyah: Int
    @State private var ayahInputText: String

    @State private var showingSurahPicker = false
    @FocusState private var focusedField: FocusedField?

    // MARK: - Sections

    private var pageNumberSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(l("jump.page_number"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text("1 – \(quran.pages.count)")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                // Stepper Minus
                Button {
                    stepPage(delta: -1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(pageNumber <= 1)

                // Numeric Input Field
                TextField("", text: $pageInputText)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .page)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .frame(height: 48)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focusedField == .page ? JumpTheme.accent : JumpTheme.cardBorder, lineWidth: focusedField == .page ? 2 : 1)
                    )
                    .onChange(of: pageInputText) { newValue in
                        handlePageTextChange(newValue)
                    }

                // Stepper Plus
                Button {
                    stepPage(delta: 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(pageNumber >= quran.pages.count)
            }
        }
        .padding(16)
        .background(JumpTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(JumpTheme.cardBorder, lineWidth: 1)
        )
    }

    private var orSeparator: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)

            Text(l("jump.or"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.vertical, 2)
    }

    private var surahAndAyahSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(l("jump.surah_and_ayah"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            // Surah Chooser Row with Prev / Next Steppers
            HStack(spacing: 10) {
                // Surah Minus
                Button {
                    stepSura(delta: -1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 38, height: 48)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(selectedSura.suraNumber <= 1)

                // Surah Chooser Button (Opens Picker)
                Button {
                    focusedField = nil
                    showingSurahPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Text("\(selectedSura.suraNumber)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(JumpTheme.accent)
                            .frame(width: 28, height: 28)
                            .background(JumpTheme.badgeBackground)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedSura.localizedName(withNumber: true))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text(selectedSura.arabicSuraName)
                                .font(.custom(.suraNames, size: 20))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 48)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(JumpTheme.cardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Surah Plus
                Button {
                    stepSura(delta: 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 38, height: 48)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(selectedSura.suraNumber >= quran.suras.count)
            }

            // Ayah Chooser Row
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(l("ayah"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text("1 – \(selectedSura.verses.count)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.8))
                }

                Spacer()

                // Ayah Minus
                Button {
                    stepAyah(delta: -1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 38, height: 42)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(selectedSura.suraNumber == 1 && selectedAyah == 1)

                // Ayah Numeric Input Field
                TextField("", text: $ayahInputText)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .ayah)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(width: 74, height: 42)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(focusedField == .ayah ? JumpTheme.accent : JumpTheme.cardBorder, lineWidth: focusedField == .ayah ? 2 : 1)
                    )
                    .onChange(of: ayahInputText) { newValue in
                        handleAyahTextChange(newValue)
                    }

                // Ayah Plus
                Button {
                    stepAyah(delta: 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 38, height: 42)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(selectedSura.suraNumber == quran.suras.count && selectedAyah == selectedSura.verses.count)
            }
        }
        .padding(16)
        .background(JumpTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(JumpTheme.cardBorder, lineWidth: 1)
        )
    }

    private var previewCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.north.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(JumpTheme.accent)

            VStack(alignment: .leading, spacing: 3) {
                Text(l("jump.preview"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(JumpTheme.accent)
                    .textCase(.uppercase)

                Text("\(lAndroid("quran_page")) \(NumberFormatter.shared.format(pageNumber)) • \(lAndroid("quran_juz2")) \(NumberFormatter.shared.format(currentJuzNumber))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text("\(selectedSura.localizedName()) : \(NumberFormatter.shared.format(selectedAyah))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(JumpTheme.badgeBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(JumpTheme.accent.opacity(0.25), lineWidth: 1)
        )
    }

    private var goButton: some View {
        Button {
            executeJump()
        } label: {
            HStack(spacing: 8) {
                Text(l("jump.go"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [JumpTheme.deepGreenTop, JumpTheme.deepGreenBase],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(14)
            .shadow(color: JumpTheme.deepGreenBase.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logic & Sync

    private var currentJuzNumber: Int {
        let targetPage = Page(quran: quran, pageNumber: pageNumber) ?? quran.pages.first!
        return targetPage.startJuz.juzNumber
    }

    private func parseDigits(_ string: String) -> Int? {
        let digits = string.compactMap { char -> Character? in
            if let scalar = char.unicodeScalars.first,
               scalar.properties.numericType == .decimal,
               let val = scalar.properties.numericValue {
                return Character("\(Int(val))")
            }
            return nil
        }
        return Int(String(digits))
    }

    private func stepPage(delta: Int) {
        focusedField = nil
        let newPage = min(max(1, pageNumber + delta), quran.pages.count)
        guard newPage != pageNumber else { return }
        pageNumber = newPage
        pageInputText = "\(newPage)"
        syncFromPageNumber(newPage)
    }

    private func stepSura(delta: Int) {
        focusedField = nil
        let newSuraNum = min(max(1, selectedSura.suraNumber + delta), quran.suras.count)
        guard newSuraNum != selectedSura.suraNumber else { return }
        let newSura = quran.suras[newSuraNum - 1]
        onSuraSelected(newSura)
    }

    private func stepAyah(delta: Int) {
        focusedField = nil
        if delta < 0 {
            if selectedAyah > 1 {
                let newAyah = selectedAyah - 1
                selectedAyah = newAyah
                ayahInputText = "\(newAyah)"
                syncFromAyah(newAyah)
            } else if selectedSura.suraNumber > 1 {
                let prevSura = quran.suras[selectedSura.suraNumber - 2]
                selectedSura = prevSura
                let lastAyah = prevSura.verses.count
                selectedAyah = lastAyah
                ayahInputText = "\(lastAyah)"
                syncFromAyah(lastAyah)
            }
        } else if delta > 0 {
            if selectedAyah < selectedSura.verses.count {
                let newAyah = selectedAyah + 1
                selectedAyah = newAyah
                ayahInputText = "\(newAyah)"
                syncFromAyah(newAyah)
            } else if selectedSura.suraNumber < quran.suras.count {
                let nextSura = quran.suras[selectedSura.suraNumber]
                selectedSura = nextSura
                selectedAyah = 1
                ayahInputText = "1"
                syncFromAyah(1)
            }
        }
    }

    private func handlePageTextChange(_ text: String) {
        guard focusedField == .page else { return }
        guard let num = parseDigits(text), num > 0 else { return }
        let clamped = min(max(1, num), quran.pages.count)
        pageNumber = clamped
        syncFromPageNumber(clamped)
    }

    private func handleAyahTextChange(_ text: String) {
        guard focusedField == .ayah else { return }
        guard let num = parseDigits(text), num > 0 else { return }
        let clamped = min(max(1, num), selectedSura.verses.count)
        selectedAyah = clamped
        syncFromAyah(clamped)
    }

    private func onSuraSelected(_ newSura: Sura) {
        selectedSura = newSura
        let clampedAyah = min(max(1, selectedAyah), newSura.verses.count)
        selectedAyah = clampedAyah
        ayahInputText = "\(clampedAyah)"
        syncFromAyah(clampedAyah)
    }

    private func syncFromPageNumber(_ pageNum: Int) {
        if let targetPage = Page(quran: quran, pageNumber: pageNum) {
            selectedSura = targetPage.startSura
            selectedAyah = targetPage.firstVerse.ayah
            ayahInputText = "\(selectedAyah)"
        }
    }

    private func syncFromAyah(_ ayahNum: Int) {
        if let ayah = AyahNumber(sura: selectedSura, ayah: ayahNum) {
            pageNumber = ayah.page.pageNumber
            pageInputText = "\(pageNumber)"
        }
    }

    private func executeJump() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        let resolvedPage = Page(quran: quran, pageNumber: pageNumber) ?? quran.pages.first!
        let resolvedAyah = AyahNumber(sura: selectedSura, ayah: selectedAyah) ?? resolvedPage.firstVerse

        onDismiss()
        onJump(resolvedPage, resolvedAyah)
    }
}

// MARK: - Surah Picker Sheet

private struct SurahPickerSheet: View {
    let quran: Quran
    @Binding var selectedSura: Sura
    let onSelect: (Sura) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredSuras: [Sura] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return quran.suras
        }
        let clean = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return quran.suras.filter { sura in
            if "\(sura.suraNumber)".contains(clean) { return true }
            if sura.localizedName().lowercased().contains(clean) { return true }
            if sura.arabicSuraName.contains(clean) { return true }
            return false
        }
    }

    var body: some View {
        NavigationView {
            List(filteredSuras) { sura in
                Button {
                    let feedback = UISelectionFeedbackGenerator()
                    feedback.selectionChanged()
                    onSelect(sura)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text("\(sura.suraNumber)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(sura == selectedSura ? JumpTheme.accent : .secondary)
                            .frame(width: 32, height: 32)
                            .background(
                                sura == selectedSura ? JumpTheme.badgeBackground : Color(UIColor.tertiarySystemFill)
                            )
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(sura.localizedName(withNumber: true))
                                .font(.system(size: 16, weight: sura == selectedSura ? .bold : .medium))
                                .foregroundColor(.primary)

                            Text("\(sura.verses.count) \(l("ayah")) • \(lAndroid("quran_page")) \(NumberFormatter.shared.format(sura.page.pageNumber))")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(sura.arabicSuraName)
                            .font(.custom(.suraNames, size: 22))
                            .foregroundColor(.secondary)

                        if sura == selectedSura {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(JumpTheme.accent)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: l("jump.search_surahs"))
            .navigationTitle(l("jump.select_surah"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(l("button.done")) {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Controller Wrapper

public final class JumpDestinationViewController: UIHostingController<JumpDestinationView> {
    public init(
        quran: Quran,
        initialPage: Page? = nil,
        initialAyah: AyahNumber? = nil,
        onJump: @escaping (Page, AyahNumber) -> Void
    ) {
        var dismissHandler: (() -> Void)?
        let rootView = JumpDestinationView(
            quran: quran,
            initialPage: initialPage,
            initialAyah: initialAyah,
            onJump: onJump,
            onDismiss: {
                dismissHandler?()
            }
        )
        super.init(rootView: rootView)

        dismissHandler = { [weak self] in
            self?.dismiss(animated: true)
        }

        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            if #available(iOS 16.0, *) {
                sheet.detents = [.custom(resolver: { _ in 580 }), .large()]
            } else {
                sheet.detents = [.medium(), .large()]
            }
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
    }

    @available(*, unavailable)
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
