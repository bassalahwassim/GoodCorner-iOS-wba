import SwiftUI

struct ListingsView: View {
    @StateObject private var viewModel: ListingsViewModel
    @StateObject private var draftViewModel: DraftViewModel
    @State private var isShowingDraft = false
    @State private var didRestoreDraft = false
    @Environment(\.scenePhase) private var scenePhase

    init(
        viewModel: ListingsViewModel = ListingsViewModel(service: APIClient()),
        draftViewModel: DraftViewModel = DraftViewModel(store: CoreDataDraftStore())
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _draftViewModel = StateObject(wrappedValue: draftViewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("list.title")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            isShowingDraft = true
                        } label: {
                            Label(
                                "draft.open",
                                systemImage: draftViewModel.hasSavedDraft
                                    ? "square.and.pencil.circle.fill"
                                    : "square.and.pencil"
                            )
                            .labelStyle(.iconOnly)
                        }
                    }
                }
        }
        .sheet(isPresented: $isShowingDraft) {
            DraftFormView(viewModel: draftViewModel, categories: viewModel.categories)
        }
        .task {
            if viewModel.state == .idle {
                await viewModel.load()
            }
            // Restauration : si un brouillon existait à la fermeture, on le rouvre au lancement.
            if !didRestoreDraft {
                didRestoreDraft = true
                if draftViewModel.hasSavedDraft {
                    isShowingDraft = true
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                draftViewModel.saveNow()
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
