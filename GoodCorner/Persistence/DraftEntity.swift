import CoreData

@objc(DraftEntity)
final class DraftEntity: NSManagedObject {
    static let entityName = "DraftEntity"

    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var descriptionText: String
    @NSManaged var priceText: String
    @NSManaged var categoryID: NSNumber?
    @NSManaged var isUrgent: Bool
    @NSManaged var imageData: Data?
    @NSManaged var updatedAt: Date
}
