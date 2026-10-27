import SwiftUI

struct ListingsView: View {
    @StateObject private var viewModel: ListingsViewModel

    init(viewModel: ListingsViewModel = ListingsViewModel(service: APIClient())) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("list.title")
        }
        .task {
            if viewModel.state == .idle {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView { Text("state.loading") }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            MessageStateView(
                systemImage: "exclamationmark.triangle",
                title: "state.error.title",
                message: message,
                retryAction: { Task { await viewModel.load() } }
            )
        case .loaded:
            VStack(spacing: 0) {
                CategoryFilterView(
                    categories: viewModel.categories,
                    selectedID: $viewModel.selectedCategoryID
                )
                if viewModel.filteredListings.isEmpty {
                    MessageStateView(
                        systemImage: "tray",
                        title: "state.empty.title",
                        message: NSLocalizedString("state.empty.message", comment: ""),
                        retryAction: nil
                    )
                } else {
                    List(viewModel.filteredListings) { listing in
                        NavigationLink {
                            ListingDetailView(
                                listing: listing,
                                categoryName: viewModel.categoryName(for: listing.categoryID)
                            )
                        } label: {
                            ListingRow(
                                listing: listing,
                                categoryName: viewModel.categoryName(for: listing.categoryID)
                            )
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await viewModel.load() }
                }
            }
        }
    }
}
