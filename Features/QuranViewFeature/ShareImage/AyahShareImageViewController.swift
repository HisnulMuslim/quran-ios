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
        appHost: URL = URL(string: "https://quran-files.hisnulmuslimdua.com/")!,
        isVideoMode: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) {
        let viewModel = AyahShareImageViewModel(
            verses: verses,
            databasesURL: databasesURL,
            quranFileURL: quranFileURL,
            appHost: appHost,
            isVideoMode: isVideoMode
        )

        var dismissHandler: (() -> Void)?
        let rootView = AyahShareImageView(
            viewModel: viewModel,
            onDismiss: {
                dismissHandler?()
            }
        )
        super.init(rootView: rootView)

        modalPresentationStyle = .pageSheet
        preferredContentSize = CGSize(width: 920, height: 760)

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
