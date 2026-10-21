//
//  AyahMenuUI.swift
//
//
//  Created by Afifi, Mohamed on 7/25/21.
//

import Combine
import QuranAnnotations
import SwiftUI
import UIx

public enum AyahMenuUI {
    public struct Actions {
        // MARK: Lifecycle

        public init(
            play: @escaping AsyncAction,
            repeatVerses: @escaping AsyncAction,
            highlight: @Sendable @escaping (Note.Color) async -> Void,
            addNote: @escaping AsyncAction,
            deleteNote: @escaping AsyncAction,
            showTranslation: @escaping AsyncAction,
            copy: @escaping AsyncAction,
            share: @escaping AsyncAction,
            expandSelection: (() -> Void)? = nil,
            shrinkSelection: (() -> Void)? = nil
        ) {
            self.play = play
            self.repeatVerses = repeatVerses
            self.highlight = highlight
            self.addNote = addNote
            self.deleteNote = deleteNote
            self.showTranslation = showTranslation
            self.copy = copy
            self.share = share
            self.expandSelection = expandSelection
            self.shrinkSelection = shrinkSelection
        }

        // MARK: Internal

        let play: AsyncAction
        let repeatVerses: AsyncAction
        let highlight: @Sendable (Note.Color) async -> Void
        let addNote: AsyncAction
        let deleteNote: AsyncAction
        let showTranslation: AsyncAction
        let copy: AsyncAction
        let share: AsyncAction
        let expandSelection: (() -> Void)?
        let shrinkSelection: (() -> Void)?
    }

    @MainActor
    public final class DataObject: ObservableObject {
        // MARK: Lifecycle

        public init(
            title: String,
            subtitle: String? = nil,
            canExpand: Bool = true,
            canShrink: Bool = false,
            highlightingColor: Note.Color,
            state: NoteState,
            playSubtitle: String,
            repeatSubtitle: String,
            actions: Actions,
            isTranslationView: Bool
        ) {
            self.title = title
            self.subtitle = subtitle
            self.canExpand = canExpand
            self.canShrink = canShrink
            self.highlightingColor = highlightingColor
            self.state = state
            self.playSubtitle = playSubtitle
            self.repeatSubtitle = repeatSubtitle
            self.actions = actions
            self.isTranslationView = isTranslationView
        }

        // MARK: Internal

        @Published public var title: String
        @Published public var subtitle: String?
        @Published public var canExpand: Bool
        @Published public var canShrink: Bool
        @Published public var highlightingColor: Note.Color
        @Published public var state: NoteState
        @Published public var playSubtitle: String
        @Published public var repeatSubtitle: String
        public let isTranslationView: Bool
        public let actions: Actions
    }

    // MARK: Public

    public enum NoteState {
        case noHighlight
        case highlighted
        case noted
    }
}

