import SwiftUI

struct ListingDetailView: View {
    let listing: Listing
    let categoryName: String

    private var priceText: String {
        listing.price.formatted(.currency(code: "EUR"))
    }

    private var publishedText: String {
        String(
            format: NSLocalizedString("detail.published.on", comment: ""),
            listing.creationDate.formatted(date: .long, time: .omitted)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Image entière (fit) sur fond neutre : plus de recadrage ni de zoom flou.
                ListingImageView(
                    url: AppConfig.absoluteURL(for: listing.imagesURL?.small),
                    contentMode: .fit
                )
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(listing.title))
                .accessibilityAddTraits(.isImage)

                VStack(alignment: .leading, spacing: 12) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { tags }
                        VStack(alignment: .leading, spacing: 6) { tags }
                    }
                    Text(listing.title)
                        .font(.title2.bold())
                    Text(priceText)
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .foregroundColor(.brandText)
                    Label(publishedText, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("detail.description")
                        .font(.headline)
                    Text(listing.description)
                        .font(.body)
                        .textSelection(.enabled)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("detail.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: "\(listing.title) – \(priceText)")
            }
        }
    }

    @ViewBuilder
    private var tags: some View {
        CategoryTag(name: categoryName)
        if listing.isUrgent {
            UrgentBadge()
        }
    }
}
