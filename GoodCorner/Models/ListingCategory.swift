import Foundation

// ATTENTION : structure supposée ({ "id": Int, "name": String }).
// À confirmer avec la sortie réelle de GET /categories.
struct ListingCategory: Identifiable, Decodable, Equatable {
    let id: Int
    let name: String
}
