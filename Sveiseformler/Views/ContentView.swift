import SwiftUI

struct ContentView: View {
    
    // Setter opp retro-stil på navigasjonsbaren
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.green, .font: UIFont.monospacedSystemFont(ofSize: 30, weight: .bold)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.green, .font: UIFont.monospacedSystemFont(ofSize: 20, weight: .bold)]
        UINavigationBar.appearance().barTintColor = .black
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                
                VStack {
                    // VIKTIG: "verbatim:" forteller SwiftUI at den skal ignorere Markdown-koder som _ og *
                    Text(verbatim: """
                     ___  _  _  ___  _  ___ 
                    / __|| || || __|| |/ __|
                    \\__ \\| \\/ || _| | |\\__ \\
                    |___/ \\__/ |___||_||___/
                    """)
                    // Vi bruker "Menlo-Bold" fordi den er 100% monospaced på alle iOS-enheter
                    .font(.custom("Menlo-Bold", size: 12))
                    .lineSpacing(2)
                    .foregroundColor(RetroTheme.primary)
                    .multilineTextAlignment(.leading) // Sørger for at tegnene treffer hverandre vertikalt
                    .fixedSize(horizontal: false, vertical: true) // Hindrer at teksten blir kuttet
                }
                .frame(maxWidth: .infinity) // Sentrerer selve blokken på skjermen
                .padding(.bottom, 20)
                
                Text("SYSTEM STATUS: ONLINE")
                    .font(RetroTheme.font(size: 14))
                    .foregroundColor(RetroTheme.primary)
                    .padding(.bottom, 10)
                
                Divider().background(RetroTheme.primary)

                // Menyvalg - Kun de 3 kalkulatorene
                Group {
                    NavigationLink(destination: HeatInputView()) {
                        TerminalMenuItem(label: "1. HEAT INPUT CALC")
                    }
                    
                    NavigationLink(destination: CarbonEquivalentView()) {
                        TerminalMenuItem(label: "2. CARBON EQUIV.")
                    }
                    
                    NavigationLink(destination: DepositionRateView()) {
                        TerminalMenuItem(label: "3. DEPOSITION RATE")
                    }
                }
                
                Spacer()
                
                Text("> WAITING FOR INPUT_")
                    .font(RetroTheme.font(size: 14))
                    .foregroundColor(RetroTheme.primary)
                    .opacity(0.8)
            }
            .padding()
            .crtScreen() // Legger på den grønne bakgrunnen og scanlines
        }
        .accentColor(RetroTheme.primary) // Gjør at tilbake-piler blir grønne
        .preferredColorScheme(.dark)
    }
}

// Hjelpevisning for menyknappene
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
        .border(RetroTheme.primary, width: 1)
        .foregroundColor(RetroTheme.primary)
    }
}
