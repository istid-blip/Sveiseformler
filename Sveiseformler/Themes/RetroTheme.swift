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
