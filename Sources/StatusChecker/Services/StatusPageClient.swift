import Foundation

enum StatusPageError: LocalizedError {
    case httpError(Int)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .httpError(let code): return "HTTP error \(code)"
        case .networkError(let error): return error.localizedDescription
        case .decodingError(let error): return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

struct StatusPageClient {
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func fetchSummary(for service: MonitoredService) async throws -> StatusPageSummary {
        let request = URLRequest(url: service.summaryURL, cachePolicy: .reloadIgnoringLocalCacheData)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw StatusPageError.networkError(error)
        }

        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw StatusPageError.httpError(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(StatusPageSummary.self, from: data)
        } catch {
            throw StatusPageError.decodingError(error)
        }
    }
}
