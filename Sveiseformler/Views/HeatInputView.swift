import SwiftUI
import SwiftData

struct HeatInputView: View {
    // 1. Access the Database Context
    @Environment(\.modelContext) private var modelContext
    
    // 2. Query the database
    @Query(filter: #Predicate<SavedCalculation> { $0.category == "Heat" },
           sort: \SavedCalculation.timestamp, order: .reverse)
    private var history: [SavedCalculation]
    
    // 3. Storage
    @AppStorage("heat_voltage") private var voltage: String = ""
    @AppStorage("heat_amperage") private var amperage: String = ""
    @AppStorage("heat_travelSpeed") private var travelSpeed: String = ""
    @AppStorage("heat_efficiency") private var efficiency: Double = 0.8
    @State private var customName: String = ""
    @Environment(\.dismiss) var dismiss
    
    // 4. Logic
    var heatInput: Double {
        let v = Double(voltage) ?? 0
        let i = Double(amperage) ?? 0
        let s = Double(travelSpeed) ?? 1
        if s == 0 { return 0.0 }
        return ((v * i * 0.06) / s) * efficiency
    }
    
    var body: some View {
        // --- HEADER ---
        HStack {
            // The Retro Back Button
            Button(action: { dismiss() }) {
                Text("< BACK")
                    .font(RetroTheme.font(size: 16, weight: .bold))
                    .foregroundColor(RetroTheme.primary)
                    .padding(5)
                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("MODULE: HEAT_INPUT")
                    .font(RetroTheme.font(size: 18, weight: .heavy))
                    .foregroundColor(RetroTheme.primary)
            }
        }
        .padding(.top)
        
        ZStack {
            // Background Layer
            RetroTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    // --- HEADER ---
                    VStack(alignment: .leading, spacing: 5) {
                        Text("MODULE: HEAT_INPUT")
                            .font(RetroTheme.font(size: 24, weight: .heavy))
                            .foregroundColor(RetroTheme.primary)
                        Text("STATUS: CALCULATING...")
                            .font(RetroTheme.font(size: 14))
                            .foregroundColor(RetroTheme.primary).opacity(0.7)
                    }
                    .padding(.top)
                    
                    Divider().background(RetroTheme.primary)
                    
                    // --- PARAMETERS SECTION ---
                    Text("> PARAMETERS")
                        .font(RetroTheme.font(size: 16, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                    
                    VStack(spacing: 15) {
                        RetroInput(title: "VOLTAGE (V)", text: $voltage, keyboardType: .decimalPad)
                        RetroInput(title: "AMPERAGE (A)", text: $amperage, keyboardType: .decimalPad)
                        RetroInput(title: "SPEED (mm/min)", text: $travelSpeed, keyboardType: .decimalPad)
                    }
                    
                    // --- EFFICIENCY SELECTOR (Custom Retro Style) ---
                    VStack(alignment: .leading) {
                        Text("PROCESS EFFICIENCY")
                            .font(RetroTheme.font(size: 14))
                            .foregroundColor(RetroTheme.primary)
                        
                        HStack(spacing: 10) {
                            EfficiencyButton(label: "SMAW (1.0)", value: 1.0, selection: $efficiency)
                            EfficiencyButton(label: "GMAW (0.8)", value: 0.8, selection: $efficiency)
                            EfficiencyButton(label: "GTAW (0.6)", value: 0.6, selection: $efficiency)
                        }
                    }
                    
                    Divider().background(RetroTheme.dim)
                    
                    // --- RESULTS DISPLAY ---
                    HStack {
                        Text("HEAT INPUT >>")
                            .font(RetroTheme.font(size: 16))
                        Spacer()
                        Text(String(format: "%.2f kJ/mm", heatInput))
                            .font(RetroTheme.font(size: 24, weight: .bold))
                            .underline()
                    }
                    .foregroundColor(RetroTheme.primary)
                    .padding()
                    .overlay(
                        Rectangle().stroke(RetroTheme.primary, lineWidth: 2)
                    )
                    
                    // --- SAVE SECTION ---
                    VStack(alignment: .leading, spacing: 10) {
                        Text("> ARCHIVE RESULT")
                            .font(RetroTheme.font(size: 14))
                            .foregroundColor(RetroTheme.primary)
                        
                        HStack {
                            // Using a simplified RetroInput for the name
                            ZStack(alignment: .leading) {
                                if customName.isEmpty {
                                    Text("ENTER_ID...")
                                        .font(RetroTheme.font(size: 16))
                                        .foregroundColor(RetroTheme.dim)
                                        .padding(.leading, 5)
                                }
                                TextField("", text: $customName)
                                    .font(RetroTheme.font(size: 16))
                                    .foregroundColor(RetroTheme.primary)
                                    .padding(10)
                                    .background(Color.black)
                                    .overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
                            }
                            
                            Button(action: saveItem) {
                                Text("SAVE")
                                    .font(RetroTheme.font(size: 16, weight: .bold))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(customName.isEmpty ? RetroTheme.dim : RetroTheme.primary)
                                    .foregroundColor(.black)
                            }
                            .disabled(customName.isEmpty)
                        }
                    }
                    
                    Divider().background(RetroTheme.dim)
                    
                    // --- HISTORY SECTION ---
                    Text("> SYSTEM LOGS")
                        .font(RetroTheme.font(size: 16, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                    
                    VStack(spacing: 12) {
                        if history.isEmpty {
                            Text("NO DATA FOUND")
                                .font(RetroTheme.font(size: 14))
                                .foregroundColor(RetroTheme.dim)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(history) { item in
                                RetroHistoryRow(item: item) {
                                    deleteItem(item)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
                .padding()
            }
        }
        .crtScreen() // Apply the CRT Scanline effect
        .scrollDismissesKeyboard(.immediately)
        .navigationBarHidden(true) // Hide default nav bar
    }
    
    // --- LOGIC ---
    
    func saveItem() {
        let val = String(format: "%.2f kJ/mm", heatInput)
        let newItem = SavedCalculation(name: customName, resultValue: val, category: "Heat")
        modelContext.insert(newItem)
        customName = ""
        
        // Optional: Add haptic feedback here
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func deleteItem(_ item: SavedCalculation) {
        withAnimation {
            modelContext.delete(item)
        }
    }
}

// MARK: - Subviews for Retro Styling

// 1. Efficiency Selector Button
struct EfficiencyButton: View {
    let label: String
    let value: Double
    @Binding var selection: Double
    
    var isSelected: Bool { selection == value }
    
    var body: some View {
        Button(action: { selection = value }) {
            Text(label)
                .font(RetroTheme.font(size: 12))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? RetroTheme.primary : Color.black)
                .foregroundColor(isSelected ? Color.black : RetroTheme.primary)
                .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
        }
    }
}

// 2. Standard Input Field
struct RetroInput: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(RetroTheme.font(size: 12))
                .foregroundColor(RetroTheme.primary)
            
            TextField("", text: $text)
                .font(RetroTheme.font(size: 18))
                .foregroundColor(RetroTheme.primary)
                .keyboardType(keyboardType)
                .padding(10)
                .background(Color.black)
                .overlay(
                    Rectangle()
                        .stroke(RetroTheme.dim, lineWidth: 1)
                )
        }
    }
}

// 3. History Row Item
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
                    .foregroundColor(.red) // A bit of red for danger, or use RetroTheme.primary
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
