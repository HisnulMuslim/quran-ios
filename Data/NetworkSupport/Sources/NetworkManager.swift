//
//  NetworkManager.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import Foundation

public final class NetworkManager {
    // MARK: Lifecycle

    public init(session: NetworkSession = URLSession.shared, baseURL: URL) {
        self.session = session
        self.baseURL = baseURL
    }

    // MARK: Public

    public func request(_ path: String, parameters: [(String, String)] = []) async throws -> Data {
        do {
            let request: URLRequest = Self.request(baseURL: baseURL, path: path, parameters: parameters)
            let (data, _) = try await session.data(for: request)
            return data
        } catch {
            throw NetworkError(error: error)
        }
    }

    // MARK: Internal

    static func request(baseURL: URL, path: String, parameters: [(String, String)] = []) -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
        var request = URLRequest(url: components.url!)
        request.setValue("https://www.hisnulmuslimdua.com/", forHTTPHeaderField: "Referer")
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
            forHTTPHeaderField: "User-Agent"
        )
        return request
    }

    // MARK: Private

    private let session: NetworkSession
    private let baseURL: URL
}
