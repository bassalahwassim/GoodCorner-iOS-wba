import SwiftUI

struct ListingImageView: View {
    let url: URL?

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholder
                default:
                    ZStack {
                        Color(.secondarySystemBackground)
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
            Color(.secondarySystemBackground)
            Image(systemName: "photo")
                .foregroundColor(.secondary)
        }
    }
}
