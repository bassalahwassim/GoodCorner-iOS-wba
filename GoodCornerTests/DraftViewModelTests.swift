import XCTest
@testable import GoodCorner

private final class FakeDraftStore: DraftStore {
    var stored: ListingDraft?
    var saveCount = 0
    var discardCount = 0
    var error: Error?

    func load() throws -> ListingDraft? { stored }

    func save(_ draft: ListingDraft) throws {
        if let error { throw error }
        saveCount += 1
        stored = draft
    }

    func discard() throws {
        if let error { throw error }
        discardCount += 1
        stored = nil
    }
}

final class DraftViewModelTests: XCTestCase {
    private let sample = ListingDraft(title: "Table", description: "", priceText: "40", categoryID: 4, isUrgent: false)

    func testInitRestoresSavedDraft() {
        let store = FakeDraftStore()
        store.stored = sample
        let viewModel = DraftViewModel(store: store)

        XCTAssertEqual(viewModel.draft, sample)
        XCTAssertTrue(viewModel.hasSavedDraft)
    }

    func testInitWithoutSavedDraftStartsEmpty() {
        let viewModel = DraftViewModel(store: FakeDraftStore())
        XCTAssertTrue(viewModel.draft.isEmpty)
        XCTAssertFalse(viewModel.hasSavedDraft)
    }

    func testSaveNowPersistsNonEmptyDraft() {
        let store = FakeDraftStore()
        let viewModel = DraftViewModel(store: store)
        viewModel.draft = sample

        viewModel.saveNow()

        XCTAssertEqual(store.stored, sample)
        XCTAssertTrue(viewModel.hasSavedDraft)
    }

    func testSaveNowWithEmptyDraftDiscardsInsteadOfSaving() {
        let store = FakeDraftStore()
        store.stored = sample
        let viewModel = DraftViewModel(store: store)
        viewModel.draft = ListingDraft()

        viewModel.saveNow()

        XCTAssertEqual(store.saveCount, 0)
        XCTAssertNil(store.stored)
        XCTAssertFalse(viewModel.hasSavedDraft)
    }

    func testResetClearsFormAndStore() {
        let store = FakeDraftStore()
        store.stored = sample
        let viewModel = DraftViewModel(store: store)

        viewModel.reset()

        XCTAssertTrue(viewModel.draft.isEmpty)
        XCTAssertNil(store.stored)
        XCTAssertFalse(viewModel.hasSavedDraft)
    }

    func testStoreFailureIsExposed() {
        let store = FakeDraftStore()
        store.error = APIError.network
        let viewModel = DraftViewModel(store: store)
        viewModel.draft = sample

        viewModel.saveNow()

        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testWhitespaceOnlyDraftIsConsideredEmpty() {
        let draft = ListingDraft(title: "  ", description: "\n", priceText: " ", categoryID: nil, isUrgent: false)
        XCTAssertTrue(draft.isEmpty)
    }
}
