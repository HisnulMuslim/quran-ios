//
//  SplashViewController.swift
//  AppStructureFeature
//
//  Created by Mohamed Afifi on 2026-06-27.
//

import UIKit

public final class SplashViewController: UIViewController {
    // MARK: Public

    override public func viewDidLoad() {
        super.viewDidLoad()
        let splashBackgroundColor = UIColor(red: 246 / 255.0, green: 246 / 255.0, blue: 244 / 255.0, alpha: 1.0)
        view.backgroundColor = splashBackgroundColor

        let imageView = UIImageView()
        if let image = UIImage(named: "SplashScreen") {
            imageView.image = image
        } else {
            imageView.backgroundColor = splashBackgroundColor
        }
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}
