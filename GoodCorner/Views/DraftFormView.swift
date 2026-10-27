import SwiftUI

struct DraftFormView: View {
    @ObservedObject var viewModel: DraftViewModel
    let categories: [ListingCategory]

    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDiscard = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("draft.field.title", text: $viewModel.draft.title)
                    TextField("draft.field.price", text: $viewModel.draft.priceText)
                        .keyboardType(.decimalPad)
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
            .onDisappear { viewModel.saveNow() }
        }
    }
}
