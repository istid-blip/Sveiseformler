//
//  WideVerticalJogger.swift
//  Sveiseformler
//
//  Created by Frode Halrynjo on 13/01/2026.
//

import SwiftUI

// MARK: - 1. CONTAINER (Dette er siden som AppFeature åpner)
// Denne trenger ingen parametere, derfor forsvinner feilmeldingen din.
struct WideVerticalJogger: View {
    @State private var exampleValue: Double = 125.0 // Her bor dataene
    
    var body: some View {
        ZStack {
            RetroTheme.background.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 5) {
                    Text("WIDE VERTICAL JOGGER")
                        .font(RetroTheme.font(size: 20, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                    Text("COMPONENT TEST")
                        .font(RetroTheme.font(size: 12))
                        .foregroundColor(RetroTheme.dim)
                }
                .padding(.top, 20)
                
                Divider().background(RetroTheme.primary)
                
                // Her kaller vi på komponenten (hjulet) og sender med dataene våre
                WideJoggerComponent(
                    value: $exampleValue,
                    range: 0...300,
                    step: 1.0,
                    title: "AMPERE ADJUST"
                )
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("JOGGER")
    }
}

// MARK: - 2. KOMPONENT (Selve hjulet du limte inn)
// Jeg har døpt den om til "WideJoggerComponent" så den ikke krangler med navnet over.
struct WideJoggerComponent: View {
    
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    var title: String? = nil
    
    // --- KONFIGURASJON ---
    private let spacing: CGFloat = 20 // Avstand mellom strekene
    private let visibleTicks: Int = 5 // Hvor mange streker opp/ned som tegnes
    private let sensitivity: CGFloat = 25.0 // Hvor mange piksler drag for ett steg (Lavere = raskere)
    
    @State private var lastDragValue: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 15) {
            // Tittel (Valgfritt)
            if let title = title {
                Text(title)
                    .font(RetroTheme.font(size: 14))
                    .foregroundColor(RetroTheme.dim)
            }
            
            HStack(spacing: 20) {
                // 1. Selve Hjulet (Venstre side)
                ZStack {
                    // Bakgrunn
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black)
                        .frame(width: 200, height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(RetroTheme.dim, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 5)
                    
                    // Trommel-visning (Klippes til rammen)
                    GeometryReader { geo in
                        let midY = geo.size.height / 2
                        
                        ZStack {
                            // Vi tegner bare strekene som er synlige rundt nåværende verdi
                            ForEach(getVisibleIndices(), id: \.self) { index in
                                let distanceFromCenter = (CGFloat(index) - CGFloat(value / step)) * spacing
                                let yPos = midY - distanceFromCenter // Minus for å få høyere tall "oppe"
                                
                                // Bare tegn hvis innenfor rammen (med litt margin)
                                if yPos > -20 && yPos < geo.size.height + 20 {
                                    HStack {
                                        // Stor strek for heltal, liten for desimal
                                        Rectangle()
                                            .fill(RetroTheme.primary)
                                            .frame(width: isMajorTick(index) ? 80 : 40, height: 2)
                                    }
                                    .position(x: geo.size.width / 2, y: yPos)
                                    .opacity(calculateOpacity(yPos: yPos, height: geo.size.height))
                                    .scaleEffect(x: calculateScale(yPos: yPos, height: geo.size.height))
                                }
                            }
                        }
                    }
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Senter-indikator (Glass-effekt over midten)
                    Rectangle()
                        .fill(RetroTheme.primary.opacity(0.1))
                        .frame(width: 200, height: 24)
                        .overlay(
                            Rectangle()
                                .stroke(RetroTheme.primary.opacity(0.5), lineWidth: 1)
                        )
                    
                    // Shine / Refleksjon på kantene (for 3D effekt)
                    HStack {
                        LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 10)
                        Spacer()
                        LinearGradient(colors: [.clear, .white.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 10)
                    }
                    .frame(width: 200, height: 200)
                    .allowsHitTesting(false)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            handleDrag(translation: gesture.translation.height)
                        }
                        .onEnded { _ in
                            lastDragValue = 0
                        }
                )
                
                // 2. Verdi-visning (Høyre side)
                Text(String(format: "%.1f", value))
                    .font(RetroTheme.font(size: 32, weight: .bold))
                    .foregroundColor(RetroTheme.primary)
                    .frame(width: 100, alignment: .leading)
                    .shadow(color: RetroTheme.primary.opacity(0.3), radius: 5)
            }
        }
    }
    
    // --- HJELPEFUNKSJONER ---
    
    private func getVisibleIndices() -> [Double] {
        let centerIndex = value / step
        let start = Int(centerIndex) - visibleTicks - 2
        let end = Int(centerIndex) + visibleTicks + 2
        return (start...end).map { Double($0) }
    }
    
    private func isMajorTick(_ index: Double) -> Bool {
        return Int(index) % 5 == 0
    }
    
    private func calculateOpacity(yPos: CGFloat, height: CGFloat) -> Double {
        let center = height / 2
        let distance = abs(center - yPos)
        let threshold = height / 2 - 10
        if distance > threshold { return 0 }
        return Double(1 - (distance / threshold))
    }
    
    private func calculateScale(yPos: CGFloat, height: CGFloat) -> CGFloat {
        let center = height / 2
        let distance = abs(center - yPos)
        return 1.0 - (distance / height) * 0.3
    }
    
    private func handleDrag(translation: CGFloat) {
        let delta = translation - lastDragValue
        // Fjernet minuset her for Natural Scrolling (slik vi fikset tidligere)
        let change = (delta / sensitivity) * step
        
        let newValue = value + change
        
        if range.contains(newValue) {
            if Int(value) != Int(newValue) {
                Haptics.selection()
            }
            value = newValue
        }
        lastDragValue = translation
    }
}

#Preview {
    WideVerticalJogger()
}
