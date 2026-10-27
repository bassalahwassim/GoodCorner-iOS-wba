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
        Self.loadStores(of: container)
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Charge le store. Si le fichier existant a été créé avec un ancien schéma
    /// (le modèle est en code, donc sans migration automatique possible), on le recrée :
    /// le brouillon est une donnée locale jetable. Pour des données à conserver,
    /// il faudrait un modèle versionné + migration légère.
    private static func loadStores(of container: NSPersistentContainer) {
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }

        guard let firstError = loadError else { return }
        guard
            let description = container.persistentStoreDescriptions.first,
            let url = description.url,
            url.path != "/dev/null"
        else {
            assertionFailure("Core Data store failed to load: \(firstError)")
            return
        }

        try? container.persistentStoreCoordinator.destroyPersistentStore(
            at: url, ofType: NSSQLiteStoreType, options: nil
        )
        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Core Data store failed to load after reset: \(error)")
            }
        }
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

        // Les images volumineuses sont stockées hors de la base SQLite par Core Data.
        let imageAttribute = attribute("imageData", .binaryDataAttributeType, optional: true)
        imageAttribute.allowsExternalBinaryDataStorage = true

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
            imageAttribute,
            attribute("updatedAt", .dateAttributeType)
        ]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }()
}
