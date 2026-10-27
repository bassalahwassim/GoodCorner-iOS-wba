import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidResponse
    case server(Int)
    case decoding
    case network

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return NSLocalizedString("error.invalid", comment: "")
        case .server(let code):
            return String(format: NSLocalizedString("error.server", comment: ""), code)
        case .decoding:
            return NSLocalizedString("error.decoding", comment: "")
        case .network:
            return NSLocalizedString("error.network", comment: "")
        }
    }
}
