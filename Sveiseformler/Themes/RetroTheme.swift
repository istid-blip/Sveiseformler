import SwiftUI

struct RetroTheme {
    // The Classic "Phosphor Green"
    static let primary = Color(red: 0.2, green: 1.0, blue: 0.3)
    // A dim version for placeholders
    static let dim = Color(red: 0.1, green: 0.4, blue: 0.1)
    // Deep black background
    static let background = Color.black
    
    // The standard terminal font
    static func font(size: CGFloat = 16, weight: Font.Weight = .medium) -> Font {
        return Font.system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Custom Modifiers

struct RetroBox: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(RetroTheme.background)
            .overlay(
                Rectangle()
                    .stroke(RetroTheme.primary, lineWidth: 2)
            )
    }
}

// --- THIS IS THE FIX ---
// Changed "ViewStyle" to "ButtonStyle"
struct RetroButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RetroTheme.font(size: 18, weight: .bold))
            // Text color logic
            .foregroundColor(configuration.isPressed ? RetroTheme.background : RetroTheme.primary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                // Background color logic: Invert when pressed
                configuration.isPressed ? RetroTheme.primary : RetroTheme.background
            )
            .overlay(
                Rectangle()
                    .stroke(RetroTheme.primary, lineWidth: 2)
            )
            // Optional: Scale effect for better feedback
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// A view modifier to add a "Scanline" effect over the screen
struct CRTOverlay: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            // Force background black everywhere
            RetroTheme.background.ignoresSafeArea()
            
            content
            
            // The Scanlines (Optimized with Canvas)
            Scanlines()
                .ignoresSafeArea()
                .allowsHitTesting(false) // Let touches pass through
        }
    }
}

// A highly optimized view that draws lines using the GPU
struct Scanlines: View {
    var body: some View {
        Canvas { context, size in
            // Tegn en linje hver 4. piksel (2px linje, 2px mellomrom)
            for y in stride(from: 0, to: size.height, by: 4) {
                let rect = CGRect(x: 0, y: y, width: size.width, height: 2)
                context.fill(Path(rect), with: .color(.black.opacity(0.2)))
            }
        }
    }
}

// Extension to make it easy to use
extension View {
    func retroStyle() -> some View {
        self.modifier(RetroBox())
    }
    
    func crtScreen() -> some View {
        self.modifier(CRTOverlay())
    }
}
// --- PASTE THIS AT THE BOTTOM OF RetroTheme.swift ---

// 1. The Standard History Row (Used in Carbon Equivalent & Dictionary)
struct RetroHistoryRow: View {
    let item: SavedCalculation
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(RetroTheme.font(size: 14, weight: .bold))
                Text(item.timestamp.formatted(date: .numeric, time: .shortened))
                    .font(RetroTheme.font(size: 10))
                    .opacity(0.7)
            }
            
            Spacer()
            
            Text(item.resultValue)
                .font(RetroTheme.font(size: 14, weight: .bold))
            
            // Delete Button
            Button(action: onDelete) {
                Text("[DEL]")
                    .font(RetroTheme.font(size: 12))
                    .foregroundColor(.red) // Red for danger
                    .padding(.leading, 10)
            }
        }
        .padding()
        .foregroundColor(RetroTheme.primary)
        .overlay(
            Rectangle().stroke(RetroTheme.dim, lineWidth: 1)
        )
    }
}
// --- ADD TO THE BOTTOM OF RetroTheme.swift ---

struct RetroEquationBox: View {
    let label: String
    @Binding var value: String
    
    @FocusState private var isFocused: Bool
    @State private var pendingClear: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("", text: $value)
                .focused($isFocused)
                .font(RetroTheme.font(size: 16, weight: .bold))
                // Forenklet fargebruk: Alltid primærfarge
                .foregroundColor(RetroTheme.primary)
                .tint(RetroTheme.primary)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .frame(minWidth: 45)
                .padding(.vertical, 5)
                // Solid svart bakgrunn er raskere å tegne
                .background(Color.black)
                
                // --- OPTIMALISERT RAMME (Ingen skygge) ---
                .overlay(
                    Rectangle()
                        // Kun enkel fargeendring, ingen glød/skygge
                        .stroke(isFocused ? RetroTheme.primary : RetroTheme.dim,
                                lineWidth: 1) // Konstant tykkelse er også raskere
                )
                
                // --- BEHOLD LOGIKKEN (Den er bra!) ---
                .onChange(of: isFocused) { _, focused in
                    if focused { pendingClear = true }
                }
                .onChange(of: value) { oldValue, newValue in
                    if isFocused && pendingClear {
                        if newValue != oldValue {
                            pendingClear = false
                            if newValue.count > oldValue.count {
                                // Bruker skrev noe nytt -> erstatt alt
                                let newContent = String(newValue.dropFirst(oldValue.count))
                                value = newContent
                            } else {
                                // Bruker trykket backspace -> slett alt
                                value = ""
                            }
                        }
                    }
                }

            Text(label)
                .font(RetroTheme.font(size: 10))
                .foregroundColor(isFocused ? RetroTheme.primary : RetroTheme.dim)
                .padding(.top, 4)
                // Fjernet shadow her også
        }
        // Fjernet scaleEffect og animation
    }
}
