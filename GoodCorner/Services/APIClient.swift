import Foundation

protocol ListingsService {
    /// `query` : terme de recherche (nil ou vide = toutes les annonces).
    func fetchListings(query: String?) async throws -> [Listing]
    func fetchCategories() async throws -> [ListingCategory]
}

extension ListingsService {
    func fetchListings() async throws -> [Listing] {
        try await fetchListings(query: nil)
    }
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

    func makeRequest(path: String, queryItems: [URLQueryItem] = []) -> URLRequest {
        var url = baseURL.appendingPathComponent(path)
        if !queryItems.isEmpty,
           var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.queryItems = queryItems
            // URLComponents laisse "+" tel quel, et beaucoup de serveurs le lisent comme un espace.
            components.percentEncodedQuery = components.percentEncodedQuery?
                .replacingOccurrences(of: "+", with: "%2B")
            url = components.url ?? url
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    func fetchListings(query: String?) async throws -> [Listing] {
		
		try await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes TODO  (remove)
	
        // Attention : si page/limit sont utilisés un jour, ils doivent être fournis ensemble.
        var items: [URLQueryItem] = []
        if let term = query?.trimmingCharacters(in: .whitespacesAndNewlines), !term.isEmpty {
            items.append(URLQueryItem(name: "query", value: term))
        }
        let response: ListingsResponse = try await get("listings", queryItems: items)
        return response.items
    }

    func fetchCategories() async throws -> [ListingCategory] {
        try await get("categories")
    }

    private func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let request = makeRequest(path: path, queryItems: queryItems)
        let result: (Data, URLResponse)
        do {
            result = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            // Requête annulée (nouvelle saisie) : ce n'est pas une erreur à afficher.
            throw CancellationError()
        } catch is CancellationError {
            throw CancellationError()
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
