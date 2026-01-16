import SwiftUI

struct ContentView: View {
    
    // --- KONFIGURASJON ---
    // Disse endres ikke under kjøring, så 'let' er ryddigere enn '@State'
    private let mainMenuItems: [AppFeature] = [
        .heatInput,
        .carbonEquivalent,
        
    ]
    
    private let moreMenuItems: [AppFeature] = [
        .schaeffler,
        .depositionRate,
        .dictionary
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Bakgrunn
                RetroTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerSection
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            mainFeatureSection
                            moreToolsLink
                            systemToolsSection
                        }
                        .padding(.top, 10)
                        .padding(.horizontal)
                    }
                    
                    footerSection
                }
            }
            // Legger CRT-effekten på hele skjermen til slutt
            .crtScreen()
            .navigationBarHidden(true)
        }
        .accentColor(RetroTheme.primary)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Subviews & Sections
private extension ContentView {
    
    // 1. Header med ASCII Art og Status
    var headerSection: some View {
        VStack(spacing: 15) {
            Text(verbatim: """
             ___  _  _  ___  _  ___ 
            / __|| || || __|| |/ __|
            \\__ \\| \\/ || _| | |\\__ \\
            |___/ \\__/ |___||_||___/
            """)
            .font(.custom("Menlo-Bold", size: 12))
            .lineSpacing(2)
            .foregroundColor(RetroTheme.primary)
            .multilineTextAlignment(.center) // Endret til center for penere layout
            .padding(.top, 20)
            
            VStack(spacing: 20) {
                Text("SYSTEM STATUS: ONLINE")
                    .font(RetroTheme.font(size: 14))
                
                Divider()
                    .background(RetroTheme.primary)
            }
            .foregroundColor(RetroTheme.primary)
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    // 2. Hovedfunksjoner (Loop)
    var mainFeatureSection: some View {
        ForEach(Array(mainMenuItems.enumerated()), id: \.element) { index, feature in
            NavigationLink(destination: feature.destination) {
                TerminalMenuItem(index: index + 1, titleKey: feature.title)
            }
        }
    }
    
    // 3. Link til flere verktøy
    var moreToolsLink: some View {
        let moreMenuIndex = mainMenuItems.count + 1
        
        return NavigationLink(destination: MoreToolsView(features: moreMenuItems, startIndex: moreMenuIndex + 1)) {
            HStack {
                Text("\(moreMenuIndex). ") + Text(LocalizedStringKey("ADDITIONAL TOOLS"))
            }
            .retroButtonStyle() // Bruker ny helper-funksjon (se nederst)
        }
    }
    
    // 4. Systemverktøy (Settings & Dev)
    var systemToolsSection: some View {
        VStack(spacing: 15) {
            // Skillelinje
            HStack {
                Rectangle().frame(height: 1)
            }
            .foregroundColor(RetroTheme.dim)
            .padding(.vertical, 5)
            
            // Settings
            NavigationLink(destination: SettingsView()) {
                HStack {
                    Image(systemName: "wrench.and.screwdriver.fill")
                    Text("CONFIGURATION")
                }
                .retroButtonStyle()
            }
            
        }
    }
    
    // 5. Footer
    var footerSection: some View {
        Text("> WAITING FOR INPUT_")
            .font(RetroTheme.font(size: 14))
            .foregroundColor(RetroTheme.primary)
            .opacity(0.8)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Components

struct TerminalMenuItem: View {
    let index: Int
    let titleKey: LocalizedStringKey
    
    var body: some View {
        HStack {
            Text("\(index). ") + Text(titleKey)
            Spacer()
            Text("[EXEC]")
                .font(RetroTheme.font(size: 12))
        }
        .retroButtonStyle()
    }
}

// Hjelper for å unngå gjentatt styling-kode
extension View {
    func retroButtonStyle(fontSize: CGFloat = 18) -> some View {
        self
            .font(RetroTheme.font(size: fontSize, weight: .bold))
            .foregroundColor(RetroTheme.primary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                Rectangle().stroke(RetroTheme.primary, lineWidth: 1)
            )
            .contentShape(Rectangle()) // Gjør hele boksen trykkbar
    }
}
