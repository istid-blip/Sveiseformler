//
//  ContentView.swift
//  Sveiseformler
//
//  Created by Frode Halrynjo on 12/01/2026.
//

import SwiftUI

struct ContentView: View {
    
    // Vi deler funksjonene i to lister.
    // Senere kan vi lage en funksjon som lar brukeren flytte elementer mellom disse to arrayene!
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
                        // Vi går gjennom listen over "favoritter"
                        ForEach(Array(mainMenuItems.enumerated()), id: \.element) { index, feature in
                            NavigationLink(destination: feature.destination) {
                                // Lager etikett som "1. HEAT INPUT..."
                                TerminalMenuItem(label: "\(index + 1). \(feature.title)")
                            }
                        }
                        
                        // 2. LENKE TIL FLERE VERKTØY
                        // Nummeret blir "antall i hovedmeny + 1"
                        let moreMenuIndex = mainMenuItems.count + 1
                        
                        NavigationLink(destination: MoreToolsView(features: moreMenuItems, startIndex: moreMenuIndex + 1)) {
                             // Bruker en litt annen stil for å vise at dette er en undermeny
                            HStack {
                                Text("\(moreMenuIndex). ADDITIONAL TOOLS")
                                    .font(RetroTheme.font(size: 18, weight: .bold))
                                Spacer()
                                Image(systemName: "chevron.right.square.fill")
                            }
                            .padding()
                            .border(RetroTheme.primary, width: 1)
                            .foregroundColor(RetroTheme.primary)
                        }

                        Divider().background(RetroTheme.primary.opacity(0.5))
                            .padding(.vertical, 10)
                        
                        // 3. FASTE SYSTEM-VALG (Dev & Settings)
                        
                        // Jog Wheel Test (Beholder denne tilgjengelig for utvikling)
                        NavigationLink(destination: JogWheelTestContainer()) {
                            TerminalMenuItem(label: "DEV. JOG WHEEL TEST")
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            HStack {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                Text("MACHINE SETUP")
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

// Hjelpe-structs (Hvis du ikke vil flytte dem til egne filer enda)
struct TerminalMenuItem: View {
    // Endret fra LocalizedStringKey til String for å håndtere dynamisk tekst lettere
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

// Dev-container for testing av hjulet
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
