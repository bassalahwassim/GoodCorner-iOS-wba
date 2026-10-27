import Foundation

protocol ListingsService {
    func fetchListings() async throws -> [Listing]
    func fetchCategories() async throws -> [ListingCategory]
}

extension JSONDecoder {
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

struct APIClient: ListingsService {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL = AppConfig.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func makeRequest(path: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    func fetchListings() async throws -> [Listing] {
        // Sans paramètres : le serveur renvoie la même enveloppe (items, total, ...).
        // Attention : page et limit doivent être fournis ensemble.
        let response: ListingsResponse = try await get("listings")
        return response.items
    }

    func fetchCategories() async throws -> [ListingCategory] {
        try await get("categories")
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let request = makeRequest(path: path)
        let result: (Data, URLResponse)
        do {
            result = try await session.data(for: request)
        } catch {
            throw APIError.network
        }
        let (data, response) = result
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.server(http.statusCode) }
        do {
            return try JSONDecoder.api.decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
