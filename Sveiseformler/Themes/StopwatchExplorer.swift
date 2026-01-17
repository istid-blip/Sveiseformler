import SwiftUI
import Combine

struct StopwatchDesignExplorer: View {
    // --- STATE ---
    @State private var value: Double = 0.0
    @AppStorage("is_recording_test") private var isRecording = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // --- ANIMASJON (Kjører på GPU) ---
    @State private var pulseAmount: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Hovedcontainer
            VStack(spacing: 40) {
                
                // Status-tekst øverst
                Text(isRecording ? "SYSTEM ACTIVE" : "READY TO RECORD")
                    .font(RetroTheme.font(size: 14, weight: .black))
                    .foregroundColor(isRecording ? .red : RetroTheme.dim)
                    .tracking(2)
                
                // --- DEN STORE RØDE KNAPPEN ---
                Button(action: toggleAction) {
                    ZStack {
                        // 1. YTRE GLØD (Aura)
                        Circle()
                            .fill(Color.red.opacity(isRecording ? 0.3 : 0.0))
                            .frame(width: 260, height: 260)
                            .scaleEffect(pulseAmount + 0.1) // Litt større enn knappen
                            .blur(radius: isRecording ? 20 : 0)
                        
                        // 2. SELVE KNAPPEN
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [isRecording ? .red : Color(white: 0.1), .black],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 220, height: 220)
                            // En rød ring rundt når aktiv
                            .overlay(
                                Circle()
                                    .stroke(isRecording ? Color.red : RetroTheme.dim, lineWidth: 6)
                            )
                            // Kraftig skygge nedover for dybde
                            .shadow(color: isRecording ? .red.opacity(0.5) : .black, radius: 15, x: 0, y: 10)
                        
                        // 3. INNHOLD I KNAPPEN
                        VStack(spacing: 8) {
                            if isRecording {
                                // Tidsvisning
                                Text(String(format: "%02d", Int(value)))
                                    .font(.system(size: 80, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                    .contentTransition(.numericText(value: value))
                                
                                Text("SECONDS")
                                    .font(RetroTheme.font(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                            } else {
                                // Start-ikon
                                Image(systemName: "play.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(RetroTheme.primary)
                                
                                Text("START")
                                    .font(RetroTheme.font(size: 18, weight: .black))
                                    .foregroundColor(RetroTheme.primary)
                            }
                        }
                    }
                    .scaleEffect(isRecording ? pulseAmount : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                
                // --- RESET KNAPP ---
                Button(action: resetAction) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("RESET TIMER")
                    }
                    .font(RetroTheme.font(size: 12, weight: .bold))
                    .foregroundColor(RetroTheme.dim)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.black)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1))
                }
                .opacity(value > 0 && !isRecording ? 1.0 : 0.2)
                .disabled(isRecording || value == 0)
                
            }
        }
        .onReceive(timer) { _ in
            if isRecording { value += 1 }
        }
        // Når isRecording endres, starter vi "pustingen"
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseAmount = 1.05
                }
            } else {
                withAnimation(.spring()) {
                    pulseAmount = 1.0
                }
            }
        }
    }
    
    func toggleAction() {
        isRecording.toggle()
        Haptics.play(.heavy)
    }
    
    func resetAction() {
        value = 0
        isRecording = false
        Haptics.play(.medium)
    }
}
