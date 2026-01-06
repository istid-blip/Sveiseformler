import SwiftUI

struct ContentView: View {
    
    // Hide the default nav bar to keep the retro look
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.green, .font: UIFont.monospacedSystemFont(ofSize: 30, weight: .bold)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.green, .font: UIFont.monospacedSystemFont(ofSize: 20, weight: .bold)]
        UINavigationBar.appearance().barTintColor = .black
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                
                // ASCII Header
                Text("""
                 __        __   _     _ 
                 \\ \\      / /__| | __| |
                  \\ \\ /\\ / / _ \\ |/ _` |
                   \\ V  V /  __/ | (_| |
                    \\_/\\_/ \\___|_|\\__,_|
                """)
                .font(RetroTheme.font(size: 12))
                .foregroundColor(RetroTheme.primary)
                .padding(.bottom, 20)
                
                Text("SYSTEM STATUS: ONLINE")
                    .font(RetroTheme.font(size: 14))
                    .foregroundColor(RetroTheme.primary)
                    .padding(.bottom, 10)
                
                Divider().background(RetroTheme.primary)

                // Menu Items
                Group {
                    NavigationLink(destination: HeatInputView()) {
                        TerminalMenuItem(label: "1. HEAT INPUT CALC")
                    }
                    
                    NavigationLink(destination: CarbonEquivalentView()) {
                        TerminalMenuItem(label: "2. CARBON EQUIV.")
                    }
                    
                    NavigationLink(destination: DictionaryView()) {
                        TerminalMenuItem(label: "3. DICTIONARY (DB)")
                    }
                }
                
                Spacer()
                
                Text("> WAITING FOR INPUT_")
                    .font(RetroTheme.font(size: 14))
                    .foregroundColor(RetroTheme.primary)
                    .opacity(0.8)
            }
            .padding()
            .crtScreen() // Apply the background and scanlines
        }
        .accentColor(RetroTheme.primary) // Color the back arrows green
        .preferredColorScheme(.dark)
    }
}

// A helper view for the menu buttons
struct TerminalMenuItem: View {
    let label: String
    var body: some View {
        HStack {
            Text(label)
                .font(RetroTheme.font(size: 18, weight: .bold))
            Spacer()
            Text("[EXEC]")
                .font(RetroTheme.font(size: 12))
        }
        .padding()
        .border(RetroTheme.primary, width: 1) // Simple border
        .foregroundColor(RetroTheme.primary)
    }
}
