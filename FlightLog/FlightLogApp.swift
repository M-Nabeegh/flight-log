import SwiftUI

@main
struct FlightLogApp: App {
    var body: some Scene {
        WindowGroup {
            Launcher {
                RootView()
            }
            .tint(Palette.accent)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            FlightsScreen()
                .tabItem { Label("Flights", systemImage: "airplane.departure") }

            MapScreen()
                .tabItem { Label("Map", systemImage: "globe.asia.australia") }

            StatsScreen()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

            AboutScreen()
                .tabItem { Label("About", systemImage: "person.crop.circle") }
        }
    }
}

#Preview {
    RootView().tint(Palette.accent)
}
