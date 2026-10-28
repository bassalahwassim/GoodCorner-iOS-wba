import Foundation

enum AppConfig {
    static let baseURL = URL(string: "http://127.0.0.1:8081")!

    /// Transforme un chemin relatif serveur ("/images/...") en URL complète.
    static func absoluteURL(for path: String?, baseURL: URL = AppConfig.baseURL) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if let url = URL(string: path), url.scheme != nil { return url }
        return URL(string: path, relativeTo: baseURL)?.absoluteURL
    }
}
