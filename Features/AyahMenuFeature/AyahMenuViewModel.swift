//
//  AyahMenuViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/11/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import Crashing
import Localization
import NoorUI
import QuranAnnotations
import QuranAudioKit
import QuranKit
import QuranTextKit
import ReadingService
import UIKit
import VLogging

@MainActor
public protocol AyahMenuListener: AnyObject {
    func dismissAyahMenu()

    func playAudio(_ from: AyahNumber, to: AyahNumber?, repeatVerses: Bool)

    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint)
    func deleteNotes(_ notes: [Note], verses: [AyahNumber]) async
    func showTranslation(_ verses: [AyahNumber])

    func editNote(_ note: Note)

    @discardableResult
    func updateAyahMenuSelectedVerses(_ verses: [AyahNumber]) -> [Note]
}

// MARK: - ViewModel

@MainActor
final class AyahMenuViewModel {
    struct Deps {
        let sourceView: UIView
        let pointInView: CGPoint
        let verses: [AyahNumber]
        let notes: [Note]
        let visiblePages: [Page]
        let noteService: NoteService
        let textRetriever: ShareableVerseTextRetriever
        let quranContentStatePreferences = QuranContentStatePreferences.shared
    }

    // MARK: Lifecycle

    init(deps: Deps) {
        self.deps = deps
        self.verses = deps.verses
        self.notes = deps.notes
    }

    // MARK: Internal

    weak var listener: AyahMenuListener?

    private(set) var verses: [AyahNumber]
    private(set) var notes: [Note]
    private(set) var dataObject: AyahMenuUI.DataObject?

    var isTranslationView: Bool {
        deps.quranContentStatePreferences.quranMode == .translation
    }

    var highlightingColor: Note.Color { deps.noteService.color(from: notes) }

    var selectionTitle: String {
        guard let first = verses.first else { return "" }
        if verses.count == 1 {
            return first.localizedName
        }
        guard let last = verses.last else { return "" }
        if first.sura == last.sura {
            let startNum = NumberFormatter.shared.format(first.ayah)
            let endNum = NumberFormatter.shared.format(last.ayah)
            return "\(first.sura.localizedName()), \(startNum)–\(endNum)"
        } else {
            let startNum = NumberFormatter.shared.format(first.ayah)
            let endNum = NumberFormatter.shared.format(last.ayah)
            return "\(first.sura.localizedName()) \(startNum) – \(last.sura.localizedName()) \(endNum)"
        }
    }

    var selectionSubtitle: String? {
        if verses.count == 1 {
            return l("ayah.menu.selected-verse")
        }
        return "\(NumberFormatter.shared.format(verses.count)) " + l("ayah.menu.selected-verses")
    }

    var canExpand: Bool {
        guard let last = verses.last, let next = last.next else {
            return false
        }
        if isTranslationView {
            return true
        }
        if deps.visiblePages.isEmpty {
            return true
        }
        return deps.visiblePages.contains(next.page)
    }

    var canShrink: Bool {
        true
    }

    var playSubtitle: String {
        if verses.count > 1 { // multiple verses selected
            return l("ayah.menu.selected-verses")
        }
        switch audioPreferences.audioEnd {
        case .juz: return l("ayah.menu.play-end-juz")
        case .sura: return l("ayah.menu.play-end-surah")
        case .page: return l("ayah.menu.play-end-page")
        case .quran: return l("ayah.menu.play-end-quran")
        }
    }

    var repeatSubtitle: String {
        if verses.count == 1 {
            return l("ayah.menu.selected-verse")
        }
        return l("ayah.menu.selected-verses")
    }

    var noteState: AyahMenuUI.NoteState {
        if notes.isEmpty {
            return .noHighlight
        } else if containsText(notes) {
            return .noted
        }
        return .highlighted
    }

    func makeDataObject(actions: AyahMenuUI.Actions) -> AyahMenuUI.DataObject {
        let object = AyahMenuUI.DataObject(
            title: selectionTitle,
            subtitle: selectionSubtitle,
            canExpand: canExpand,
            canShrink: canShrink,
            highlightingColor: highlightingColor,
            state: noteState,
            playSubtitle: playSubtitle,
            repeatSubtitle: repeatSubtitle,
            actions: actions,
            isTranslationView: isTranslationView
        )
        self.dataObject = object
        return object
    }

    func expandSelection() {
        guard let last = verses.last, let next = last.next else {
            return
        }
        if !isTranslationView && !deps.visiblePages.isEmpty && !deps.visiblePages.contains(next.page) {
            return
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        verses.append(next)
        if let newNotes = listener?.updateAyahMenuSelectedVerses(verses) {
            notes = newNotes
        }
        updateDataObject()
    }

    func shrinkSelection() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if verses.count > 1 {
            verses.removeLast()
            if let newNotes = listener?.updateAyahMenuSelectedVerses(verses) {
                notes = newNotes
            }
            updateDataObject()
        } else {
            listener?.dismissAyahMenu()
        }
    }

    private func updateDataObject() {
        guard let dataObject else { return }
        dataObject.title = selectionTitle
        dataObject.subtitle = selectionSubtitle
        dataObject.canExpand = canExpand
        dataObject.canShrink = canShrink
        dataObject.playSubtitle = playSubtitle
        dataObject.repeatSubtitle = repeatSubtitle
        dataObject.highlightingColor = highlightingColor
        dataObject.state = noteState
    }

    // MARK: - Items & Actions

    func play() {
        logger.info("AyahMenu: play tapped. Verses: \(verses)")
        listener?.dismissAyahMenu()

        let verses = self.verses
        let lastVerse = verses.count == 1 ? nil : verses.last
        listener?.playAudio(verses[0], to: lastVerse, repeatVerses: false)
    }

    func repeatVerses() {
        logger.info("AyahMenu: repeat verses tapped. Verses: \(verses)")
        listener?.dismissAyahMenu()

        let verses = self.verses
        listener?.playAudio(verses[0], to: verses.last, repeatVerses: true)
    }

    func deleteNotes() async {
        logger.info("AyahMenu: delete notes. Verses: \(verses)")
        if !containsText(notes) {
            listener?.dismissAyahMenu()
        }
        await listener?.deleteNotes(notes, verses: verses)
    }

    func editNote() async {
        logger.info("AyahMenu: edit notes. Verses: \(verses)")
        let notes = self.notes
        let color = deps.noteService.color(from: notes)
        if let note = await _updateHighlight(color: color) {
            listener?.editNote(note)
        }
    }

    func updateHighlight(color: Note.Color) async {
        logger.info("AyahMenu: update verse highlights. Verses: \(verses)")
        listener?.dismissAyahMenu()
        _ = await _updateHighlight(color: color)
    }

    func showTranslation() {
        logger.info("AyahMenu: showTranslation. Verses: \(verses)")
        listener?.showTranslation(verses)
    }

    func copy() {
        logger.info("AyahMenu: copy. Verses: \(verses)")
        listener?.dismissAyahMenu()
        Task {
            if let lines = try? await retrieveSelectedAyahText() {
                let pasteBoard = UIPasteboard.general
                pasteBoard.string = lines.joined(separator: "\n")
            }
        }
    }

    func share() {
        logger.info("AyahMenu: share. Verses: \(verses)")
        Task {
            if let lines = try? await retrieveSelectedAyahText() {
                let withNewLines = lines.joined(separator: "\n")
                listener?.shareText([withNewLines], in: self.deps.sourceView, at: self.deps.pointInView)
            }
        }
    }

    // MARK: Private

    private let audioPreferences = AudioPreferences.shared

    private let deps: Deps

    // MARK: - Helper

    private func containsText(_ notes: [Note]) -> Bool {
        notes.contains { note in
            !(note.note ?? "").isEmpty
        }
    }

    private func _updateHighlight(color: Note.Color) async -> Note? {
        let quran = ReadingPreferences.shared.reading.quran
        do {
            let updatedNote = try await deps.noteService.updateHighlight(
                verses: verses, color: color, quran: quran
            )
            logger.info("AyahMenu: notes updated")
            return updatedNote
        } catch {
            crasher.recordError(error, reason: "Failed to update highlights")
            return nil
        }
    }

    private func retrieveSelectedAyahText() async throws -> [String] {
        try await crasher.recordError("Failed to update highlights") {
            try await deps.textRetriever.textForVerses(verses)
        }
    }
}
