import XCTest
@testable import goodCorner

/// Petit journal thread-safe utilisé par les handlers de test.
private final class Log {
    private let lock = NSLock()
    private var storage: [String] = []
    func add(_ value: String) { lock.lock(); storage.append(value); lock.unlock() }
    var items: [String] { lock.lock(); defer { lock.unlock() }; return storage }
}

@MainActor
final class ListingSearchTests: XCTestCase {
    private func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    func testRapidTypingTriggersSingleRequestWithFinalTerm() async throws {
        let service = MockListingsService()
        let viewModel = ListingsViewModel(service: service, searchDebounce: .milliseconds(40))

        viewModel.searchText = "v"
        viewModel.searchText = "vi"
        viewModel.searchText = "vin"

        try await waitUntil { service.queries.contains { $0 == "vin" } }
        try await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertEqual(service.queries, ["vin"])
    }

    func testClearingSearchFetchesAllListingsWithoutQuery() async throws {
        let service = MockListingsService()
        let viewModel = ListingsViewModel(service: service, searchDebounce: .milliseconds(30))

        viewModel.searchText = "abc"
        try await waitUntil { service.queries.count == 1 }
        viewModel.searchText = "  "
        try await waitUntil { service.queries.count == 2 }

        XCTAssertEqual(service.queries, ["abc", nil])
    }

    func testNewQueryCancelsInFlightRequest() async throws {
        let service = MockListingsService()
        let cancelled = Log()
        service.listingsHandler = { query in
            if query == "slow" {
                do {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                } catch {
                    cancelled.add("slow")
                    throw error
                }
                return [.stub(id: 1)]
            }
            return [.stub(id: 2)]
        }
        let viewModel = ListingsViewModel(service: service, searchDebounce: .milliseconds(30))

        viewModel.searchText = "slow"
        try await waitUntil { service.queries.contains { $0 == "slow" } }
        viewModel.searchText = "fast"
        try await waitUntil { viewModel.listings.map(\.id) == [2] }
        try await waitUntil { !cancelled.items.isEmpty }

        XCTAssertEqual(cancelled.items, ["slow"])
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertFalse(viewModel.isUpdating)
    }

    func testStaleResultIsIgnoredEvenIfOldRequestIgnoresCancellation() async throws {
        let service = MockListingsService()
        service.listingsHandler = { query in
            if query == "slow" {
                // Ne réagit pas à l'annulation : renvoie son résultat en retard.
                _ = await Task.detached { try? await Task.sleep(nanoseconds: 300_000_000) }.value
                return [.stub(id: 1)]
            }
            return [.stub(id: 2)]
        }
        let viewModel = ListingsViewModel(service: service, searchDebounce: .milliseconds(30))

        viewModel.searchText = "slow"
        try await waitUntil { service.queries.contains { $0 == "slow" } }
        viewModel.searchText = "fast"
        try await waitUntil { viewModel.listings.map(\.id) == [2] }
        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertEqual(viewModel.listings.map(\.id), [2])
    }

    func testSearchWithNoResultsIsLoadedAndEmpty() async throws {
        let service = MockListingsService()
        service.listingsHandler = { _ in [] }
        let viewModel = ListingsViewModel(service: service, searchDebounce: .milliseconds(30))

        viewModel.searchText = "zzz"
        try await waitUntil { viewModel.state == .loaded }

        XCTAssertTrue(viewModel.filteredListings.isEmpty)
        XCTAssertEqual(viewModel.trimmedSearchTerm, "zzz")
    }

    func testSearchFailureSetsFailedStateAndRetryRecovers() async throws {
        let service = MockListingsService()
        service.listingsHandler = { _ in throw APIError.network }
        let viewModel = ListingsViewModel(service: service, searchDebounce: .milliseconds(30))

        viewModel.searchText = "abc"
        let expected = ListingsViewModel.State.failed(APIError.network.errorDescription ?? "")
        try await waitUntil { viewModel.state == expected }
        XCTAssertEqual(viewModel.state, expected)

        service.listingsHandler = { _ in [.stub(id: 7)] }
        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.listings.map(\.id), [7])
        XCTAssertEqual(service.queries.last ?? "x", "abc") // le réessai conserve le terme
    }

    func testCategoryFilterStillAppliesToSearchResults() async throws {
        let service = MockListingsService()
        service.listingsHandler = { _ in [.stub(id: 1, categoryID: 1), .stub(id: 2, categoryID: 2)] }
        let viewModel = ListingsViewModel(service: service, searchDebounce: .milliseconds(30))

        viewModel.searchText = "x"
        try await waitUntil { viewModel.state == .loaded }
        viewModel.selectedCategoryID = 2

        XCTAssertEqual(viewModel.filteredListings.map(\.id), [2])
    }
}
