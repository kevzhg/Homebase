import SwiftUI
import FirebaseCore

@main
struct HomebaseAppApp: App {
    init() {
        logInfo("🚀 App starting up", category: "app")
        FirebaseApp.configure()
        logSuccess("Firebase configured", category: "app")
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house.fill")
                    }
                
                LiveWorkoutView()
                    .tabItem {
                        Label("Live Workout", systemImage: "figure.run")
                    }
            }
            .onAppear {
                FirebaseService.shared.startListening()
            }
        }
    }
}
