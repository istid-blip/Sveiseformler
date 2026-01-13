//
//  HorizontalScaleComponent.swift
//  Sveiseformler
//
//  Created by Frode Halrynjo on 12/01/2026.
//

import SwiftUI

struct HorizontalScaleComponent: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    
    // --- KONFIGURASJON ---
    private let tickSpacing: CGFloat = 10.0 // Avstand mellom hver minste strek
    private let majorTickInterval: Int = 10  // Hver 10. strek er stor
    private let midTickInterval: Int = 5     // Hver 5. strek er medium
    private let sensitivity: CGFloat = 0.5   // Justerer hvor fort den scroller (lavere = raskere)
    
    @State private var lastDragValue: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 1. Bakgrunn
            Rectangle()
                .fill(RetroTheme.background)
                .frame(height: 60)
                .overlay(
                    // Ramme oppe og nede
                    VStack {
                        Divider().background(RetroTheme.dim)
                        Spacer()
                        Divider().background(RetroTheme.dim)
                    }
                )
            
            // 2. Skala (Streker)
            GeometryReader { geo in
                let width = geo.size.width
                let midX = width / 2
                
                // Hvor mange streker får vi plass til?
                let ticksNeeded = Int(width / tickSpacing) / 2 + 2
                
                // Nåværende "base" verdi (avrundet til nærmeste step)
                let currentStepIndex = Int(value / step)
                
                // Vi tegner kun strekene som er synlige
                ForEach((currentStepIndex - ticksNeeded)...(currentStepIndex + ticksNeeded), id: \.self) { index in
                    
                    // Beregn posisjon: (Indeks * avstand) - (TotalOffset)
                    // TotalOffset er (Verdi / Step) * Avstand
                    let xOffset = (CGFloat(index) * tickSpacing) - (CGFloat(value / step) * tickSpacing)
                    let xPos = midX + xOffset
                    
                    // Tegn strek hvis den er innenfor viewet
                    if xPos > -10 && xPos < width + 10 {
                        // Bestem type strek
                        let isMajor = index % majorTickInterval == 0
                        let isMid = index % midTickInterval == 0
                        
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(isMajor ? RetroTheme.primary : RetroTheme.dim)
                                .frame(width: isMajor ? 2 : 1)
                                .frame(height: isMajor ? 35 : (isMid ? 25 : 15))
                        }
                        .position(x: xPos, y: 30) // 30 er midten av høyden (60)
                        .opacity(fadeEdges(xPos: xPos, width: width))
                    }
                }
            }
            .frame(height: 60)
            .clipShape(Rectangle())
            
            // 3. Senter-indikator (Nålen)
            VStack(spacing: 0) {
                // Pil ned
                Image(systemName: "triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(RetroTheme.primary)
                    .rotationEffect(.degrees(180))
                    .offset(y: 4)
                
                Rectangle()
                    .fill(RetroTheme.primary)
                    .frame(width: 2, height: 60)
                
                // Pil opp
                Image(systemName: "triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(RetroTheme.primary)
                    .offset(y: -4)
            }
            .shadow(color: RetroTheme.primary.opacity(0.5), radius: 5)
            
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80) // Total høyde inkludert piler
        // 4. Gestures
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    handleDrag(translation: gesture.translation.width)
                }
                .onEnded { _ in
                    lastDragValue = 0
                }
        )
    }
    
    // --- LOGIKK ---
    
    private func handleDrag(translation: CGFloat) {
        let delta = translation - lastDragValue
        
        // Formel: Endring = (Bevegelse * Følsomhet) * Steg
        // Minus foran delta for "Natural Scrolling" (Dra venstre -> Verdi øker, som på en linjal)
        // Hvis du vil ha "Slider"-følelse (Dra høyre -> Verdi øker), fjern minuset.
        let change = -(delta * sensitivity / tickSpacing) * step * 10
        // * 10 her for å matche tickSpacing visuelt, slik at 10px drag = 1 tick bevegelse ca.
        
        let newValue = value + change
        
        if range.contains(newValue) {
            // Haptisk feedback når vi passerer hele tall
            if Int(newValue) != Int(value) {
                Haptics.selection()
            }
            value = newValue
        }
        
        lastDragValue = translation
    }
    
    // Fader ut strekene på sidene for en penere look
    private func fadeEdges(xPos: CGFloat, width: CGFloat) -> Double {
        let edgeZone = width / 3
        if xPos < edgeZone {
            return Double(xPos / edgeZone)
        } else if xPos > width - edgeZone {
            return Double((width - xPos) / edgeZone)
        }
        return 1.0
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HorizontalScaleComponent(
            value: .constant(125.5),
            range: 0...200,
            step: 0.5
        )
    }
}
