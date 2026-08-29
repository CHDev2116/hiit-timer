import SwiftUI

@main
struct HIITTimerApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    ContentView()
                }
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

                NavigationStack {
                    DashboardView()
                }
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar")
                }
            }
        }
    }
}
