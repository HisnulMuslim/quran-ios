//
//  HomeTab.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AppDependencies
import HomeFeature
import Localization
import QuranKit
import QuranText
import QuranTextKit
import QuranViewFeature
import ReadingService
import UIKit

struct HomeTabBuilder: TabBuildable {
    let container: AppDependencies

    func build() -> UIViewController {
        let interactor = HomeTabInteractor(
            quranBuilder: QuranBuilder(container: container),
            homeBuilder: HomeBuilder(container: container)
        )
        let viewController = HomeTabViewController(interactor: interactor)
        viewController.navigationBar.prefersLargeTitles = true
        return viewController
    }
}

private final class HomeTabInteractor: TabInteractor {
    // MARK: Lifecycle

    init(quranBuilder: QuranBuilder, homeBuilder: HomeBuilder) {
        self.homeBuilder = homeBuilder
        super.init(quranBuilder: quranBuilder)
    }

    // MARK: Internal

    override func start() {
        let rootViewController = homeBuilder.build(withListener: self)
        presenter?.setViewControllers([rootViewController], animated: false)

        #if DEBUG
        if let pageStr = ProcessInfo.processInfo.environment["OPEN_PAGE"],
           let pageNum = Int(pageStr) {
            if let arabicStr = ProcessInfo.processInfo.environment["SET_ARABIC_FONT"],
               let rawVal = Int(arabicStr),
               let size = FontSize(rawValue: rawVal) {
                var prefs = FontSizePreferences.shared
                prefs.arabicFontSize = size
            }
            if let transStr = ProcessInfo.processInfo.environment["SET_TRANS_FONT"],
               let rawVal = Int(transStr),
               let size = FontSize(rawValue: rawVal) {
                var prefs = FontSizePreferences.shared
                prefs.translationFontSize = size
            }
            if let modeStr = ProcessInfo.processInfo.environment["SET_VIEW_MODE"],
               let rawMode = Int(modeStr),
               let mode = TranslationViewMode(rawValue: rawMode) {
                var statePrefs = QuranContentStatePreferences.shared
                statePrefs.translationViewMode = mode
            }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let quran = ReadingPreferences.shared.reading.quran
                if let targetPage = Page(quran: quran, pageNumber: pageNum) {
                    self.navigateTo(page: targetPage, lastPage: nil, highlightingSearchAyah: nil)
                }
            }
        }
        #endif
    }

    // MARK: Private

    private let homeBuilder: HomeBuilder
}

private final class HomeTabViewController: TabViewController {
    override func getTabBarItem() -> UITabBarItem {
        UITabBarItem(
            title: "\(lAndroid("quran_sura")) / \(lAndroid("quran_juz2"))",
            image: .symbol("doc.text"),
            selectedImage: .symbol("doc.text.fill")
        )
    }
}
