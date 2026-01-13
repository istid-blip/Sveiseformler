//
//  JogWheelView.swift
//  Sveiseformler
//
//  Created by Frode Halrynjo on 12/01/2026.
//

import SwiftUI

struct JogWheelView: View {
    var title: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...100
    var step: Double = 1.0
    
    // Vi bruker separate variabler for å teste de to hjulene uavhengig
    @State private var valueStyle1: Double
    @State private var valueStyle2: Double
    
    init(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        
        // Initierer de interne test-verdiene med startverdien
        self._valueStyle1 = State(initialValue: value.wrappedValue)
        self._valueStyle2 = State(initialValue: value.wrappedValue)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                
                // HEADER
                VStack(spacing: 5) {
                    Text(title)
                        .font(RetroTheme.font(size: 20, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                    Text("DESIGN EXPERIMENTS")
                        .font(RetroTheme.font(size: 12))
                        .foregroundColor(RetroTheme.dim)
                }
                .padding(.top, 20)
                
                Divider().background(RetroTheme.primary)
                
                // --- DESIGN 1: RETRO DASHED ---
                VStack(spacing: 15) {
                    Text("OPTION A: RETRO DASH")
                        .font(RetroTheme.font(size: 14))
                        .foregroundColor(RetroTheme.dim)
                    
                    RetroWheelComponent(value: $valueStyle1, range: range, step: step)
                }
                
                Divider().background(RetroTheme.dim.opacity(0.3))
                
                // --- DESIGN 2: PRECISION KNOB ---
                VStack(spacing: 15) {
                    Text("OPTION B: PRECISION KNOB")
                        .font(RetroTheme.font(size: 14))
                        .foregroundColor(RetroTheme.dim)
                    
                    PrecisionKnobComponent(value: $valueStyle2, range: range, step: step)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(RetroTheme.background)
        .onAppear {
            // Synk initielle verdier
            valueStyle1 = value
            valueStyle2 = value
        }
        .onChange(of: valueStyle1) {oldvalue, newValue in value = newValue }
        .onChange(of: valueStyle2) {oldvalue, newValue in value = newValue }
    }
}

// MARK: - COMPONENT 1: Retro Dashed Wheel (Den gamle)
struct RetroWheelComponent: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    
    @State private var rotation: Double = 0
    @State private var lastDragAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Verdi-display
            Text(String(format: "%.1f", value))
                .font(RetroTheme.font(size: 24, weight: .bold))
                .foregroundColor(RetroTheme.primary)
                .frame(width: 120, height: 50)
                .background(Color.black)
                .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 2))
            
            ZStack {
                // Ytre ring
                Circle()
                    .stroke(RetroTheme.dim.opacity(0.5), lineWidth: 2)
                    .frame(width: 160, height: 160)
                
                // Roterende stiplet hjul
                Circle()
                    .stroke(RetroTheme.primary, style: StrokeStyle(lineWidth: 12, dash: [3, 6]))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(rotation))
                
                // Indikator
                Rectangle()
                    .fill(RetroTheme.primary)
                    .frame(width: 4, height: 20)
                    .offset(y: -70) // Låst til toppen (statisk indikator)
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        handleDrag(location: gesture.location)
                    }
            )
        }
    }
    
    private func handleDrag(location: CGPoint) {
        // Sentrum av sirkelen er (80, 80) siden rammen er 160x160.
        // Men i en ZStack er sentrum (0,0) relativt til viewet hvis vi bruker global coordinater,
        // så her forenkler vi ved å anta at trykket skjer relativt til viewets bounds.
        // Enklere: Vi beregner vinkel ut fra sentrum av viewet.
        
        let vector = CGVector(dx: location.x - 80, dy: location.y - 80)
        let angle = atan2(vector.dy, vector.dx) * 180 / .pi
        
        let angleDiff = angle - lastDragAngle
        
        // Vi roterer hjulet visuelt
        rotation = angle + 90
        
        // Beregn verdiendring
        // Hvis vi drar med klokka (positiv vinkelendring), øker verdien
        if abs(angleDiff) < 50 { // Ignorer store hopp (ved 180/-180 overgang)
             let newValue = value + (angleDiff > 0 ? step : -step)
             if range.contains(newValue) {
                 value = newValue
                 Haptics.selection()
             }
        }
        
        lastDragAngle = angle
    }
}

// MARK: - COMPONENT 2: Precision Knob (Den nye)
struct PrecisionKnobComponent: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    
    @State private var rotation: Double = 0
    @State private var lastDragAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Verdi-display (Litt mer diskret stil)
            HStack {
                Text("VALUE:")
                    .font(RetroTheme.font(size: 14))
                    .foregroundColor(RetroTheme.dim)
                Text(String(format: "%.1f", value))
                    .font(RetroTheme.font(size: 24, weight: .bold)) // Monospaced tall
                    .foregroundColor(RetroTheme.primary)
            }
            .padding(10)
            .background(Color.black.opacity(0.5))
            .cornerRadius(5)
            
            ZStack {
                // Bakgrunnsskala (Tick marks rundt)
                ForEach(0..<20) { i in
                    Rectangle()
                        .fill(RetroTheme.dim)
                        .frame(width: 2, height: 10)
                        .offset(y: -95)
                        .rotationEffect(.degrees(Double(i) * (360.0 / 20.0)))
                }
                
                // Selve knotten (Solid)
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.black]),
                            center: .center,
                            startRadius: 5,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle().stroke(RetroTheme.dim, lineWidth: 1)
                    )
                    .shadow(color: .black, radius: 10, x: 5, y: 5)
                
                // Indikatorstrek på knotten (Roterer)
                Rectangle()
                    .fill(RetroTheme.primary)
                    .frame(width: 4, height: 35)
                    .offset(y: -50) // Flyttet ut mot kanten
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: RetroTheme.primary.opacity(0.8), radius: 5) // "Glow" effekt
                
                // Sentrum av knotten
                Circle()
                    .fill(Color.black)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(RetroTheme.dim, lineWidth: 1))
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let vector = CGVector(dx: gesture.location.x - 80, dy: gesture.location.y - 80)
                        let angle = atan2(vector.dy, vector.dx) * 180 / .pi
                        
                        let angleDiff = angle - lastDragAngle
                        rotation = angle + 90
                        
                        // Følsomhet: Endre verdi basert på vinkel
                        if abs(angleDiff) < 50 {
                            let newValue = value + (angleDiff > 0 ? step : -step)
                            if range.contains(newValue) {
                                value = newValue
                                Haptics.selection()
                            }
                        }
                        lastDragAngle = angle
                    }
            )
        }
    }
}

// MARK: - Preview
#Preview {
    JogWheelView(
        title: "TEST CONTROL",
        value: .constant(125.0),
        range: 0...200,
        step: 1.0
    )
}
