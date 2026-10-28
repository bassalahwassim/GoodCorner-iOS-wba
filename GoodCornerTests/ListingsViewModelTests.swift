import XCTest
@testable import GoodCorner

final class ListingsViewModelTests: XCTestCase {
    private let categories = [
        ListingCategory(id: 1, name: "Vêtement"),
        ListingCategory(id: 2, name: "Maison")
    ]

    func testLoadSuccessPreservesAPIOrder() async {
        let service = MockListingsService(
            listingsResult: .success([.stub(id: 3), .stub(id: 1), .stub(id: 2)]),
            categoriesResult: .success(categories)
        )
        let viewModel = ListingsViewModel(service: service)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.listings.map(\.id), [3, 1, 2])
    }

    func testFilterByCategoryKeepsOrder() async {
        let service = MockListingsService(
            listingsResult: .success([
                .stub(id: 1, categoryID: 1), .stub(id: 2, categoryID: 2),
                .stub(id: 3, categoryID: 1)
            ]),
            categoriesResult: .success(categories)
        )
        let viewModel = ListingsViewModel(service: service)
        await viewModel.load()

        viewModel.selectedCategoryID = 1
        XCTAssertEqual(viewModel.filteredListings.map(\.id), [1, 3])

        viewModel.selectedCategoryID = nil
        XCTAssertEqual(viewModel.filteredListings.count, 3)
    }

    func testFailureSetsFailedState() async {
        let service = MockListingsService(listingsResult: .failure(APIError.network))
        let viewModel = ListingsViewModel(service: service)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed(APIError.network.errorDescription ?? ""))
        XCTAssertTrue(viewModel.listings.isEmpty)
    }

    func testCategoryNameLookup() async {
        let service = MockListingsService(categoriesResult: .success(categories))
        let viewModel = ListingsViewModel(service: service)
        await viewModel.load()

        XCTAssertEqual(viewModel.categoryName(for: 2), "Maison")
        XCTAssertEqual(viewModel.categoryName(for: 99), NSLocalizedString("category.unknown", comment: ""))
    }
}
