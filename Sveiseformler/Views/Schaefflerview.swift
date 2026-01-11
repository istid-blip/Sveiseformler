import SwiftUI

// --- DATAMODELL (Uendret) ---
struct StainlessGrade: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let cr: String
    let mo: String
    let si: String
    let nb: String
    let ni: String
    let c: String
    let mn: String
    
    static let defaults: [StainlessGrade] = [
        StainlessGrade(name: "Select Grade...", description: "Custom values", cr: "0", mo: "0", si: "0", nb: "0", ni: "0", c: "0", mn: "0"),
        StainlessGrade(name: "304 / 1.4301", description: "Standard Austenitic", cr: "18.5", mo: "0.0", si: "0.5", nb: "0.0", ni: "9.0", c: "0.04", mn: "1.5"),
        StainlessGrade(name: "316L / 1.4404", description: "Marine / Acid Proof", cr: "17.0", mo: "2.2", si: "0.5", nb: "0.0", ni: "11.5", c: "0.02", mn: "1.5"),
        StainlessGrade(name: "309S / 1.4833", description: "High Temperature", cr: "23.0", mo: "0.0", si: "0.8", nb: "0.0", ni: "13.0", c: "0.06", mn: "1.5"),
        StainlessGrade(name: "310S / 1.4845", description: "High Temperature", cr: "25.0", mo: "0.0", si: "1.0", nb: "0.0", ni: "20.0", c: "0.05", mn: "1.5"),
        StainlessGrade(name: "Duplex 2205", description: "Ferritic-Austenitic", cr: "22.5", mo: "3.2", si: "0.4", nb: "0.0", ni: "5.5", c: "0.02", mn: "1.5"),
        StainlessGrade(name: "410 / 1.4006", description: "Martensitic", cr: "12.5", mo: "0.0", si: "0.4", nb: "0.0", ni: "0.5", c: "0.12", mn: "0.8")
    ]
}

struct SchaefflerView: View {
    @Environment(\.dismiss) var dismiss
    
    // --- STATE ---
    @State private var selectedGrade: StainlessGrade = StainlessGrade.defaults[0]
    
    enum InputTarget: String, Identifiable {
        case cr, mo, si, nb
        case ni, c, mn
        var id: String { rawValue }
    }
    @State private var focusedField: InputTarget? = nil
    
    // Input Variabler
    @State private var cr: Double = 0.0
    @State private var mo: Double = 0.0
    @State private var si: Double = 0.0
    @State private var nb: Double = 0.0
    
    @State private var ni: Double = 0.0
    @State private var c: Double = 0.0
    @State private var mn: Double = 0.0
    
    // --- BEREGNINGER ---
    var crEquivalent: Double {
        return cr + mo + (1.5 * si) + (0.5 * nb)
    }
    
    var niEquivalent: Double {
        return ni + (30 * c) + (0.5 * mn)
    }
    
    var body: some View {
        ZStack {
            RetroTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- HEADER ---
                HStack {
                    Button(action: { dismiss() }) {
                        Text("< MENU")
                            .font(RetroTheme.font(size: 14, weight: .bold))
                            .foregroundColor(RetroTheme.primary)
                            .padding(8)
                            .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                    Spacer()
                    Text("SCHAEFFLER CALC")
                        .font(RetroTheme.font(size: 16, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                }
                .padding()
                .zIndex(1)
                
                ZStack(alignment: .bottom) {
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            
                            // --- 1. RESULTAT SEKSJON (Flyttet øverst) ---
                            VStack(spacing: 20) {
                                Text("CALCULATED EQUIVALENTS")
                                    .font(RetroTheme.font(size: 10, weight: .bold))
                                    .foregroundColor(RetroTheme.dim)
                                
                                HStack(spacing: 40) {
                                    ResultDisplay(label: "Cr-eq", value: crEquivalent)
                                    ResultDisplay(label: "Ni-eq", value: niEquivalent)
                                }
                                
                                // Formel visning
                                VStack(spacing: 5) {
                                    Text("Cr-eq = %Cr + %Mo + 1.5×%Si + 0.5×%Nb")
                                    Text("Ni-eq = %Ni + 30×%C + 0.5×%Mn")
                                }
                                .font(RetroTheme.font(size: 9))
                                .foregroundColor(RetroTheme.dim)
                                .multilineTextAlignment(.center)
                                
                                Rectangle().fill(RetroTheme.dim).frame(height: 1).padding(.horizontal)
                            }
                            .padding(.top, 10)
                            .zIndex(1)
                            
                            // --- 2. INPUT GRIDS (Midten) ---
                            HStack(alignment: .top, spacing: 20) {
                                
                                // VENSTRE: Ferrittdannere
                                VStack(spacing: 15) {
                                    Text("FERRITE FORMERS")
                                        .font(RetroTheme.font(size: 10, weight: .bold))
                                        .foregroundColor(RetroTheme.dim)
                                    
                                    SchaefflerInput(label: "Cr %", value: cr, target: .cr, currentFocus: focusedField) { focusedField = .cr }
                                    SchaefflerInput(label: "Mo %", value: mo, target: .mo, currentFocus: focusedField) { focusedField = .mo }
                                    SchaefflerInput(label: "Si %", value: si, target: .si, currentFocus: focusedField) { focusedField = .si }
                                    SchaefflerInput(label: "Nb %", value: nb, target: .nb, currentFocus: focusedField) { focusedField = .nb }
                                }
                                
                                // HØYRE: Austenittdannere
                                VStack(spacing: 15) {
                                    Text("AUSTENITE FORMERS")
                                        .font(RetroTheme.font(size: 10, weight: .bold))
                                        .foregroundColor(RetroTheme.dim)
                                    
                                    SchaefflerInput(label: "Ni %", value: ni, target: .ni, currentFocus: focusedField) { focusedField = .ni }
                                    SchaefflerInput(label: "C %", value: c, target: .c, currentFocus: focusedField, precision: 2) { focusedField = .c }
                                    SchaefflerInput(label: "Mn %", value: mn, target: .mn, currentFocus: focusedField) { focusedField = .mn }
                                    
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                            .zIndex(1)

                            // --- 3. GRADE SELECTOR (Flyttet ned) ---
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("PRESET GRADE")
                                        .font(RetroTheme.font(size: 10, weight: .bold))
                                        .foregroundColor(RetroTheme.dim)
                                    
                                    RetroDropdown(
                                        title: "GRADE",
                                        selection: selectedGrade,
                                        options: StainlessGrade.defaults,
                                        onSelect: { grade in selectGrade(grade) },
                                        itemText: { $0.name },
                                        itemDetail: { $0.description }
                                    )
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            .zIndex(100) // Z-index 100 sikrer at den åpnes over Reset-knappen
                            
                            
                            // --- 4. RESET ---
                            Button(action: resetFields) {
                                Text("RESET VALUES")
                                    .font(RetroTheme.font(size: 14, weight: .bold))
                                    .foregroundColor(RetroTheme.background)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(RetroTheme.dim)
                                    .overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 320) // Plass til hjulet
                            .zIndex(0)
                        }
                    }
                    
                    // --- TROMMEL OVERLAY ---
                    if let target = focusedField {
                        VStack(spacing: 0) {
                            HStack {
                                Text(title(for: target))
                                    .font(RetroTheme.font(size: 12, weight: .bold))
                                    .foregroundColor(RetroTheme.primary)
                                    .padding(.leading)
                                Spacer()
                                Button(action: { withAnimation { focusedField = nil } }) {
                                    Image(systemName: "chevron.down")
                                        .font(.title3)
                                        .foregroundColor(RetroTheme.dim)
                                }
                                .padding(.trailing)
                                .padding(.vertical, 10)
                            }
                            .background(Color.black)
                            .overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1).frame(height: 1), alignment: .top)

                            RetroJogWheel(
                                value: binding(for: target),
                                range: range(for: target),
                                step: step(for: target),
                                title: ""
                            )
                            .frame(height: 300)
                        }
                        .background(Color.black)
                        .transition(.move(edge: .bottom))
                        .zIndex(200)
                        .onTapGesture { }
                    }
                }
            }
        }
        .crtScreen()
        .onTapGesture {
            if focusedField != nil {
                withAnimation { focusedField = nil }
            }
        }
        .navigationBarHidden(true)
    }
    
    // --- LOGIKK ---
    
    func selectGrade(_ grade: StainlessGrade) {
        selectedGrade = grade
        if grade.name != "Select Grade..." {
            cr = Double(grade.cr) ?? 0.0
            mo = Double(grade.mo) ?? 0.0
            si = Double(grade.si) ?? 0.0
            nb = Double(grade.nb) ?? 0.0
            ni = Double(grade.ni) ?? 0.0
            c = Double(grade.c) ?? 0.0
            mn = Double(grade.mn) ?? 0.0
            Haptics.play(.medium)
        }
    }
    
    func resetFields() {
        withAnimation {
            selectedGrade = StainlessGrade.defaults[0]
            cr = 0; mo = 0; si = 0; nb = 0
            ni = 0; c = 0; mn = 0
            Haptics.play(.medium)
        }
    }
    
    func binding(for field: InputTarget) -> Binding<Double> {
        switch field {
        case .cr: return $cr
        case .mo: return $mo
        case .si: return $si
        case .nb: return $nb
        case .ni: return $ni
        case .c:  return $c
        case .mn: return $mn
        }
    }
    
    func range(for field: InputTarget) -> ClosedRange<Double> {
        switch field {
        case .c: return 0...2.0
        case .cr: return 0...40.0
        case .ni: return 0...40.0
        default: return 0...10.0
        }
    }
    
    func step(for field: InputTarget) -> Double {
        switch field {
        case .c: return 0.01
        default: return 0.1
        }
    }
    
    func title(for field: InputTarget) -> String {
        switch field {
        case .cr: return "CHROMIUM (Cr %)"
        case .mo: return "MOLYBDENUM (Mo %)"
        case .si: return "SILICON (Si %)"
        case .nb: return "NIOBIUM (Nb %)"
        case .ni: return "NICKEL (Ni %)"
        case .c:  return "CARBON (C %)"
        case .mn: return "MANGANESE (Mn %)"
        }
    }
    
    @ViewBuilder
    func SchaefflerInput(label: String, value: Double, target: InputTarget, currentFocus: InputTarget?, precision: Int = 1, action: @escaping () -> Void) -> some View {
        let isSelected = (currentFocus == target)
        let isDimmed = (currentFocus != nil && !isSelected)
        let borderColor = isDimmed ? RetroTheme.dim : RetroTheme.primary
        let textColor = isDimmed ? RetroTheme.dim : RetroTheme.primary
        
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                action()
                Haptics.selection()
            }
        }) {
            VStack(spacing: 0) {
                Text(String(format: "%.\(precision)f", value))
                    .font(RetroTheme.font(size: 18, weight: .bold))
                    .foregroundColor(textColor)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .overlay(Rectangle().stroke(borderColor, lineWidth: isSelected ? 2 : 1))
                
                Text(label)
                    .font(RetroTheme.font(size: 10))
                    .foregroundColor(RetroTheme.dim)
                    .padding(.top, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Resultatvisning
struct ResultDisplay: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(RetroTheme.font(size: 12))
                .foregroundColor(RetroTheme.dim)
            
            Text(String(format: "%.2f", value))
                .font(RetroTheme.font(size: 32, weight: .black))
                .foregroundColor(RetroTheme.primary)
                .padding(10)
                .background(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(RetroTheme.primary, lineWidth: 2)
                )
                .shadow(color: RetroTheme.primary.opacity(0.3), radius: 10)
        }
    }
}
