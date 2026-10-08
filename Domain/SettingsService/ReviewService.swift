//
//  ReviewService.swift
//  Quran
//
//  Created by Muhammad Umer on 4/11/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Analytics
import Foundation
import StoreKit
import Utilities

@MainActor
public struct ReviewService {
    // MARK: Lifecycle

    public init(analytics: AnalyticsLibrary) {
        self.analytics = analytics
    }

    // MARK: Public

    public func checkForReview(in window: UIWindow) {
        var appOpenedCounter = persistence.appOpenedCounter

        if appOpenedCounter == 0 {
            persistence.appInstalledDate = Date()
        } else {
            let oldDate = persistence.requestReviewDate ?? persistence.appInstalledDate
            let today = Date()
            let difference = Calendar.current.dateComponents([.day], from: oldDate, to: today)

            if let daysCount = difference.day {
                let isFirstTimePrompt = persistence.requestReviewDate == nil && daysCount >= 7 && appOpenedCounter >= 10
                let isPeriodicPrompt = persistence.requestReviewDate != nil && daysCount >= 90

                if isFirstTimePrompt || isPeriodicPrompt {
                    requestReview(in: window)
                    persistence.requestReviewDate = Date()
                }
            }
        }

        appOpenedCounter += 1
        persistence.appOpenedCounter = appOpenedCounter
    }

    public func openAppReview() {
        let itmsURL = URL(validURL: "itms-apps://apps.apple.com/app/id6780201059?action=write-review")
        let webURL = URL(validURL: "https://apps.apple.com/app/id6780201059?action=write-review")
        if application.canOpenURL(itmsURL) {
            application.open(itmsURL)
        } else {
            application.open(webURL)
        }
        analytics.review(automatic: false)
    }

    public func openOtherApps() {
        Self.openDeveloperApps(application: application)
    }

    public static func openDeveloperApps(application: UIApplication = .shared) {
        let itmsURL = URL(validURL: "itms-apps://apps.apple.com/developer/id1544699161")
        let webURL = URL(validURL: "https://apps.apple.com/developer/id1544699161")
        if application.canOpenURL(itmsURL) {
            application.open(itmsURL)
        } else {
            application.open(webURL)
        }
    }

    // MARK: Internal

    let analytics: AnalyticsLibrary
    let persistence = ReviewPersistence.shared
    let application: UIApplication = .shared

    public static func requestReviewNow() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        guard let windowScene = activeScene else {
            print("ReviewService: No window scene found for review")
            return
        }
        if #available(iOS 16.0, *) {
            AppStore.requestReview(in: windowScene)
        } else {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func requestReview(in window: UIWindow) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            Self.requestReviewNow()
            self.analytics.review(automatic: true)
        }
    }
}

private extension AnalyticsLibrary {
    func review(automatic: Bool) {
        logEvent("RequestReviewAutomatic", value: automatic.description)
    }
}
