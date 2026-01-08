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
            
            // The Scanlines
            VStack(spacing: 0) {
                ForEach(0..<100, id: \.self) { _ in
                    Color.black.opacity(0.2)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                    Spacer().frame(height: 2)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false) // Let touches pass through
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
    @State private var pendingClear: Bool = false // Tracks if the text is "selected"
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("", text: $value)
                .focused($isFocused)
                .font(RetroTheme.font(size: 16, weight: .bold))
                // 1. Text Color: Cyan when selected, Green when typing
                .foregroundColor(pendingClear ? Color.cyan : RetroTheme.primary)
                // 2. Cursor Color: HIDDEN (Clear) when selected, Green when typing
                .tint(pendingClear ? .clear : RetroTheme.primary)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .frame(minWidth: 45)
                .padding(.vertical, 5)
                .background(Color.black)
                
                // --- GLOW & BORDER ---
                .overlay(
                    Rectangle()
                        .stroke(isFocused ? RetroTheme.primary : RetroTheme.primary.opacity(0.5),
                                lineWidth: isFocused ? 2 : 1)
                )
                .shadow(color: isFocused ? RetroTheme.primary.opacity(0.8) : .clear, radius: 8)
                
                // --- ACTIVATION LOGIC ---
                .onChange(of: isFocused) { _, focused in
                    if focused {
                        pendingClear = true
                    } else {
                        pendingClear = false
                    }
                }
                
                // --- TYPING LOGIC ---
                .onChange(of: value) { oldValue, newValue in
                    if isFocused && pendingClear {
                        if newValue != oldValue {
                            pendingClear = false
                            
                            if newValue.count > oldValue.count {
                                // User TYPED a new number -> Keep only new input
                                let newContent = String(newValue.dropFirst(oldValue.count))
                                value = newContent
                            } else {
                                // User hit BACKSPACE -> Clear everything
                                value = ""
                            }
                        }
                    }
                }

            Text(label)
                .font(RetroTheme.font(size: 10))
                .foregroundColor(isFocused ? RetroTheme.primary : RetroTheme.dim)
                .padding(.top, 4)
                .shadow(color: isFocused ? RetroTheme.primary.opacity(0.5) : .clear, radius: 4)
        }
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
