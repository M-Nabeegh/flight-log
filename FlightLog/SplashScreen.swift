import SwiftUI

/// The black card shown at launch: the mark springs in, the line rises under it,
/// then the heart settles into a slow beat until the app takes over.
struct SplashScreen: View {
    @State private var markIn = false
    @State private var lineIn = false
    @State private var beating = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Palette.flag)
                    .shadow(color: Palette.flag.opacity(0.45), radius: beating ? 18 : 8)
                    .scaleEffect(markIn ? (beating ? 1.06 : 1) : 0.55)
                    .opacity(markIn ? 1 : 0)

                Text("Made with love")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(.white.opacity(0.9))
                    .opacity(lineIn ? 1 : 0)
                    .offset(y: lineIn ? 0 : 10)
                    .blur(radius: lineIn ? 0 : 3)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.62)) { markIn = true }
            withAnimation(.easeOut(duration: 0.6).delay(0.28)) { lineIn = true }
            withAnimation(.easeInOut(duration: 0.85).delay(0.75).repeatForever(autoreverses: true)) {
                beating = true
            }
        }
    }
}

/// Holds the splash over the app, then hands over: the card lifts and fades
/// while the app eases up from just under full size, so the two moves overlap
/// instead of cutting.
struct Launcher<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var covered = true

    var body: some View {
        ZStack {
            content
                .scaleEffect(covered ? 0.97 : 1)
                .opacity(covered ? 0 : 1)
                .animation(.easeOut(duration: 0.55), value: covered)

            if covered {
                SplashScreen()
                    .transition(.asymmetric(
                        insertion: .identity,
                        removal: .scale(scale: 1.08).combined(with: .opacity)))
                    .zIndex(1)
            }
        }
        .task {
            // Cold start already spends ~0.9s on the system launch screen before
            // this appears, so the hold is short on purpose.
            try? await Task.sleep(for: .seconds(1.35))
            withAnimation(.easeInOut(duration: 0.6)) { covered = false }
        }
    }
}

#Preview { SplashScreen() }
