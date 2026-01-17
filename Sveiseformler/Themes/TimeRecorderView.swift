import SwiftUI
import Combine // Nødvendig for Timer-funksjonaliteten

struct TimeRecorderView: View {
    @Binding var value: Double // Tid i sekunder
    
    // --- STATE ---
    @State private var isRecording = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // For animasjon av rød prikk
    @State private var pulseOpacity = 1.0
    
    var body: some View {
        VStack {
            ZStack {
                // --- 1. BAKGRUNN ---
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
                    .frame(width: 320, height: 280)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(RetroTheme.dim, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 15)
                
                // --- 2. INNHOLD ---
                VStack(spacing: 20) {
                    
                    // Header
                    HStack {
                        Text("STOPWATCH")
                            .font(RetroTheme.font(size: 12, weight: .bold))
                            .foregroundColor(RetroTheme.dim)
                        
                        Spacer()
                        
                        // REC Indikator
                        if isRecording {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .opacity(pulseOpacity)
                                Text("REC")
                                    .font(RetroTheme.font(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    pulseOpacity = 0.3
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Tidsvisning (Stort tall)
                    Text(formattedTime)
                        .font(.system(size: 70, weight: .black, design: .monospaced))
                        .foregroundColor(isRecording ? .red : RetroTheme.primary)
                        .shadow(color: (isRecording ? Color.red : RetroTheme.primary).opacity(0.3), radius: 10)
                        .frame(width: 280)
                        .contentTransition(.numericText(value: value))
                    
                    Text("SECONDS")
                        .font(RetroTheme.font(size: 10, weight: .bold))
                        .foregroundColor(RetroTheme.dim)
                        .offset(y: -10)
                    
                    Spacer()
                    
                    // Kontrollknapper
                    HStack(spacing: 30) {
                        // RESET KNAPP
                        Button(action: {
                            value = 0
                            isRecording = false
                            Haptics.play(.medium)
                        }) {
                            VStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                Text("RESET")
                                    .font(RetroTheme.font(size: 9, weight: .bold))
                            }
                            .foregroundColor(RetroTheme.dim)
                            .frame(width: 80, height: 60)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1))
                        }
                        
                        // START / STOP KNAPP
                        Button(action: {
                            isRecording.toggle()
                            Haptics.play(.heavy)
                            if !isRecording {
                                // Når vi stopper, resett puls
                                pulseOpacity = 1.0
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isRecording ? Color.red.opacity(0.2) : RetroTheme.primary.opacity(0.2))
                                    .frame(width: 70, height: 70)
                                
                                Circle()
                                    .stroke(isRecording ? Color.red : RetroTheme.primary, lineWidth: 2)
                                    .frame(width: 70, height: 70)
                                
                                Image(systemName: isRecording ? "stop.fill" : "play.fill")
                                    .font(.title)
                                    .foregroundColor(isRecording ? .red : RetroTheme.primary)
                            }
                        }
                    }
                    .padding(.bottom, 30)
                }
                .frame(width: 320, height: 280)
            }
        }
        .frame(maxWidth: .infinity)
        // Timer Logic
        .onReceive(timer) { _ in
            if isRecording {
                value += 1
            }
        }
    }
    
    // Formatterer sekunder til 00-format
    var formattedTime: String {
        let seconds = Int(value)
        return String(format: "%02d", seconds)
    }
}
