//
//  AyahMenuBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/11/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AppDependencies
import QuranAnnotations
import QuranKit
import QuranTextKit
import UIKit

public struct AyahMenuInput {
    // MARK: Lifecycle

    public init(
        sourceView: UIView,
        pointInView: CGPoint,
        verses: [AyahNumber],
        notes: [Note],
        visiblePages: [Page] = []
    ) {
        self.sourceView = sourceView
        self.pointInView = pointInView
        self.verses = verses
        self.notes = notes
        self.visiblePages = visiblePages
    }

    // MARK: Internal

    let sourceView: UIView
    let pointInView: CGPoint
    let verses: [AyahNumber]
    let notes: [Note]
    let visiblePages: [Page]
}

@MainActor
public struct AyahMenuBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(withListener listener: AyahMenuListener, input: AyahMenuInput) -> UIViewController {
        let textRetriever = ShareableVerseTextRetriever(
            databasesURL: container.databasesURL,
            quranFileURL: container.quranUthmaniV2Database
        )
        let noteService = container.noteService()
        let viewModel = AyahMenuViewModel(deps: AyahMenuViewModel.Deps(
            sourceView: input.sourceView,
            pointInView: input.pointInView,
            verses: input.verses,
            notes: input.notes,
            visiblePages: input.visiblePages,
            noteService: noteService,
            textRetriever: textRetriever
        ))
        viewModel.listener = listener
        return AyahMenuViewController(viewModel: viewModel)
    }

    // MARK: Private

    private let container: AppDependencies
}
