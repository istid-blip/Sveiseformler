import SwiftUI
import SwiftData

struct HeatInputView: View {
    // 1. Navigation & Data
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<SavedCalculation> { $0.category == "Heat" },
           sort: \SavedCalculation.timestamp, order: .reverse)
    private var history: [SavedCalculation]
    
    // 2. Focus State (The order we jump through)
    enum Field: Int, Hashable, CaseIterable {
        case voltage, amperage, speed, name
    }
    @FocusState private var focusedField: Field?
    
    // 3. Inputs
    @AppStorage("heat_voltage") private var voltage: String = ""
    @AppStorage("heat_amperage") private var amperage: String = ""
    @AppStorage("heat_travelSpeed") private var travelSpeed: String = ""
    @AppStorage("heat_efficiency") private var efficiency: Double = 0.8
    @State private var customName: String = ""
    
    // 4. Logic
    var rawEnergy: Double {
        let v = voltage.toDouble
        let i = amperage.toDouble
        return v * i * 0.06
    }
    
    var heatInput: Double {
        let s = travelSpeed.toDouble
        if s == 0 { return 0.0 }
        return (rawEnergy / s) * efficiency
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
                    Text("HEAT_INPUT_CALC")
                        .font(RetroTheme.font(size: 16, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // --- RESULT DISPLAY ---
                        VStack(spacing: 5) {
                            Text("RESULT (Q)")
                                .font(RetroTheme.font(size: 12))
                                .foregroundColor(RetroTheme.dim)
                            Text(String(format: "%.2f kJ/mm", heatInput))
                                .font(RetroTheme.font(size: 40, weight: .black))
                                .foregroundColor(RetroTheme.primary)
                                .shadow(color: RetroTheme.primary.opacity(0.6), radius: 8)
                        }
                        .padding(.top, 20)
                        
                        // --- FORMULA VISUALIZATION ---
                        VStack(spacing: 15) {
                            HStack(alignment: .center, spacing: 10) {
                                
                                // EFFICIENCY (Menu)
                                VStack {
                                    Text("η (Eff.)")
                                        .font(RetroTheme.font(size: 10))
                                        .foregroundColor(RetroTheme.dim)
                                    
                                    Menu {
                                        Button("SMAW (1.0)") { efficiency = 1.0 }
                                        Button("GMAW/FCAW (0.8)") { efficiency = 0.8 }
                                        Button("GTAW (0.6)") { efficiency = 0.6 }
                                    } label: {
                                        Text(String(format: "%.1f", efficiency))
                                            .font(RetroTheme.font(size: 20, weight: .bold))
                                            .padding(10)
                                            .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                                    }
                                }
                                
                                Text("×").foregroundColor(RetroTheme.dim)
                                
                                // THE FRACTION
                                VStack(spacing: 5) {
                                    // Numerator
                                    HStack(alignment: .bottom, spacing: 5) {
                                        // U (Volts)
                                        RetroEquationBox(label: "U", value: $voltage)
                                            .focused($focusedField, equals: .voltage)
                                        
                                        Text("×").foregroundColor(RetroTheme.dim).padding(.bottom, 15)
                                        
                                        // I (Amps)
                                        RetroEquationBox(label: "I", value: $amperage)
                                            .focused($focusedField, equals: .amperage)
                                        
                                        Text("× 0.06").font(RetroTheme.font(size: 14)).foregroundColor(RetroTheme.dim).padding(.bottom, 15)
                                    }
                                    
                                    Rectangle().fill(RetroTheme.primary).frame(height: 2)
                                    
                                    // Denominator: Speed
                                    RetroEquationBox(label: "v (mm/min)", value: $travelSpeed)
                                        .focused($focusedField, equals: .speed)
                                        .frame(width: 120)
                                }
                            }
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(RetroTheme.dim, lineWidth: 1).opacity(0.5))
                        }
                        .padding(.horizontal)
                        
                        // --- SAVE & HISTORY ---
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                TextField("ID...", text: $customName)
                                    .focused($focusedField, equals: .name)
                                    .font(RetroTheme.font(size: 16))
                                    .foregroundColor(RetroTheme.primary)
                                    .padding(10)
                                    .overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
                                
                                Button(action: saveItem) {
                                    Text("SAVE")
                                        .font(RetroTheme.font(size: 14, weight: .bold))
                                        .padding()
                                        .background(customName.isEmpty ? RetroTheme.dim : RetroTheme.primary)
                                        .foregroundColor(Color.black)
                                }
                                .disabled(customName.isEmpty)
                            }
                            
                            if !history.isEmpty {
                                Text("> RECENT LOGS")
                                    .font(RetroTheme.font(size: 14, weight: .bold))
                                    .foregroundColor(RetroTheme.primary)
                                
                                ForEach(history.prefix(5)) { item in
                                    RetroHistoryRow(item: item) { deleteItem(item) }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .crtScreen()
        .navigationBarHidden(true)
        // --- NAVIGATION TOOLBAR ---
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("DONE") { focusedField = nil }
                    .font(RetroTheme.font(size: 14, weight: .bold))
                    .foregroundColor(RetroTheme.primary)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: { moveFocus(forward: false) }) {
                        Image(systemName: "chevron.left")
                    }
                    Button(action: { moveFocus(forward: true) }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundColor(RetroTheme.primary)
            }
        }
    }
    
    // --- FOCUS LOGIC ---
    private func moveFocus(forward: Bool) {
        guard let current = focusedField else { return }
        let allCases = Field.allCases
        if let currentIndex = allCases.firstIndex(of: current) {
            let nextIndex = forward ? currentIndex + 1 : currentIndex - 1
            if allCases.indices.contains(nextIndex) {
                focusedField = allCases[nextIndex]
            }
        }
    }

    // --- ACTIONS ---
    func saveItem() {
        let val = String(format: "%.2f kJ/mm", heatInput)
        modelContext.insert(SavedCalculation(name: customName, resultValue: val, category: "Heat"))
        customName = ""
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func deleteItem(_ item: SavedCalculation) {
        withAnimation { modelContext.delete(item) }
    }
}
// --- PASTE THIS AT THE VERY BOTTOM OF THE FILE ---

extension String {
    var toDouble: Double {
        // Replaces commas with dots so "5,5" becomes "5.5" (safe for math)
        let cleanedString = self.replacingOccurrences(of: ",", with: ".")
        return Double(cleanedString) ?? 0.0
    }
}
