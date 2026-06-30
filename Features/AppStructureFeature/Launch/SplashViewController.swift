//
//  SplashViewController.swift
//  AppStructureFeature
//
//  Created by Mohamed Afifi on 2026-06-27.
//

import UIKit

public final class SplashViewController: UIViewController {
    // MARK: Public

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let imageView = UIImageView()
        if let image = UIImage(named: "SplashScreen") {
            imageView.image = image
        } else {
            imageView.backgroundColor = .black
        }
        imageView.contentMode = .scaleAspectFill
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
