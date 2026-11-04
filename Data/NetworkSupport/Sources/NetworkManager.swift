//
//  NetworkManager.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import Foundation

public final class NetworkManager {
    // MARK: Lifecycle

    public init(session: NetworkSession = URLSession.shared, baseURL: URL, fallbackBaseURL: URL? = nil) {
        self.session = session
        self.baseURL = baseURL
        self.fallbackBaseURL = fallbackBaseURL
    }

    // MARK: Public

    public func request(_ path: String, parameters: [(String, String)] = []) async throws -> Data {
        do {
            return try await performRequest(baseURL: baseURL, path: path, parameters: parameters)
        } catch {
            if let fallbackBaseURL {
                do {
                    return try await performRequest(baseURL: fallbackBaseURL, path: path, parameters: parameters)
                } catch {
                    throw NetworkError(error: error)
                }
            }
            throw NetworkError(error: error)
        }
    }

    // MARK: Internal

    static func request(baseURL: URL, path: String, parameters: [(String, String)] = []) -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if !parameters.isEmpty {
            components.queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
        }
        var request = URLRequest(url: components.url!)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("https://www.hisnulmuslimdua.com/", forHTTPHeaderField: "Referer")
        request.setValue("KannadaQuran/1.1.3 (iOS)", forHTTPHeaderField: "User-Agent")
        return request
    }

    // MARK: Private

    private let session: NetworkSession
    private let baseURL: URL
    private let fallbackBaseURL: URL?

    private func performRequest(baseURL: URL, path: String, parameters: [(String, String)]) async throws -> Data {
        let request: URLRequest = Self.request(baseURL: baseURL, path: path, parameters: parameters)
        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw NetworkError.serverError("HTTP \(httpResponse.statusCode)")
        }
        return data
    }
}
