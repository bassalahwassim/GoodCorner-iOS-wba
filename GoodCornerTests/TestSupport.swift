import Foundation
@testable import GoodCorner

extension Listing {
    static func stub(id: Int, categoryID: Int = 1, isUrgent: Bool = false) -> Listing {
        Listing(
            id: id,
            title: "Item \(id)",
            description: "",
            price: 10,
            categoryID: categoryID,
            creationDate: Date(timeIntervalSince1970: 0),
            isUrgent: isUrgent,
            imagesURL: nil
        )
    }
}

/// Service factice : résultats fixes OU comportement dynamique via `listingsHandler`.
final class MockListingsService: ListingsService {
    var listingsResult: Result<[Listing], Error>
    var categoriesResult: Result<[ListingCategory], Error>
    var listingsHandler: ((String?) async throws -> [Listing])?

    private let lock = NSLock()
    private var recordedQueries: [String?] = []

    init(
        listingsResult: Result<[Listing], Error> = .success([]),
        categoriesResult: Result<[ListingCategory], Error> = .success([])
    ) {
        self.listingsResult = listingsResult
        self.categoriesResult = categoriesResult
    }

    /// Termes reçus, dans l'ordre (nil = sans filtre).
    var queries: [String?] {
        lock.lock()
        defer { lock.unlock() }
        return recordedQueries
    }

    func fetchListings(query: String?) async throws -> [Listing] {
        lock.lock()
        recordedQueries.append(query)
        lock.unlock()
        if let listingsHandler {
            return try await listingsHandler(query)
        }
        return try listingsResult.get()
    }

    func fetchCategories() async throws -> [ListingCategory] {
        try categoriesResult.get()
    }
}
