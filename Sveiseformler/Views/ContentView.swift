import SwiftUI

struct ContentView: View {
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.green, .font: UIFont.monospacedSystemFont(ofSize: 30, weight: .bold)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.green, .font: UIFont.monospacedSystemFont(ofSize: 20, weight: .bold)]
        UINavigationBar.appearance().barTintColor = .black
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                
                // HEADER LOGO
                VStack {
                    Text(verbatim: """
                     ___  _  _  ___  _  ___ 
                    / __|| || || __|| |/ __|
                    \\__ \\| \\/ || _| | |\\__ \\
                    |___/ \\__/ |___||_||___/
                    """)
                    .font(.custom("Menlo-Bold", size: 12))
                    .lineSpacing(2)
                    .foregroundColor(RetroTheme.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
                
                // Denne teksten oversettes automatisk hvis nøkkelen finnes i Localizable
                Text("SYSTEM STATUS: ONLINE")
                    .font(RetroTheme.font(size: 14))
                    .foregroundColor(RetroTheme.primary)
                    .padding(.bottom, 10)
                
                Divider().background(RetroTheme.primary)

                // MENY
                ScrollView {
                    VStack(spacing: 15) {
                        
                        NavigationLink(destination: HeatInputView()) {
                            TerminalMenuItem(label: "1. HEAT INPUT CALC")
                        }
                        
                        NavigationLink(destination: CarbonEquivalentView()) {
                            TerminalMenuItem(label: "2. CARBON EQUIV.")
                        }
                        
                        NavigationLink(destination: SchaefflerView()) {
                            TerminalMenuItem(label: "3. SCHAEFFLER CALC")
                        }
                        
                        NavigationLink(destination: DepositionRateView()) {
                            TerminalMenuItem(label: "4. DEPOSITION RATE")
                        }
                        
                        NavigationLink(destination: DictionaryView()) {
                            TerminalMenuItem(label: "5. WELD DICTIONARY")
                        }
                        
                        Divider().background(RetroTheme.primary.opacity(0.5))
                        
                        // --- NY KNAPP: MACHINE SETUP ---
                        NavigationLink(destination: SettingsView()) {
                            HStack {
                                Image(systemName: "wrench.and.screwdriver.fill") // Mer "mekanisk" ikon
                                Text("MACHINE SETUP") // Nytt navn!
                            }
                            .font(RetroTheme.font(size: 16, weight: .bold))
                            .foregroundColor(RetroTheme.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                        }
                    }
                }
                
                Spacer()
                
                Text("> WAITING FOR INPUT_")
                    .font(RetroTheme.font(size: 14))
                    .foregroundColor(RetroTheme.primary)
                    .opacity(0.8)
            }
            .padding()
            .crtScreen()
        }
        .accentColor(RetroTheme.primary)
        .preferredColorScheme(.dark)
    }
}

// Oppdatert Helper: Tar nå imot LocalizedStringKey
struct TerminalMenuItem: View {
    let label: LocalizedStringKey
    
    var body: some View {
        HStack {
            Text(label)
                .font(RetroTheme.font(size: 18, weight: .bold))
            Spacer()
            Text("[EXEC]")
                .font(RetroTheme.font(size: 12))
        }
        .padding()
        .border(RetroTheme.primary, width: 1)
        .foregroundColor(RetroTheme.primary)
    }
}
