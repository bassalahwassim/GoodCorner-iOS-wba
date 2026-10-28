import Foundation

struct Listing: Identifiable, Decodable, Equatable {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let categoryID: Int
    let creationDate: Date
    let isUrgent: Bool
    let imagesURL: ImagesURL?

    struct ImagesURL: Decodable, Equatable {
        let small: String?
        let thumb: String?
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, price
        case categoryID = "category_id"
        case creationDate = "creation_date"
        case isUrgent = "is_urgent"
        case imagesURL = "images_url"
    }
}

struct ListingsResponse: Decodable, Equatable {
    let items: [Listing]
    let total: Int
    let page: Int
    let limit: Int
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case items, total, page, limit
        case hasMore = "has_more"
    }
}
