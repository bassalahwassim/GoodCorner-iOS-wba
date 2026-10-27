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

struct MockListingsService: ListingsService {
    var listingsResult: Result<[Listing], Error> = .success([])
    var categoriesResult: Result<[ListingCategory], Error> = .success([])

    func fetchListings() async throws -> [Listing] { try listingsResult.get() }
    func fetchCategories() async throws -> [ListingCategory] { try categoriesResult.get() }
}
