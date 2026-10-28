import SwiftUI
import PhotosUI

struct DraftFormView: View {
    @ObservedObject var viewModel: DraftViewModel
    let categories: [ListingCategory]

    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDiscard = false
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                photoSection

                Section {
                    TextField("draft.field.title", text: $viewModel.draft.title)
                    TextField("draft.field.price", text: $viewModel.draft.priceText)
                        .keyboardType(.decimalPad)
						.onChange(of: viewModel.draft.priceText) { newValue in
							let cleaned = PriceInput.sanitize(newValue)
							if cleaned != newValue {
								viewModel.draft.priceText = cleaned
							}
						}
                    Picker("draft.field.category", selection: $viewModel.draft.categoryID) {
                        Text("draft.field.none").tag(Int?.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(Int?.some(category.id))
                        }
                    }
                    Toggle("draft.field.urgent", isOn: $viewModel.draft.isUrgent)
                }

                Section("draft.field.description") {
                    TextEditor(text: $viewModel.draft.description)
                        .frame(minHeight: 120)
                }

                Section {
                    Button("draft.reset") { viewModel.reset() }
                        .disabled(viewModel.draft.isEmpty)
                    Button("draft.discard", role: .destructive) { isConfirmingDiscard = true }
                        .disabled(viewModel.draft.isEmpty)
                } footer: {
                    if let message = viewModel.errorMessage {
                        Text(message).foregroundColor(.red)
                    } else {
                        Text("draft.autosave.note")
                    }
                }
            }
            .navigationTitle("draft.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("draft.close") { dismiss() }
                }
            }
            .confirmationDialog("draft.discard.confirm", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                Button("draft.discard", role: .destructive) {
                    viewModel.discard()
                    dismiss()
                }
            }
            .onChange(of: pickerItem) { item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await viewModel.attachPhoto(rawData: data)
                    } else {
                        await viewModel.attachPhoto(rawData: Data()) // déclenche le message d'erreur
                    }
                    pickerItem = nil
                }
            }
            .onDisappear { viewModel.saveNow() }
        }
    }

    private var photoSection: some View {
        let hasPhoto = viewModel.draft.imageData != nil
        return Section("draft.photo.header") {
            if let data = viewModel.draft.imageData {
                DraftPhotoPreview(data: data)
                    .equatable()
                Button("draft.photo.remove", role: .destructive) {
                    viewModel.removePhoto()
                }
            }
            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                Label(
                    LocalizedStringKey(hasPhoto ? "draft.photo.change" : "draft.photo.add"),
                    systemImage: "photo.on.rectangle"
                )
            }
        }
    }
}

/// Equatable pour éviter de re-décoder l'image à chaque frappe dans le formulaire.
private struct DraftPhotoPreview: View, Equatable {
    let data: Data

    var body: some View {
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel(Text("draft.photo.preview"))
                .accessibilityAddTraits(.isImage)
        }
    }
}
