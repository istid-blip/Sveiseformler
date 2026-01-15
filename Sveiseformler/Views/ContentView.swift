import SwiftUI

struct ContentView: View {
    
    // Vi deler funksjonene i to lister.
    @State private var mainMenuItems: [AppFeature] = [
        .heatInput,
        .carbonEquivalent,
        .wideverticaljogger
    ]
    
    @State private var moreMenuItems: [AppFeature] = [
        .schaeffler,
        .depositionRate,
        .dictionary
    ]
    
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
                
                Text("SYSTEM STATUS: ONLINE")
                    .font(RetroTheme.font(size: 14))
                    .foregroundColor(RetroTheme.primary)
                    .padding(.bottom, 10)
                
                Divider().background(RetroTheme.primary)

                // MENY
                ScrollView {
                    VStack(spacing: 15) {
                        
                        // 1. DYNAMISK HOVEDMENY
                        // Vi bruker Array(mainMenuItems.enumerated()) for å få indeks
                        ForEach(Array(mainMenuItems.enumerated()), id: \.element) { index, feature in
                            NavigationLink(destination: feature.destination) {
                                // Sender indeks og tittel separat for oversettelse
                                TerminalMenuItem(index: index + 1, titleKey: feature.title)
                            }
                        }
                        
                        // 2. LENKE TIL FLERE VERKTØY
                        let moreMenuIndex = mainMenuItems.count + 1
                        
                        NavigationLink(destination: MoreToolsView(features: moreMenuItems, startIndex: moreMenuIndex + 1)) {
                            HStack {
                                // Her setter vi sammen to tekster: tallet (uendret) og nøkkelen (oversatt)
                                Text("\(moreMenuIndex). ") + Text(LocalizedStringKey("ADDITIONAL TOOLS"))
                            }
                            .font(RetroTheme.font(size: 18, weight: .bold))
                            .foregroundColor(RetroTheme.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                        }

                        Divider().background(RetroTheme.primary.opacity(0.5))
                            .padding(.vertical, 10)
                        
                        // 3. FASTE SYSTEM-VALG
                        NavigationLink(destination: JogWheelTestContainer()) {
                            // Dev-test trenger ikke oversettelse, men vi kan bruke structen
                            TerminalMenuItem(index: 99, titleKey: "DEV. JOG WHEEL TEST")
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            HStack {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                Text("MACHINE SETUP") // Denne oversettes automatisk hvis den finnes i Localizable
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

// Oppdatert TerminalMenuItem som støtter oversettelse
struct TerminalMenuItem: View {
    let index: Int
    let titleKey: LocalizedStringKey // Endret fra String til LocalizedStringKey
    
    var body: some View {
        HStack {
            // Nå trenger vi ikke konvertere, vi kan bruke titleKey direkte
            Text("\(index). ") + Text(titleKey)
            
            Spacer()
            
            Text("[EXEC]")
                .font(RetroTheme.font(size: 12))
        }
        .font(RetroTheme.font(size: 18, weight: .bold))
        .padding()
        .border(RetroTheme.primary, width: 1)
        .foregroundColor(RetroTheme.primary)
    }
}

// Dev-container beholdes lik
struct JogWheelTestContainer: View {
    @State private var testValue: Double = 100.0
    
    var body: some View {
        ZStack {
            RetroTheme.background.ignoresSafeArea()
            CustomJogWheel(
                title: "TEST WHEEL",
                value: $testValue,
                range: 0...500,
                step: 1.0
            )
        }
        .navigationTitle("JOG WHEEL TEST")
    }
}
