import CoreData

protocol DraftStore {
    func load() throws -> ListingDraft?
    func save(_ draft: ListingDraft) throws
    func discard() throws
}

/// Stocke au plus UN brouillon : le dernier en cours.
final class CoreDataDraftStore: DraftStore {
    private let context: NSManagedObjectContext

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        context = container.viewContext
    }

    func load() throws -> ListingDraft? {
        try context.performAndWait {
            guard let entity = try latestEntity() else { return nil }
            return ListingDraft(
                title: entity.title,
                description: entity.descriptionText,
                priceText: entity.priceText,
                categoryID: entity.categoryID?.intValue,
                isUrgent: entity.isUrgent,
                imageData: entity.imageData
            )
        }
    }

    func save(_ draft: ListingDraft) throws {
        try context.performAndWait {
            let entity: DraftEntity
            if let existing = try latestEntity() {
                entity = existing
            } else {
                entity = DraftEntity(context: context)
                entity.id = UUID()
            }
            entity.title = draft.title
            entity.descriptionText = draft.description
            entity.priceText = draft.priceText
            entity.categoryID = draft.categoryID.map { NSNumber(value: $0) }
            entity.isUrgent = draft.isUrgent
            entity.imageData = draft.imageData
            entity.updatedAt = Date()
            try context.save()
        }
    }

    func discard() throws {
        try context.performAndWait {
            let request = NSFetchRequest<DraftEntity>(entityName: DraftEntity.entityName)
            for entity in try context.fetch(request) {
                context.delete(entity)
            }
            if context.hasChanges {
                try context.save()
            }
        }
    }

    private func latestEntity() throws -> DraftEntity? {
        let request = NSFetchRequest<DraftEntity>(entityName: DraftEntity.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
