//
//  RetroJogWheel.swift
//  Sveiseformler
//
//  Created by Frode Halrynjo on 12/01/2026.
//
import SwiftUI

struct RetroJogWheel: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    
    // Konfigurasjon
    private let friction: Double = 12.0
    private let barHeight: CGFloat = 4.0
    private let barSpacing: CGFloat = 20.0
    
    // State for bevegelse
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. BAKGRUNN (Mørk med grønnskjær)
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.black.opacity(0.9),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                // Grønn ramme rundt hjulet
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RetroTheme.primary.opacity(0.5), lineWidth: 1)
                )
                
                // 2. RILLER (Trommel-effekt med Retro-farger)
                VStack(spacing: barSpacing) {
                    let count = Int(geo.size.height / (barHeight + barSpacing)) + 5
                    ForEach(0..<count, id: \.self) { _ in
                        Capsule()
                            .fill(LinearGradient(
                                colors: [
                                    Color.black,
                                    RetroTheme.primary.opacity(0.7), // Lyser opp midten med retro-grønn
                                    Color.black
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: barHeight)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 10)
                            // Skygge/Glow effekt
                            .shadow(color: RetroTheme.primary.opacity(0.3), radius: 2, x: 0, y: 0)
                    }
                }
                .offset(y: (dragOffset.truncatingRemainder(dividingBy: barHeight + barSpacing)) - (barHeight + barSpacing))
                .mask(Rectangle())
                .allowsHitTesting(false)
                .drawingGroup()
                
                // 3. SKYGGER (Topp og bunn fade)
                VStack {
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: 50)
                    Spacer()
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 50)
                }
                .allowsHitTesting(false)
                
                // 4. TOUCH AREA
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let delta = gesture.translation.height - lastDragValue
                                dragOffset += delta
                                
                                let stepsToTake = Int(dragOffset / friction)
                                
                                if stepsToTake != 0 {
                                    // Adaptiv hastighet
                                    let velocity = abs(delta)
                                    var multiplier: Double = 1.0
                                    
                                    if velocity > 25 { multiplier = 10.0 }
                                    else if velocity > 10 { multiplier = 5.0 }
                                    else if velocity > 4 { multiplier = 2.0 }
                                    
                                    let direction: Double = -1.0
                                    let change = direction * Double(stepsToTake) * step * multiplier
                                    
                                    let newValue = value + change
                                    
                                    if range.contains(newValue) {
                                        value = (newValue * 100).rounded() / 100
                                        Haptics.selection()
                                    }
                                    
                                    dragOffset -= Double(stepsToTake) * friction
                                }
                                
                                lastDragValue = gesture.translation.height
                            }
                            .onEnded { _ in
                                lastDragValue = 0
                                dragOffset = 0
                            }
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            // Ytre glød
            .shadow(color: RetroTheme.primary.opacity(0.15), radius: 10, x: 0, y: -5)
        }
    }
}
