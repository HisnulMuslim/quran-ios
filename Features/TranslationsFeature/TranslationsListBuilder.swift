//
//  TranslationsListBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AppDependencies
import TranslationService
import UIKit

@MainActor
public struct TranslationsListBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build() -> UIViewController {
        let repository = TranslationsRepository(databasesURL: container.databasesURL, baseURL: container.appHost)
        let localRetriever = LocalTranslationsRetriever(databasesURL: container.databasesURL)
        let downloader = TranslationsDownloader(downloader: container.downloadManager)
        let updater = TranslationsUpdater(
            translationsRepository: repository,
            localTranslationsRetriever: localRetriever,
            downloader: downloader
        )

        let viewModel = TranslationsListViewModel(
            analytics: container.analytics,
            translationsRepository: repository,
            localTranslationsRetriever: localRetriever,
            deleter: TranslationDeleter(databasesURL: container.databasesURL),
            downloader: downloader,
            translationsUpdater: updater
        )

        let viewController = TranslationsViewController(viewModel: viewModel)
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
