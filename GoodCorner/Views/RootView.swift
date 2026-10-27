import SwiftUI

/// Affiche le splash au lancement, puis l'écran principal.
struct RootView: View {
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            if isShowingSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        isShowingSplash = false
                    }
                }
                .transition(.opacity)
            } else {
                ListingsView()
                    .transition(.opacity)
            }
        }
    }
}
