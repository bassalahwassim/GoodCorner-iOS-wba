import SwiftUI

extension Color {
    /// Rouge du logo, légèrement assombri (#D32F2F) : contraste ≥ 4,5:1 avec du texte blanc.
    /// Utilisé comme couleur d'accent de l'app et pour les puces sélectionnées.
    static let brandStrong = Color(red: 211 / 255, green: 47 / 255, blue: 47 / 255)

    /// Jaune du logo (#F7E034), pour les badges.
    static let brandYellow = Color(red: 247 / 255, green: 224 / 255, blue: 52 / 255)

    /// Rouge pour du TEXTE : foncé en mode clair, plus vif en mode sombre (contraste suffisant des deux côtés).
    static let brandText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 239 / 255, green: 63 / 255, blue: 63 / 255, alpha: 1)
            : UIColor(red: 211 / 255, green: 47 / 255, blue: 47 / 255, alpha: 1)
    })
}

/// Fond « carte » : surface claire arrondie avec une ombre très légère.
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

extension View {
    func card() -> some View {
        modifier(CardModifier())
    }
}
