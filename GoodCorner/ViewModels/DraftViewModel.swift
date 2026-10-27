import Foundation
import Combine

final class DraftViewModel: ObservableObject {
    @Published var draft: ListingDraft
    @Published private(set) var hasSavedDraft: Bool
    @Published private(set) var errorMessage: String?

    private let store: DraftStore
    private var cancellables = Set<AnyCancellable>()

    init(store: DraftStore, autosaveDelay: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(500)) {
        self.store = store
        let restored = try? store.load()   // ListingDraft? (try? aplatit l'optionnel)
        self.draft = restored ?? ListingDraft()
        self.hasSavedDraft = restored != nil

        // Sauvegarde automatique, avec debounce pour ne pas écrire à chaque frappe.
        $draft
            .dropFirst()
            .removeDuplicates()
            .debounce(for: autosaveDelay, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.saveNow() }
            .store(in: &cancellables)
    }

    /// Écrit immédiatement (fermeture du formulaire, passage en arrière-plan).
    func saveNow() {
        do {
            if draft.isEmpty {
                try store.discard()
                hasSavedDraft = false
            } else {
                try store.save(draft)
                hasSavedDraft = true
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Redimensionne la photo choisie hors du thread principal, puis l'ajoute au brouillon.
    @MainActor
    func attachPhoto(rawData: Data) async {
        let processed = await Task.detached(priority: .userInitiated) {
            ImageProcessor.jpegData(from: rawData)
        }.value

        if let processed {
            draft.imageData = processed
            errorMessage = nil
        } else {
            errorMessage = NSLocalizedString("draft.photo.error", comment: "")
        }
    }

    func removePhoto() {
        draft.imageData = nil
    }

    /// Vide le formulaire (il reste ouvert) et supprime la copie persistée.
    func reset() {
        draft = ListingDraft()
        do {
            try store.discard()
            hasSavedDraft = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Abandonne le brouillon : même effet que reset(), l'appelant ferme ensuite l'écran.
    func discard() {
        reset()
    }
}
