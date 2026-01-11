import SwiftUI
import SwiftData

// MARK: - Core Theme Definitions
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

// MARK: - View Modifiers

// A generic retro box border
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
                context.fill(Path(rect), with: .color(.black.opacity(0.1)))
            }
        }
    }
}

// MARK: - Button Styles

struct RetroButton: ButtonStyle { // Blir denne structen brukt noen plass?
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RetroTheme.font(size: 18, weight: .bold))
            .foregroundColor(configuration.isPressed ? RetroTheme.background : RetroTheme.primary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                configuration.isPressed ? RetroTheme.primary : RetroTheme.background
            )
            .overlay(
                Rectangle()
                    .stroke(RetroTheme.primary, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    Haptics.play(.light) // NYTT: Bruker Haptics service
                }
            }
    }
}



// MARK: - Extensions

extension View {
    func retroStyle() -> some View {
        self.modifier(RetroBox())
    }
    
    func crtScreen() -> some View {
        self.modifier(CRTOverlay())
    }
}

// MARK: - Specialized Retro Components

// Erstatt den gamle RetroHistoryRow i RetroTheme.swift med denne:

struct RetroHistoryRow: View {
    let item: SavedCalculation
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Navn og Dato
                HStack {
                    Text(item.name)
                        .font(RetroTheme.font(size: 16, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                    
                    Spacer()
                    
                    Text(item.timestamp, format: .dateTime.day().month().hour().minute())
                        .font(RetroTheme.font(size: 10))
                        .foregroundColor(RetroTheme.dim)
                }
                
                // VISER DETALJENE HVIS DE FINNES (NY KODE)
                if let v = item.voltage, let i = item.amperage, let t = item.travelTime, let l = item.weldLength {
                    HStack(spacing: 10) {
                        detailText(label: "U:", value: "\(v)V")
                        detailText(label: "I:", value: "\(Int(i))A")
                        detailText(label: "t:", value: "\(Int(t))s")
                        detailText(label: "L:", value: "\(Int(l))mm")
                    }
                }
            }
            
            Spacer()
            
            // Resultat
            VStack(alignment: .trailing) {
                Text(item.resultValue)
                    .font(RetroTheme.font(size: 18, weight: .heavy))
                    .foregroundColor(RetroTheme.primary)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(RetroTheme.dim)
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .overlay(Rectangle().stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1))
        .background(Color.black.opacity(0.3))
    }
    
    // Hjelpefunksjon for små detaljer
    func detailText(label: String, value: String) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(RetroTheme.font(size: 10))
                .foregroundColor(RetroTheme.dim)
            Text(value)
                .font(RetroTheme.font(size: 10))
                .foregroundColor(RetroTheme.primary)
        }
    }
}

// 2. Custom Input Box with Smart Focus Logic
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
                                lineWidth: 1)
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
        }
    }
}

// 3. Retro Rolling Picker Components

// 3a. Selve knappen man trykker på for å åpne hjulet
struct RollingInputButton: View {
    let label: String
    let value: Double
    var precision: Int = 1
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            Haptics.play(.light) // NYTT
        }) {
            VStack(spacing: 0) {
                Text(String(format: "%.\(precision)f", value))
                    .font(RetroTheme.font(size: 18, weight: .bold))
                    .foregroundColor(RetroTheme.primary)
                    .padding(.vertical, 8)
                    .frame(minWidth: 60)
                    .background(Color.black)
                    // Enkel ramme (raskere enn glød/skygge)
                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                
                Text(label)
                    .font(RetroTheme.font(size: 10))
                    .foregroundColor(RetroTheme.dim)
                    .padding(.top, 4)
            }
        }
    }
}

// 3b. Popup-arket med hjulet (Picker)
struct RollingPickerSheet: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Bakgrunn
            Color.black.ignoresSafeArea()
            
            VStack {
                // Header med tittel og Done-knapp
                HStack {
                    Text(title)
                        .font(RetroTheme.font(size: 16, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                    Spacer()
                    Button("DONE") {
                        onDismiss()
                    }
                    .font(RetroTheme.font(size: 14, weight: .bold))
                    .foregroundColor(RetroTheme.primary)
                    .padding(8)
                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                }
                .padding()
                
                Spacer()
                
                // Selve hjulet
                Picker("Value", selection: $value) {
                    ForEach(Array(stride(from: range.lowerBound, through: range.upperBound, by: step)), id: \.self) { num in
                        Text(String(format: step < 1 ? "%.1f" : "%.0f", num))
                            .font(RetroTheme.font(size: 35, weight: .bold))
                            .foregroundColor(RetroTheme.primary)
                            .tag(num)
                    }
                }
                .pickerStyle(.wheel)
                .colorScheme(.dark) // Tvinger mørk modus på hjulet
                
                Spacer()
            }
        }
        .presentationDetents([.height(350)]) // Dekker bare nedre del av skjermen
        .presentationDragIndicator(.visible)
    }
}


struct RetroDropdown<T: Identifiable & Equatable>: View {
    let title: String
    let selection: T
    let options: [T]
    let onSelect: (T) -> Void
    let itemText: (T) -> String
    let itemDetail: ((T) -> String)?
    
    @State private var isExpanded = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
            if isExpanded {
                Haptics.play(.light)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(itemText(selection))
                        .font(RetroTheme.font(size: 16, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if let detail = itemDetail?(selection) {
                        HStack {
                            Text(detail)
                                .font(RetroTheme.font(size: 9))
                            Spacer()
                            Text(isExpanded ? "▲" : "▼")
                                .font(RetroTheme.font(size: 10))
                        }
                        .foregroundColor(RetroTheme.dim)
                    }
                }
            }
            .padding(10)
            .background(Color.black)
            .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1.5))
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(RetroTheme.primary)
        // Her er selve listen som flyter over
        .overlay(
            GeometryReader { geo in
                if isExpanded {
                    VStack(spacing: 0) {
                        ForEach(options) { option in
                            Button(action: {
                                onSelect(option)
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    isExpanded = false
                                }
                            }) {
                                HStack {
                                    Text(itemText(option))
                                        .font(RetroTheme.font(size: 14))
                                        .foregroundColor(option == selection ? Color.black : RetroTheme.primary)
                                    
                                    Spacer()
                                    
                                    if let detail = itemDetail?(option) {
                                        Text(detail)
                                            .font(RetroTheme.font(size: 10))
                                            .foregroundColor(option == selection ? Color.black.opacity(0.8) : RetroTheme.dim)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 10)
                                .background(option == selection ? RetroTheme.primary : Color.black)
                            }
                            .overlay(
                                Rectangle().frame(height: 1).foregroundColor(RetroTheme.dim.opacity(0.3)),
                                alignment: .bottom
                            )
                        }
                    }
                    .background(Color.black)
                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1.5))
                    .frame(width: geo.size.width)
                    .offset(y: geo.size.height + 5) // Flytter listen rett under knappen
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 10)
                }
            }
        )
        // VIKTIG: Dette sier at hvis listen er åpen, skal denne knappen tegnes OVER alt annet
        .zIndex(isExpanded ? 100 : 1)
    }
}

// En blinkende effekt for "Recording"-indikatorer etc.
struct BlinkModifier: ViewModifier {
    @State private var isOn = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isOn ? 1.0 : 0.3) // Blinker mellom full og lav synlighet
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isOn = true
                }
            }
    }
}

extension View {
    func blinkEffect() -> some View {
        self.modifier(BlinkModifier())
    }
}

// MARK: - VERTICAL RETRO JOG WHEEL

// MARK: - VERTICAL RETRO JOG WHEEL (Industrial Design)

struct RetroJogWheel: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    var title: String // Brukes ikke visuelt inni hjulet, men med i API
    
    // Konfigurasjon
    private let friction: Double = 12.0
    private let barHeight: CGFloat = 4.0
    private let barSpacing: CGFloat = 20.0
    
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. BAKGRUNN (Mørk Gummi/Metall-look)
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(white: 0.15),
                        Color(white: 0.2), // Lysere midtparti (highlight)
                        Color(white: 0.15),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .overlay(
                    // Legg på litt støy/tekstur hvis mulig, eller bare en svak ramme
                    Rectangle().stroke(Color(white: 0.3), lineWidth: 1)
                )
                
                // 2. RILLER (De bevegelige delene)
                VStack(spacing: barSpacing) {
                    let count = Int(geo.size.height / (barHeight + barSpacing)) + 5
                    ForEach(0..<count, id: \.self) { _ in
                        // Hver rille ser ut som et innhugg
                        Capsule()
                            .fill(LinearGradient(
                                colors: [.black, Color(white: 0.4), .black],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: barHeight)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 10) // Litt innrykk på rillene
                            .opacity(0.8)
                    }
                }
                .offset(y: (dragOffset.truncatingRemainder(dividingBy: barHeight + barSpacing)) - (barHeight + barSpacing))
                .mask(Rectangle())
                .allowsHitTesting(false)
                
                // 3. SKYGGER (Vignette for dybde oppe og nede)
                VStack {
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: 60)
                    Spacer()
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 60)
                }
                .allowsHitTesting(false)
                
                // 4. TOUCH AREA (Usynlig, men fanger bevegelser)
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let delta = gesture.translation.height - lastDragValue
                                dragOffset += delta
                                
                                // Rask bevegelse = større hopp
                                let multiplier: Double = abs(delta) > 15 ? 5.0 : 1.0
                                let effectiveStep = step * multiplier
                                
                                if abs(dragOffset) > friction {
                                    // Dra NED = Reduser verdi. Dra OPP = Øk verdi.
                                    let direction: Double = delta > 0 ? -1 : 1
                                    let newValue = value + (direction * effectiveStep)
                                    
                                    if range.contains(newValue) {
                                        value = (newValue * 100).rounded() / 100
                                        Haptics.selection()
                                    }
                                }
                                lastDragValue = gesture.translation.height
                            }
                            .onEnded { _ in
                                lastDragValue = 0
                            }
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: -5)
        }
    }
}
