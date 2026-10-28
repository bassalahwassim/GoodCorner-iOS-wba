import SwiftUI

/// Vue réutilisée pour l'état d'erreur (avec "Réessayer") et l'état vide.
struct MessageStateView: View {
    let systemImage: String
    let title: LocalizedStringKey
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            if let retryAction {
                Button("state.retry", action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
