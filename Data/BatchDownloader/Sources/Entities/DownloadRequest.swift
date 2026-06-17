//
//  DownloadRequest.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/11/17.
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

import Foundation
import NetworkSupport
import Utilities

public struct DownloadRequest: Hashable, Sendable {
    // MARK: Lifecycle

    public init(url: URL, destination: RelativeFilePath) {
        self.url = url
        self.destination = destination
    }

    // MARK: Public

    public let url: URL
    public let destination: RelativeFilePath

    public var resumePath: RelativeFilePath { destination.appendingPathExtension(Self.downloadResumeDataExtension) }

    public var request: URLRequest {
        var request = URLRequest(url: url)
        request.setValue("https://www.hisnulmuslimdua.com/", forHTTPHeaderField: "Referer")
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
            forHTTPHeaderField: "User-Agent"
        )
        return request
    }

    // MARK: Private

    private static let downloadResumeDataExtension = "resume"
}

public struct DownloadBatchRequest: Hashable, Sendable {
    // MARK: Lifecycle

    public init(requests: [DownloadRequest]) {
        self.requests = requests
    }

    // MARK: Public

    public let requests: [DownloadRequest]
}

extension NetworkSession {
    func downloadTask(with request: DownloadRequest) -> NetworkSessionDownloadTask {
        if let data = try? Data(contentsOf: request.resumePath) {
            return downloadTask(withResumeData: data)
        } else {
            return downloadTask(with: request.request)  // Uses Referer-injected URLRequest
        }
    }
}
