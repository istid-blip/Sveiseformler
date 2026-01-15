//
//  MoreToolsView.swift
//  Sveiseformler
//
//  Created by Frode Halrynjo on 13/01/2026.
//

import SwiftUI

struct MoreToolsView: View {
    // Denne listen bestemmer hva som vises her inne
    var features: [AppFeature]
    
    // Vi starter nummereringen der hovedmenyen slapp (f.eks. på 3)
    var startIndex: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                
                // Header for undermenyen
                Text("ADDITIONAL TOOLS")
                    .font(RetroTheme.font(size: 14))
                    .foregroundColor(RetroTheme.primary)
                    .padding(.bottom, 10)
                
                Divider().background(RetroTheme.primary)
                    .padding(.bottom, 20)
                
                // Generer menyvalgene dynamisk
                ForEach(Array(features.enumerated()), id: \.element) { index, feature in
                    NavigationLink(destination: feature.destination) {
                        // Vi regner ut riktig nummer basert på start-indeksen
                        let number = startIndex + index
                        
                        // HER ER ENDRINGEN: Vi bruker nå index og titleKey separat
                        TerminalMenuItem(index: number, titleKey: feature.title)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .crtScreen() // Gjenbruker CRT-effekten
        .navigationTitle("EXTENDED MENU")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        ZStack {
            RetroTheme.background.ignoresSafeArea()
            MoreToolsView(features: [.schaeffler, .depositionRate], startIndex: 3)
        }
    }
}
