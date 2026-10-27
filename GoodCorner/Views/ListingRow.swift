import SwiftUI

struct ListingRow: View {
    let listing: Listing
    let categoryName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
			ListingImageView(url: AppConfig.absoluteURL(for: listing.imagesURL?.small))
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true) // décorative : le titre porte l'information
            VStack(alignment: .leading, spacing: 4) {
                Text(categoryName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(listing.title)
                    .font(.headline)
                Text(listing.price.formatted(.currency(code: "EUR")))
					.font(.subheadline.bold()).foregroundColor(.blue)
                if listing.isUrgent {
                    UrgentBadge()
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct UrgentBadge: View {
    var body: some View {
        Label("badge.urgent", systemImage: "bolt.fill")
            .font(.caption.bold())
            .foregroundColor(.orange)
    }
}
