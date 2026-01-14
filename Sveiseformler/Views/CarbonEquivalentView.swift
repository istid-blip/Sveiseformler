import SwiftUI
import SwiftData

struct CarbonEquivalentView: View {
    // 1. Navigation & Data
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<SavedCalculation> { $0.category == "CE" },
           sort: \SavedCalculation.timestamp, order: .reverse)
    private var history: [SavedCalculation]
    
    // 2. Wheel Focus State
    enum InputTarget: String, Identifiable {
        case c, mn, cr, mo, v, ni, cu
        var id: String { rawValue }
    }
    @State private var focusedField: InputTarget? = nil
    
    // 3. Inputs
    @AppStorage("ce_c") private var c: String = ""
    @AppStorage("ce_mn") private var mn: String = ""
    @AppStorage("ce_cr") private var cr: String = ""
    @AppStorage("ce_mo") private var mo: String = ""
    @AppStorage("ce_v") private var v: String = ""
    @AppStorage("ce_ni") private var ni: String = ""
    @AppStorage("ce_cu") private var cu: String = ""
    
    // Navn-feltet beholder vi som vanlig tekstfelt siden det er tekst
    @State private var customName: String = ""
    @FocusState private var nameFieldFocused: Bool
    
    var ceValue: Double {
        let C_val = c.toDouble
        let Mn_val = mn.toDouble
        let Cr_val = cr.toDouble
        let Mo_val = mo.toDouble
        let V_val = v.toDouble
        let Ni_val = ni.toDouble
        let Cu_val = cu.toDouble
        
        return C_val + (Mn_val/6) + ((Cr_val+Mo_val+V_val)/5) + ((Ni_val+Cu_val)/15)
    }
    
    var isCritical: Bool { ceValue > 0.40 }
    
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
                    Text("CARB_EQUIV_MOD")
                        .font(RetroTheme.font(size: 16, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                }
                .padding()
                
                // --- MAIN CONTENT ---
                ZStack(alignment: .bottom) {
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            // --- RESULT MONITOR ---
                            VStack(spacing: 5) {
                                Text("CARBON EQUIVALENT (CE)")
                                    .font(RetroTheme.font(size: 12))
                                    .foregroundColor(RetroTheme.dim)
                                Text(String(format: "%.3f", ceValue))
                                    .font(RetroTheme.font(size: 40, weight: .black))
                                    .foregroundColor(isCritical ? Color.red : RetroTheme.primary)
                                    .shadow(color: (isCritical ? Color.red : RetroTheme.primary).opacity(0.6), radius: 8)
                            }
                            .padding(.top, 0)

                            // --- FORMULA VISUALIZATION ---
                            VStack(alignment: .leading, spacing: 5) {
                                // Row 1: C + (Mn / 6)
                                HStack(alignment: .center, spacing: 10) {
                                    SelectableEquationInput(label: "C", value: c.toDouble, target: .c, currentFocus: focusedField) { focusedField = .c }
                                    Text("+").foregroundColor(RetroTheme.dim)
                                    VStack(spacing: 2) {
                                        SelectableEquationInput(label: "Mn", value: mn.toDouble, target: .mn, currentFocus: focusedField) { focusedField = .mn }
                                        Rectangle().fill(RetroTheme.primary).frame(height: 2)
                                        Text("6").font(RetroTheme.font(size: 14)).foregroundColor(RetroTheme.dim)
                                    }.frame(width: 60)
                                }
                                
                                // Row 2: + (Cr+Mo+V) / 5
                                HStack(alignment: .center, spacing: 10) {
                                    Text("+").foregroundColor(RetroTheme.dim)
                                    VStack(spacing: 2) {
                                        HStack(spacing: 5) {
                                            SelectableEquationInput(label: "Cr", value: cr.toDouble, target: .cr, currentFocus: focusedField) { focusedField = .cr }
                                            Text("+").foregroundColor(RetroTheme.dim)
                                            SelectableEquationInput(label: "Mo", value: mo.toDouble, target: .mo, currentFocus: focusedField) { focusedField = .mo }
                                            Text("+").foregroundColor(RetroTheme.dim)
                                            SelectableEquationInput(label: "V", value: v.toDouble, target: .v, currentFocus: focusedField) { focusedField = .v }
                                        }
                                        Rectangle().fill(RetroTheme.primary).frame(height: 2)
                                        Text("5").font(RetroTheme.font(size: 14)).foregroundColor(RetroTheme.dim)
                                    }
                                }
                                
                                // Row 3: + (Ni+Cu) / 15
                                HStack(alignment: .center, spacing: 10) {
                                    Text("+").foregroundColor(RetroTheme.dim)
                                    VStack(spacing: 2) {
                                        HStack(spacing: 5) {
                                            SelectableEquationInput(label: "Ni", value: ni.toDouble, target: .ni, currentFocus: focusedField) { focusedField = .ni }
                                            Text("+").foregroundColor(RetroTheme.dim)
                                            SelectableEquationInput(label: "Cu", value: cu.toDouble, target: .cu, currentFocus: focusedField) { focusedField = .cu }
                                        }
                                        Rectangle().fill(RetroTheme.primary).frame(height: 2)
                                        Text("15").font(RetroTheme.font(size: 14)).foregroundColor(RetroTheme.dim)
                                    }
                                }
                            }
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(RetroTheme.dim, lineWidth: 1).opacity(0.5))
                            .padding(.horizontal)
                            
                            // --- SAVE & LOGS ---
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    TextField("ID...", text: $customName)
                                        .focused($nameFieldFocused)
                                        .font(RetroTheme.font(size: 16))
                                        .foregroundColor(RetroTheme.primary)
                                        .padding(10)
                                        .overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
                                        .tint(RetroTheme.primary)
                                        .onTapGesture {
                                            // Lukk hjulet hvis man trykker på tekstfeltet
                                            focusedField = nil
                                        }
                                    
                                    Button(action: saveItem) {
                                        Text("SAVE")
                                            .font(RetroTheme.font(size: 14, weight: .bold))
                                            .padding()
                                            .background(customName.isEmpty ? RetroTheme.dim : RetroTheme.primary)
                                            .foregroundColor(Color.black)
                                    }
                                    .disabled(customName.isEmpty)
                                }
                                
                                // Show History Logs
                                if !history.isEmpty {
                                    Text("> LOGS")
                                        .font(RetroTheme.font(size: 14, weight: .bold))
                                        .foregroundColor(RetroTheme.primary)
                                        .padding(.top, 10)
                                    
                                    ForEach(history.prefix(5)) { item in
                                        RetroHistoryRow(item: item) {
                                            deleteItem(item)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 320) // Ekstra plass i bunnen for hjulet
                        }
                    }
                    .onTapGesture {
                        if focusedField != nil {
                            withAnimation { focusedField = nil }
                        }
                        nameFieldFocused = false
                    }
                    
                    // --- TROMMEL OVERLAY (FLYTENDE) ---
                    if let target = focusedField {
                        VStack(spacing: 0) {
                            
                            // PUSTELUKE: Lar deg trykke på knappene bak overlayet
                            Color.clear
                                .allowsHitTesting(false)
                            
                            ZStack {
                                // SKJOLD: Hindrer scrolling i historikken bak hjulet
                                Color.black.opacity(0.01)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation { focusedField = nil }
                                    }
                                
                                // Selve hjulet
                                AcceleratedWideJogger(
                                    value: binding(for: target),
                                    range: range(for: target),
                                    step: step(for: target)
                                )
                                .padding(.bottom, 50)
                            }
                            .frame(height: 380)
                        }
                        .ignoresSafeArea(edges: .bottom)
                        .transition(.move(edge: .bottom))
                        .zIndex(100)
                    }
                }
            }
        }
        .crtScreen()
        .navigationBarHidden(true)
    }
    
    // --- Logic Helpers ---

    func saveItem() {
        let val = String(format: "%.3f", ceValue)
        modelContext.insert(SavedCalculation(name: customName, resultValue: val, category: "CE"))
        customName = ""
        nameFieldFocused = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func deleteItem(_ item: SavedCalculation) {
        withAnimation {
            modelContext.delete(item)
        }
    }
    
    // --- Wheel Configuration Helpers ---
    
    func binding(for field: InputTarget) -> Binding<Double> {
        switch field {
        case .c: return Binding(get: { c.toDouble }, set: { c = String(format: "%.2f", $0) })
        case .mn: return Binding(get: { mn.toDouble }, set: { mn = String(format: "%.2f", $0) })
        case .cr: return Binding(get: { cr.toDouble }, set: { cr = String(format: "%.2f", $0) })
        case .mo: return Binding(get: { mo.toDouble }, set: { mo = String(format: "%.2f", $0) })
        case .v: return Binding(get: { v.toDouble }, set: { v = String(format: "%.2f", $0) })
        case .ni: return Binding(get: { ni.toDouble }, set: { ni = String(format: "%.2f", $0) })
        case .cu: return Binding(get: { cu.toDouble }, set: { cu = String(format: "%.2f", $0) })
        }
    }
    
    func range(for field: InputTarget) -> ClosedRange<Double> {
        // De fleste legeringselementer er mellom 0 og 5-10%
        return 0...10.0
    }
    
    func step(for field: InputTarget) -> Double {
        // Kjemisk analyse trenger ofte hundredeler (0.01)
        return 0.01
    }
    
    func title(for field: InputTarget) -> String {
        switch field {
        case .c: return "Carbon (C)"
        case .mn: return "Manganese (Mn)"
        case .cr: return "Chromium (Cr)"
        case .mo: return "Molybdenum (Mo)"
        case .v: return "Vanadium (V)"
        case .ni: return "Nickel (Ni)"
        case .cu: return "Copper (Cu)"
        }
    }
}

// --- Local Helpers ---

// En tilpasset knapp som åpner hjulet (erstatter tekstfeltet)
struct SelectableEquationInput: View {
    let label: String
    let value: Double
    let target: CarbonEquivalentView.InputTarget
    let currentFocus: CarbonEquivalentView.InputTarget?
    let action: () -> Void

    var body: some View {
        let isSelected = (currentFocus == target)
        
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                action()
                Haptics.selection()
            }
        }) {
            VStack(spacing: 0) {
                Text(String(format: "%.2f", value))
                    .font(RetroTheme.font(size: 24, weight: .bold))
                    .foregroundColor(RetroTheme.primary)
                    .frame(minWidth: 70)
                    .padding(.vertical, 5)
                    .background(Color.black)
                    .overlay(
                        Rectangle()
                            .stroke(isSelected ? RetroTheme.primary : RetroTheme.dim, lineWidth: isSelected ? 2 : 1)
                    )

                Text(label)
                    .font(RetroTheme.font(size: 10))
                    .foregroundColor(isSelected ? RetroTheme.primary : RetroTheme.dim)
                    .padding(.top, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// --- Extensions ---
// (Hvis denne allerede ligger i en annen fil kan du fjerne den her, men den skader ikke)
extension String {
    var toDouble: Double {
        let cleanString = self.replacingOccurrences(of: ",", with: ".")
        return Double(cleanString) ?? 0.0
    }
}
