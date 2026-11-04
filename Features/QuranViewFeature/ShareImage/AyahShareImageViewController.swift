//
//  AyahShareImageViewController.swift
//  Quran
//
//  Created for Kannada Quran App.
//

import QuranKit
import SwiftUI
import UIKit

public final class AyahShareImageViewController: UIHostingController<AyahShareImageView> {
    public init(
        verses: [AyahNumber],
        databasesURL: URL,
        quranFileURL: URL,
        onDismiss: (() -> Void)? = nil
    ) {
        let viewModel = AyahShareImageViewModel(
            verses: verses,
            databasesURL: databasesURL,
            quranFileURL: quranFileURL
        )

        var dismissHandler: (() -> Void)?
        let rootView = AyahShareImageView(
            viewModel: viewModel,
            onDismiss: {
                dismissHandler?()
            }
        )
        super.init(rootView: rootView)

        dismissHandler = { [weak self] in
            self?.dismiss(animated: true) {
                onDismiss?()
            }
        }
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
    }
}
