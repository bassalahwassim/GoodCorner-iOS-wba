import Foundation
import Combine

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
    /// Vrai pendant qu'une requête est en cours alors qu'une liste est déjà affichée.
    @Published private(set) var isUpdating = false
    @Published var selectedCategoryID: Int?
    @Published var searchText = ""

    private let service: ListingsService
    private var fetchTask: Task<Void, Never>?
    private var generation = 0
    private var cancellables = Set<AnyCancellable>()

    init(
        service: ListingsService,
        searchDebounce: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300)
    ) {
        self.service = service

        // Recherche en temps réel : on attend une pause de frappe avant d'appeler l'API.
        $searchText
            .dropFirst()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: searchDebounce, scheduler: DispatchQueue.main)
            .removeDuplicates()
			.sink { [weak self] _ in
				guard let self else { return }
				Task { @MainActor in
					_ = self.startFetch()
				}
			}
            .store(in: &cancellables)
    }

    var trimmedSearchTerm: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
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

    /// Chargement initial, réessai et pull-to-refresh (utilise la recherche en cours).
    @MainActor
    func load() async {
        await startFetch().value
    }

    // MARK: - Requêtes

    /// Lance une requête et ANNULE la précédente : une seule requête reste active.
    @MainActor
    @discardableResult
    private func startFetch() -> Task<Void, Never> {
        fetchTask?.cancel()
        generation += 1
        let current = generation
        let term = trimmedSearchTerm.isEmpty ? nil : trimmedSearchTerm
        let needsCategories = categories.isEmpty

        switch state {
        case .idle, .failed:
            state = .loading
        case .loading, .loaded:
            break
        }
        isUpdating = (state == .loaded)

		let task = Task { @MainActor [weak self] in
			guard let self else { return }
			await self.fetch(generation: current, term: term, loadCategories: needsCategories)
		}
        fetchTask = task
        return task
    }

    @MainActor
    private func fetch(generation current: Int, term: String?, loadCategories: Bool) async {
        do {
            let newListings: [Listing]
            var newCategories: [ListingCategory]?
            if loadCategories {
                async let listingsRequest = service.fetchListings(query: term)
                async let categoriesRequest = service.fetchCategories()
                let (fetchedListings, fetchedCategories) = try await (listingsRequest, categoriesRequest)
                newListings = fetchedListings
                newCategories = fetchedCategories
            } else {
                newListings = try await service.fetchListings(query: term)
            }

            // Résultat périmé (une requête plus récente a démarré) : on l'ignore.
            guard current == generation else { return }
            listings = newListings
            if let newCategories { categories = newCategories }
            state = .loaded
            isUpdating = false
        } catch is CancellationError {
            // Remplacée par une requête plus récente : rien à afficher.
        } catch {
            guard current == generation else { return }
            state = .failed(error.localizedDescription)
            isUpdating = false
        }
    }
}
