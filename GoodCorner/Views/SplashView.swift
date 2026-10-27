import SwiftUI

/// Écran de démarrage animé : le logo apparaît en fondu puis fait un tour complet.
struct SplashView: View {
    /// Appelé quand l'animation est terminée.
    let onFinish: () -> Void

    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Même couleur que le fond du logo et que le Launch Screen : aucune coupure visible.
            Color("SplashBackground")
                .ignoresSafeArea()

            Image("SplashLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 320)
                .padding(32)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                .accessibilityLabel(Text("splash.logo"))
        }
        .task {
            if reduceMotion {
                // Accessibilité : pas de rotation si "Réduire les animations" est activé.
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 1
                    scale = 1
                }
                try? await Task.sleep(nanoseconds: 800_000_000)
            } else {
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 1
                    scale = 1
                }
                withAnimation(.easeInOut(duration: 1.2).delay(0.2)) {
                    rotation = 360
                }
                try? await Task.sleep(nanoseconds: 1_800_000_000)
            }
            if !Task.isCancelled {
                onFinish()
            }
        }
    }
}
