import Foundation
import NetworkSupport
import VLogging

struct AudioUpdatesNetworkManager {
    // MARK: Internal

    let networkManager: NetworkManager

    func getAudioUpdates(revision: Int) async throws -> AudioUpdates? {
        let path = "/data/api/audio_updates/audio_updates_v\(revision).json"
        do {
            let data = try await networkManager.request(path)
            return try parse(data: data)
        } catch is DecodingError {
            logger.info("AudioUpdatesNetworkManager: Failed to decode updates JSON (likely 404/no updates). Returning nil.")
            return nil
        } catch {
            throw error
        }
    }

    // MARK: Private

    private func parse(data: Data) throws -> AudioUpdates? {
        if data.isEmpty { // no updates
            return nil
        }

        var sanitizedData = data
        if let jsonString = String(data: data, encoding: .utf8) {
            // If the server concatenated multiple JSON objects (e.g. `}{`), take only the first object
            if let range = jsonString.range(of: "}{") {
                let firstObjectString = String(jsonString[..<range.lowerBound]) + "}"
                if let firstObjectData = firstObjectString.data(using: .utf8) {
                    sanitizedData = firstObjectData
                }
            }
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(AudioUpdates.self, from: sanitizedData)
    }
}
