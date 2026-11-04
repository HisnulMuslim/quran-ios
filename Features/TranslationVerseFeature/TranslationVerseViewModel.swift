//
//  TranslationVerseViewModel.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-09.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import AnnotationsService
import Combine
import QuranKit
import QuranText
import QuranTextKit
import QuranTranslationFeature
import TranslationService
import VLogging

public struct TranslationVerseActions {
    // MARK: Lifecycle

    public init(updateCurrentVerseTo: @escaping (AyahNumber) -> Void) {
        self.updateCurrentVerseTo = updateCurrentVerseTo
    }

    // MARK: Internal

    let updateCurrentVerseTo: (AyahNumber) -> Void
}

@MainActor
class TranslationVerseViewModel: ObservableObject {
    // MARK: Lifecycle

    init(startingVerse: AyahNumber, localTranslationsRetriever: LocalTranslationsRetriever, dataService: QuranTextDataService, actions: TranslationVerseActions) {
        currentVerse = startingVerse
        self.dataService = dataService
        self.localTranslationsRetriever = localTranslationsRetriever
        self.actions = actions

        let noOpHighlightingService = QuranHighlightsService()
        let vm = ContentTranslationViewModel(localTranslationsRetriever: localTranslationsRetriever, dataService: dataService, highlightsService: noOpHighlightingService)
        vm.showHeaderAndFooter = false
        vm.verses = [startingVerse]
        vm.translationViewMode = .both
        vm.loadAllDownloadedTranslations = true
        self.translationViewModel = vm

        Task { [weak self] in
            await self?.loadAvailableTranslations()
        }
    }

    // MARK: Internal

    let translationViewModel: ContentTranslationViewModel
    @Published var availableTranslations: [Translation] = []
    @Published var selectedFilterId: Int = -1 // -1 means "All (Side-by-Side)"

    @Published var currentVerse: AyahNumber {
        didSet {
            translationViewModel.verses = [currentVerse]
            actions.updateCurrentVerseTo(currentVerse)
        }
    }

    func selectFilter(_ id: Int) {
        selectedFilterId = id
        if id == -1 {
            translationViewModel.customTranslationIds = nil
        } else {
            translationViewModel.customTranslationIds = [id]
        }
    }

    func loadAvailableTranslations() async {
        if let locals = try? await localTranslationsRetriever.getLocalTranslations() {
            availableTranslations = locals.filter(\.isDownloaded)
        }
    }

    func next() {
        logger.info("Verse Translation: moving to next verse currentVerse:\(currentVerse)")
        if let next = currentVerse.next {
            currentVerse = next
        }
    }

    func previous() {
        logger.info("Verse Translation: moving to previous verse currentVerse:\(currentVerse)")
        if let previous = currentVerse.previous {
            currentVerse = previous
        }
    }

    // MARK: Private

    private let localTranslationsRetriever: LocalTranslationsRetriever
    private let dataService: QuranTextDataService
    private let actions: TranslationVerseActions
}
