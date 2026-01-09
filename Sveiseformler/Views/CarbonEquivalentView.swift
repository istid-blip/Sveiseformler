import SwiftUI
import SwiftData

struct CarbonEquivalentView: View {
    // 1. Navigation & Data
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<SavedCalculation> { $0.category == "CE" },
           sort: \SavedCalculation.timestamp, order: .reverse)
    private var history: [SavedCalculation]
    
    // 2. Focus State for Keyboard Shuffling
    enum Field: Int, Hashable, CaseIterable {
        case c, mn, cr, mo, v, ni, cu, name
    }
    @FocusState private var focusedField: Field?
    
    // 3. Inputs
    @AppStorage("ce_c") private var c: String = ""
    @AppStorage("ce_mn") private var mn: String = ""
    @AppStorage("ce_cr") private var cr: String = ""
    @AppStorage("ce_mo") private var mo: String = ""
    @AppStorage("ce_v") private var v: String = ""
    @AppStorage("ce_ni") private var ni: String = ""
    @AppStorage("ce_cu") private var cu: String = ""
    @State private var customName: String = ""
    
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
                
                ScrollView {
                    VStack(spacing: 25) {
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
                        .padding(.top, 10)

                        // --- FORMULA VISUALIZATION ---
                        VStack(alignment: .leading, spacing: 20) {
                            // Row 1: C + (Mn / 6)
                            HStack(alignment: .center, spacing: 10) {
                                EquationInput(label: "C", text: $c, field: .c, focusedField: $focusedField)
                                Text("+").foregroundColor(RetroTheme.dim)
                                VStack(spacing: 2) {
                                    EquationInput(label: "Mn", text: $mn, field: .mn, focusedField: $focusedField)
                                    Rectangle().fill(RetroTheme.primary).frame(height: 2)
                                    Text("6").font(RetroTheme.font(size: 14)).foregroundColor(RetroTheme.dim)
                                }.frame(width: 60)
                            }
                            
                            // Row 2: + (Cr+Mo+V) / 5
                            HStack(alignment: .center, spacing: 10) {
                                Text("+").foregroundColor(RetroTheme.dim)
                                VStack(spacing: 2) {
                                    HStack(spacing: 5) {
                                        EquationInput(label: "Cr", text: $cr, field: .cr, focusedField: $focusedField)
                                        Text("+").foregroundColor(RetroTheme.dim)
                                        EquationInput(label: "Mo", text: $mo, field: .mo, focusedField: $focusedField)
                                        Text("+").foregroundColor(RetroTheme.dim)
                                        EquationInput(label: "V", text: $v, field: .v, focusedField: $focusedField)
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
                                        EquationInput(label: "Ni", text: $ni, field: .ni, focusedField: $focusedField)
                                        Text("+").foregroundColor(RetroTheme.dim)
                                        EquationInput(label: "Cu", text: $cu, field: .cu, focusedField: $focusedField)
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
                                    .focused($focusedField, equals: .name)
                                    .font(RetroTheme.font(size: 16))
                                    .foregroundColor(RetroTheme.primary)
                                    .padding(10)
                                    .overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
                                    .tint(RetroTheme.primary)
                                
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
                        .padding(.bottom, 50)
                    }
                }
            }
        }
        .crtScreen()
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                // Done button on the left
                Button("DONE") {
                    focusedField = nil
                }
                .font(RetroTheme.font(size: 14, weight: .bold))
                .foregroundColor(RetroTheme.primary)
                
                Spacer()
                
                // Horizontal navigation arrows on the right
                HStack(spacing: 20) {
                    Button(action: moveFocusBackward) {
                        Image(systemName: "chevron.left")
                    }
                    .foregroundColor(RetroTheme.primary)
                    
                    Button(action: moveFocusForward) {
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(RetroTheme.primary)
                }
            }
        }
    }
    
    // --- Logic Helpers ---
    
    private func moveFocusForward() {
        guard let current = focusedField else { return }
        let allCases = Field.allCases
        if let currentIndex = allCases.firstIndex(of: current), currentIndex < allCases.count - 1 {
            focusedField = allCases[currentIndex + 1]
        }
    }
    
    private func moveFocusBackward() {
        guard let current = focusedField else { return }
        let allCases = Field.allCases
        if let currentIndex = allCases.firstIndex(of: current), currentIndex > 0 {
            focusedField = allCases[currentIndex - 1]
        }
    }

    func saveItem() {
        let val = String(format: "%.3f", ceValue)
        modelContext.insert(SavedCalculation(name: customName, resultValue: val, category: "CE"))
        customName = ""
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func deleteItem(_ item: SavedCalculation) {
        withAnimation {
            modelContext.delete(item)
        }
    }
}

// --- Local Helpers ---

// En tilpasset input-boks som fungerer med FocusState-navigasjonen i denne filen
struct EquationInput: View {
    let label: String
    @Binding var text: String
    let field: CarbonEquivalentView.Field
    @FocusState.Binding var focusedField: CarbonEquivalentView.Field?

    var body: some View {
        VStack(spacing: 0) {
            TextField("", text: $text)
                .focused($focusedField, equals: field)
                .keyboardType(.decimalPad)
                .font(RetroTheme.font(size: 16, weight: .bold))
                .foregroundColor(RetroTheme.primary)
                .tint(RetroTheme.primary)
                .multilineTextAlignment(.center)
                .frame(minWidth: 45)
                .padding(.vertical, 5)
                .background(Color.black)
                .overlay(
                    Rectangle()
                        .stroke(focusedField == field ? RetroTheme.primary : RetroTheme.dim, lineWidth: 1)
                )

            Text(label)
                .font(RetroTheme.font(size: 10))
                .foregroundColor(focusedField == field ? RetroTheme.primary : RetroTheme.dim)
                .padding(.top, 4)
        }
    }
}

// --- Extensions ---

// Denne fikser feilen med "value of type 'String' has no member 'toDouble'"
extension String {
    var toDouble: Double {
        // Erstatter komma med punktum og konverterer til Double
        let cleanString = self.replacingOccurrences(of: ",", with: ".")
        return Double(cleanString) ?? 0.0
    }
}
