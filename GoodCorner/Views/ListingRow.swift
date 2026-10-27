import SwiftUI

struct ListingRow: View {
    let listing: Listing
    let categoryName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ListingImageView(url: AppConfig.absoluteURL(for: listing.imagesURL?.thumb))
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true) // décorative : le titre porte l'information

            VStack(alignment: .leading, spacing: 6) {
                // Si la place manque (texte agrandi), les étiquettes passent l'une sous l'autre.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) { tags }
                    VStack(alignment: .leading, spacing: 4) { tags }
                }
                Text(listing.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Text(listing.price.formatted(.currency(code: "EUR")))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.brandText)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var tags: some View {
        CategoryTag(name: categoryName)
        if listing.isUrgent {
            UrgentBadge()
        }
    }
}

struct CategoryTag: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.caption)
            .lineLimit(1)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color(.secondarySystemFill)))
    }
}

struct UrgentBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "bolt.fill")
            Text("badge.urgent")
        }
        .font(.caption2.weight(.heavy))
        .textCase(.uppercase)
        .foregroundColor(.black)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(Color.brandYellow))
        .accessibilityElement(children: .combine)
    }
}
