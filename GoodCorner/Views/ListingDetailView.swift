import SwiftUI

struct ListingDetailView: View {
    let listing: Listing
    let categoryName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ListingImageView(url: AppConfig.absoluteURL(for: listing.imagesURL?.thumb))
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipped()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(listing.title))
                    .accessibilityAddTraits(.isImage)

                Text(listing.title)
                    .font(.title2.bold())
                Text(listing.price.formatted(.currency(code: "EUR")))
					.font(.title3.bold()).foregroundColor(Color.blue)
                if listing.isUrgent {
                    UrgentBadge()
                }

                InfoRow(title: "detail.category", value: categoryName)
                InfoRow(
                    title: "detail.published",
                    value: listing.creationDate.formatted(date: .long, time: .shortened)
                )

                Text("detail.description")
                    .font(.headline)
                    .padding(.top, 8)
                Text(listing.description)
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("detail.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct InfoRow: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
        .accessibilityElement(children: .combine)
    }
}
