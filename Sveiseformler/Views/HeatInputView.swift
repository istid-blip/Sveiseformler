import SwiftUI
import SwiftData

struct HeatInputView: View {
    // 1. Navigation & Data
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<SavedCalculation> { $0.category == "Heat" },
           sort: \SavedCalculation.timestamp, order: .reverse)
    private var history: [SavedCalculation]
    
    // 2. State for Inputs (Double istedenfor String for enklere matte)
    @AppStorage("heat_voltage_d") private var voltage: Double = 24.0
    @AppStorage("heat_amperage_d") private var amperage: Double = 180.0
    @AppStorage("heat_length_d") private var length: Double = 1000.0 // mm
    @AppStorage("heat_time_d") private var time: Double = 60.0       // sek
    @AppStorage("heat_efficiency") private var efficiency: Double = 0.8
    @State private var customName: String = ""
    
    // State for å styre hvilket "hjul" som er åpent
    @State private var activeSheet: ActiveSheet?
    
    enum ActiveSheet: Identifiable {
        case voltage, amperage, length, time
        var id: Int { hashValue }
    }
    
    // 3. Logic
    var rawEnergy: Double {
        return voltage * amperage * 0.06
    }
    
    var calculatedSpeed: Double {
        if time == 0 { return 0.0 }
        return (length * 60) / time
    }
    
    var heatInput: Double {
        let s = calculatedSpeed
        if s == 0 { return 0.0 }
        return (rawEnergy / s) * efficiency
    }
    
    // Funksjon for å sette smarte standardverdier
    func setDefaults(for processCode: Double) {
        efficiency = processCode
        
        // Eksempel på "smarte" startverdier basert på prosess
        if processCode == 1 { // SMAW (Pinne)
            voltage = 20.0
            amperage = 100.0
        } else if processCode == 2 { // GMAW (MIG/MAG)
            voltage = 28.0
            amperage = 220.0
        } else if processCode == 3 { // GTAW (TIG)
            voltage = 12.0
            amperage = 100.0
        }
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
                    Text("HEAT_INPUT")
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
                            
                            if calculatedSpeed > 0 {
                                Text(String(format: "(Speed: %.0f mm/min)", calculatedSpeed))
                                    .font(RetroTheme.font(size: 12))
                                    .foregroundColor(RetroTheme.dim)
                            }
                        }
                        .padding(.top, 20)
                        
                        // --- FORMULA VISUALIZATION ---
                        VStack(spacing: 15) {
                            HStack(alignment: .center, spacing: 10) {
                                
                                // EFFICIENCY MENU (Setter også startverdier)
                                VStack {
                                    Text("η")
                                        .font(RetroTheme.font(size: 10))
                                        .foregroundColor(RetroTheme.dim)
                                    
                                    Menu {
                                        Button("SMAW (Pinne) - 0.8") { setDefaults(for: 1) }
                                        Button("GMAW/FCAW - 0.8") { setDefaults(for: 2) }
                                        Button("GTAW (TIG) - 0.6") { setDefaults(for: 3) }
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
                                        RollingInputButton(label: "U (V)", value: voltage) {
                                            activeSheet = .voltage
                                        }
                                        
                                        Text("×").foregroundColor(RetroTheme.dim).padding(.bottom, 15)
                                        
                                        // I (Amps)
                                        RollingInputButton(label: "I (A)", value: amperage, precision: 0) {
                                            activeSheet = .amperage
                                        }
                                        
                                        Text("× 0.06").font(RetroTheme.font(size: 14)).foregroundColor(RetroTheme.dim).padding(.bottom, 15)
                                    }
                                    
                                    Rectangle().fill(RetroTheme.primary).frame(height: 2)
                                    
                                    // Denominator
                                    HStack(alignment: .bottom, spacing: 5) {
                                        // Length
                                        RollingInputButton(label: "L (mm)", value: length, precision: 0) {
                                            activeSheet = .length
                                        }
                                        .frame(minWidth: 70)
                                        
                                        Text("÷").foregroundColor(RetroTheme.dim).padding(.bottom, 15)
                                        
                                        // Time
                                        RollingInputButton(label: "t (sec)", value: time, precision: 0) {
                                            activeSheet = .time
                                        }
                                        .frame(minWidth: 70)
                                        
                                        Text("× 60").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim).padding(.bottom, 15)
                                    }
                                }
                            }
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(RetroTheme.dim, lineWidth: 1).opacity(0.5))
                        }
                        
                        // --- SAVE & HISTORY ---
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                // Her bruker vi fortsatt tastatur for tekst, det er mest naturlig
                                TextField("ID (e.g. Root Pass)...", text: $customName)
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
                                Text("> SYSTEM LOGS")
                                    .font(RetroTheme.font(size: 14, weight: .bold))
                                    .foregroundColor(RetroTheme.primary)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(history) { item in
                                        RetroHistoryRow(item: item) { deleteItem(item) }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .crtScreen()
        .sheet(item: $activeSheet) { item in
            switch item {
            case .voltage:
                RollingPickerSheet(title: "VOLTAGE (V)", value: $voltage, range: 10...40, step: 0.5) { activeSheet = nil }
            case .amperage:
                RollingPickerSheet(title: "AMPERAGE (A)", value: $amperage, range: 50...400, step: 10.0) { activeSheet = nil }
            case .length:
                RollingPickerSheet(title: "LENGTH (mm)", value: $length, range: 10...5000, step: 10.0) { activeSheet = nil }
            case .time:
                RollingPickerSheet(title: "TIME (sec)", value: $time, range: 5...600, step: 1.0) { activeSheet = nil }
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

extension String {
    var toDouble: Double {
        let cleanedString = self.replacingOccurrences(of: ",", with: ".")
        return Double(cleanedString) ?? 0.0
    }
}
