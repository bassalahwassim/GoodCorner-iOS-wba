import SwiftUI

struct CategoryFilterView: View {
    let categories: [ListingCategory]
    @Binding var selectedID: Int?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(Text("filter.all"), isSelected: selectedID == nil) {
                    selectedID = nil
                }
                ForEach(categories) { category in
                    chip(Text(category.name), isSelected: selectedID == category.id) {
                        selectedID = category.id
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func chip(_ label: Text, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            label
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground)))
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
