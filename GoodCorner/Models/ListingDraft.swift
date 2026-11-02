import Foundation

/// Modèle de domaine du brouillon (indépendant de Core Data).
struct ListingDraft: Equatable {
    var title = ""
    var description = ""
    var priceText = ""
    var categoryID: Int?
    var isUrgent = false
    /// Photo choisie dans la photothèque (JPEG redimensionné).
    var imageData: Data?

    /// Un brouillon "vide" n'est jamais persisté.
    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && priceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && categoryID == nil
            && imageData == nil
    }
}
