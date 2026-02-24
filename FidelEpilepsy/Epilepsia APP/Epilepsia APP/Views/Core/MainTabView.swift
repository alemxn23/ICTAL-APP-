import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    init() {
        // Customize Tab Bar Appearance (Crystal Glass)
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground() // Default blur
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(Color.black.opacity(0.2)) // Tint
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.Medical.safe)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.Medical.safe)]
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.5)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "bolt.heart.fill")
                }
                .tag(0)
            
            // Diary Tab
            SeizureDiaryView()
            .tabItem {
                Label("Diary", systemImage: "doc.text.fill")
            }
            .tag(1)
            
            // Profile Tab
            PerfilView()
                .tabItem {
                    Label("Perfil", systemImage: "person.crop.circle.fill")
                }
                .tag(2)
        }
        .accentColor(.Medical.safe)
    }
}
