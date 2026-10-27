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
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func chip(_ label: Text, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            label
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .white : .primary)
                .background(
                    Capsule().fill(isSelected ? Color.brandStrong : Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : Color(.separator), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
