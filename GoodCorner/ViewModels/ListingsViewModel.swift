import Foundation

final class ListingsViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var listings: [Listing] = []
    @Published private(set) var categories: [ListingCategory] = []
    @Published var selectedCategoryID: Int?

    private let service: ListingsService

    init(service: ListingsService) {
        self.service = service
    }

    /// L'ordre renvoyé par l'API est conservé (filter ne réordonne pas).
    var filteredListings: [Listing] {
        guard let selectedCategoryID else { return listings }
        return listings.filter { $0.categoryID == selectedCategoryID }
    }

    func categoryName(for id: Int) -> String {
        categories.first { $0.id == id }?.name
            ?? NSLocalizedString("category.unknown", comment: "")
    }

    @MainActor
    func load() async {
        state = .loading
        do {
            async let fetchedListings = service.fetchListings()
            async let fetchedCategories = service.fetchCategories()
            let (newListings, newCategories) = try await (fetchedListings, fetchedCategories)
            listings = newListings
            categories = newCategories
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
