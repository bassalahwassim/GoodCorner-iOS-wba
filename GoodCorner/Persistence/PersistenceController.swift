import CoreData

/// Pile Core Data. Le modèle est décrit en code (pas de fichier .xcdatamodeld),
/// ce qui le rend facile à relire, à versionner et à tester.
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    /// - Parameters:
    ///   - inMemory: store jetable pour les tests.
    ///   - storeURL: fichier SQLite explicite (tests de persistance entre "relances").
    init(inMemory: Bool = false, storeURL: URL? = nil) {
        container = NSPersistentContainer(name: "goodCorner", managedObjectModel: Self.model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else if let storeURL {
            container.persistentStoreDescriptions.first?.url = storeURL
        }
        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Core Data store failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Modèle partagé : une seule instance pour éviter les conflits de classes entre containers.
    static let model: NSManagedObjectModel = {
        func attribute(
            _ name: String,
            _ type: NSAttributeType,
            optional: Bool = false,
            defaultValue: Any? = nil
        ) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            attribute.defaultValue = defaultValue
            return attribute
        }

        let entity = NSEntityDescription()
        entity.name = DraftEntity.entityName
        entity.managedObjectClassName = NSStringFromClass(DraftEntity.self)
        entity.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("title", .stringAttributeType, defaultValue: ""),
            attribute("descriptionText", .stringAttributeType, defaultValue: ""),
            attribute("priceText", .stringAttributeType, defaultValue: ""),
            attribute("categoryID", .integer64AttributeType, optional: true),
            attribute("isUrgent", .booleanAttributeType, defaultValue: false),
            attribute("updatedAt", .dateAttributeType)
        ]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }()
}
