import SwiftUI

struct AcceleratedWideJogger: View {
    
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    
    // --- KONFIGURASJON ---
    private let friction: Double = 12.0
    private let spacing: CGFloat = 20
    private let visibleTicks: Int = 5
    
    // --- STATE ---
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    
    var body: some View {
        VStack {
            // Selve Hjulet (Sentrert)
            ZStack {
                // Bakgrunn (Rammen)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black) // Hjulet har sin egen bakgrunn
                    .frame(width: 220, height: 220) // Litt bredere ramme for å ramme inn
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(RetroTheme.dim, lineWidth: 1)
                    )
                    // "Flyte"-effekt: Kraftig skygge
                    .shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 10)
                
                // Trommel-visning (Klippes til rammen)
                GeometryReader { geo in
                    let midY = geo.size.height / 2
                    
                    ZStack {
                        ForEach(getVisibleIndices(), id: \.self) { index in
                            let distanceFromCenter = (CGFloat(index) - CGFloat(value / step)) * spacing
                            let yPos = midY - distanceFromCenter
                            
                            if yPos > -20 && yPos < geo.size.height + 20 {
                                HStack {
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
                .frame(width: 220, height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Senter-indikator (Glass-effekt)
                Rectangle()
                    .fill(RetroTheme.primary.opacity(0.1))
                    .frame(width: 220, height: 24)
                    .overlay(
                        Rectangle()
                            .stroke(RetroTheme.primary.opacity(0.5), lineWidth: 1)
                    )
                    .allowsHitTesting(false)
                
                // Shine / Refleksjon på kantene
                HStack {
                    LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 15)
                    Spacer()
                    LinearGradient(colors: [.clear, .white.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 15)
                }
                .frame(width: 220, height: 220)
                .allowsHitTesting(false)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            // --- GESTURE LOGIC ---
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let delta = gesture.translation.height - lastDragValue
                        dragOffset += delta
                        
                        let stepsToTake = Int(dragOffset / friction)
                        
                        if stepsToTake != 0 {
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
        .frame(maxWidth: .infinity) // Sikrer at hjulet midtstilles i forelderen
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
}
