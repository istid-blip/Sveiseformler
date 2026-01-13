//
//  VerticalJogWheel.swift
//  Sveiseformler
//
//  Created by Frode Halrynjo on 12/01/2026.
//

import SwiftUI

struct VerticalJogWheel: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    var title: String? = nil
    
    // Konfigurasjon for utseende
    private let spacing: CGFloat = 20 // Avstand mellom strekene
    private let visibleTicks: Int = 5 // Hvor mange streker opp/ned som tegnes
    
    @State private var dragOffset: CGFloat = 0
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
                        .frame(width: 60, height: 200)
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
                                        // Stor strek for heltal, liten for desimal (hvis step < 1)
                                        Rectangle()
                                            .fill(RetroTheme.primary)
                                            .frame(width: isMajorTick(index) ? 30 : 15, height: 2)
                                    }
                                    .position(x: geo.size.width / 2, y: yPos)
                                    .opacity(calculateOpacity(yPos: yPos, height: geo.size.height))
                                    .scaleEffect(x: calculateScale(yPos: yPos, height: geo.size.height))
                                }
                            }
                        }
                    }
                    .frame(width: 60, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Senter-indikator (Glass-effekt over midten)
                    Rectangle()
                        .fill(RetroTheme.primary.opacity(0.1))
                        .frame(width: 58, height: 24)
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
                    .frame(width: 60, height: 200)
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
    
    // Beregner hvilke indekser (ticks) som skal tegnes basert på verdi
    private func getVisibleIndices() -> [Double] {
        let centerIndex = value / step
        let start = Int(centerIndex) - visibleTicks - 2
        let end = Int(centerIndex) + visibleTicks + 2
        
        return (start...end).map { Double($0) }
    }
    
    // Sjekker om streken skal være stor eller liten (f.eks. hver 5. eller 10.)
    private func isMajorTick(_ index: Double) -> Bool {
        return Int(index) % 5 == 0
    }
    
    // Regner ut gjennomsiktighet basert på avstand fra sentrum (fade-effekt)
    private func calculateOpacity(yPos: CGFloat, height: CGFloat) -> Double {
        let center = height / 2
        let distance = abs(center - yPos)
        let threshold = height / 2 - 10
        
        if distance > threshold { return 0 }
        return Double(1 - (distance / threshold))
    }
    
    // Gir en liten bue-effekt (skalering) på midten
    private func calculateScale(yPos: CGFloat, height: CGFloat) -> CGFloat {
        let center = height / 2
        let distance = abs(center - yPos)
        return 1.0 - (distance / height) * 0.3
    }
    
    // Håndterer selve dra-bevegelsen
    private func handleDrag(translation: CGFloat) {
        let delta = translation - lastDragValue
        
        // Følsomhet: Hvor mange pixler må man dra for å flytte ett steg?
        let sensitivity: CGFloat = 10.0 // Lavere tall = raskere hjul
        
        // Minus delta fordi: Dra NED (positiv Y) skal øke verdien (få strekene til å gå nedover)
        // ELLER: Dra NED trekker "tapen" ned, som betyr at vi ser høyere tall komme ovenfra?
        // Standard scrolling: Dra NED = Beveger innhold NED -> Vi ser lavere tall (hvis toppen er lavest).
        // La oss justere slik at det føles naturlig: Opp = Øk verdi.
        
        let change = (delta / sensitivity) * step
        
        let newValue = value + change
        
        if range.contains(newValue) {
            // Haptic feedback ved passering av hele tall
            if Int(value) != Int(newValue) {
                Haptics.selection()
            }
            value = newValue
        }
        
        lastDragValue = translation
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        RetroTheme.background.ignoresSafeArea()
        VerticalJogWheel(
            value: .constant(50),
            range: 0...100,
            step: 1,
            title: "VERTICAL DRUM"
        )
    }
}
