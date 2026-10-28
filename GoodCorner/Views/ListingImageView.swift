import SwiftUI

struct ListingImageView: View {
    let url: URL?
    /// .fill pour les vignettes, .fit pour l'image du détail (pas de recadrage ni d'agrandissement excessif).
    var contentMode: ContentMode = .fill

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: contentMode)
                case .failure:
                    placeholder
                default:
                    ZStack {
                        Color(.secondarySystemFill)
                        ProgressView()
                    }
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color(.secondarySystemFill)
            Image(systemName: "photo")
                .foregroundColor(.secondary)
        }
    }
}
