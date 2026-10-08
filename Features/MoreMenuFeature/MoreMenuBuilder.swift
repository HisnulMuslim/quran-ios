//
//  MoreMenuBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/1/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import UIKit

@MainActor
public struct MoreMenuBuilder {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func build(withListener listener: MoreMenuListener, model: MoreMenuModel) -> UIViewController {
        let viewModel = MoreMenuViewModel(model: model)
        let viewController = MoreMenuController(viewModel: viewModel)
        viewModel.listener = listener
        return viewController
    }

    public func buildThemeSettings(showFontSize: Bool = true) -> UIViewController {
        ThemeSettingsHostingController(showFontSize: showFontSize)
    }
}
