import XCTest
import CoreData
@testable import GoodCorner

final class CoreDataDraftStoreTests: XCTestCase {
    private func makeStore() -> (CoreDataDraftStore, PersistenceController) {
        let persistence = PersistenceController(inMemory: true)
        return (CoreDataDraftStore(container: persistence.container), persistence)
    }

    private let sample = ListingDraft(
        title: "Vélo", description: "Très bon état", priceText: "120",
        categoryID: 5, isUrgent: true
    )

    func testLoadReturnsNilWhenNothingSaved() throws {
        let (store, _) = makeStore()
        XCTAssertNil(try store.load())
    }

    func testSaveThenLoadRoundTrip() throws {
        let (store, _) = makeStore()
        try store.save(sample)
        XCTAssertEqual(try store.load(), sample)
    }

    func testSavingTwiceKeepsASingleDraft() throws {
        let (store, persistence) = makeStore()
        try store.save(sample)
        var updated = sample
        updated.title = "Vélo de route"
        try store.save(updated)

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: DraftEntity.entityName)
        XCTAssertEqual(try persistence.container.viewContext.count(for: request), 1)
        XCTAssertEqual(try store.load()?.title, "Vélo de route")
    }

    func testOptionalCategoryIsPreservedAsNil() throws {
        let (store, _) = makeStore()
        var draft = sample
        draft.categoryID = nil
        try store.save(draft)
        XCTAssertNil(try store.load()?.categoryID)
    }

    func testDiscardRemovesDraft() throws {
        let (store, _) = makeStore()
        try store.save(sample)
        try store.discard()
        XCTAssertNil(try store.load())
    }

    func testDraftSurvivesRelaunch() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".sqlite")
        addTeardownBlock {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(atPath: url.path + suffix)
            }
        }

        // "Première session" : on écrit puis on détache le store.
        let first = PersistenceController(storeURL: url)
        try CoreDataDraftStore(container: first.container).save(sample)
        let coordinator = first.container.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            try coordinator.remove(store)
        }

        // "Relance" : nouveau container sur le même fichier.
        let second = PersistenceController(storeURL: url)
        XCTAssertEqual(try CoreDataDraftStore(container: second.container).load(), sample)
    }
}
