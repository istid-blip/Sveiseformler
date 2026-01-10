import SwiftUI
import SwiftData

// Definisjon av sveiseprosesser (EN 1011-1)
struct WeldingProcess: Identifiable, Hashable {
    let id = UUID()
    let name: String       // F.eks "MAG / Massivtråd"
    let code: String       // F.eks "135"
    let kFactor: Double    // Virkningsgrad (0.8)
    let defaultVoltage: String
    let defaultAmperage: String
}

struct HeatInputView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Henter historikk
    @Query(filter: #Predicate<SavedCalculation> { $0.category == "HeatInput" },
           sort: \SavedCalculation.timestamp, order: .reverse)
    private var history: [SavedCalculation]
    
    // --- State for Rullevelger (Picker) ---
    enum InputType: Identifiable {
        case voltage, amperage, time, length
        var id: Int { hashValue }
    }
    @State private var activeInput: InputType?
    
    // --- Lagret Data ---
    @AppStorage("heat_selected_process_name") private var selectedProcessName: String = "MAG / FCAW"
    
    // Input-verdier lagret som String
    @AppStorage("heat_voltage") private var voltageStr: String = ""
    @AppStorage("heat_amperage") private var amperageStr: String = ""
    @AppStorage("heat_time") private var timeStr: String = ""
    @AppStorage("heat_length") private var lengthStr: String = ""
    @AppStorage("heat_efficiency") private var efficiency: Double = 0.8
    
    @State private var customName: String = ""
    
    // Liste over standard prosesser
    private let processes = [
        WeldingProcess(name: "SAW (Pulver)", code: "121", kFactor: 1.0, defaultVoltage: "30.0", defaultAmperage: "500"),
        WeldingProcess(name: "MMA (Pinne)", code: "111", kFactor: 0.8, defaultVoltage: "23.0", defaultAmperage: "120"),
        WeldingProcess(name: "MAG / FCAW", code: "135/136", kFactor: 0.8, defaultVoltage: "24.0", defaultAmperage: "200"),
        WeldingProcess(name: "TIG / GTAW", code: "141", kFactor: 0.6, defaultVoltage: "14.0", defaultAmperage: "110"),
        WeldingProcess(name: "Plasma", code: "15", kFactor: 0.6, defaultVoltage: "25.0", defaultAmperage: "150")
    ]
    
    var currentProcess: WeldingProcess {
        processes.first(where: { $0.name == selectedProcessName }) ?? processes[2]
    }

    // --- Beregning ---
    var heatInput: Double {
        let v = voltageStr.toDouble // Volt
        let i = amperageStr.toDouble // Ampere
        let t = timeStr.toDouble     // Sekunder
        let l = lengthStr.toDouble   // Millimeter
        
        if l == 0 { return 0 }
        
        // Formel: (U * I * t) / (L * 1000) * k
        let energy = (v * i * t) / (l * 1000)
        return energy * efficiency
    }
    
    // Beregnet hastighet (kun for visning)
    var calculatedSpeed: Double {
        let l = lengthStr.toDouble
        let t = timeStr.toDouble
        if t == 0 { return 0 }
        // mm/min = (lengde / tid_sekunder) * 60
        return (l / t) * 60
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
                .zIndex(1)
                
                VStack(spacing: 25) {
                    
                    // --- TOP SECTION: PROCESS (LEFT) & RESULT (RIGHT) ---
                    HStack(alignment: .top, spacing: 0) {
                        
                        // LEFT: Process Selector
                        VStack(alignment: .leading, spacing: 5) {
                            Text("PROCESS")
                                .font(RetroTheme.font(size: 10))
                                .foregroundColor(RetroTheme.dim)
                            
                            RetroDropdown(
                                title: "PROCESS",
                                selection: currentProcess,
                                options: processes,
                                onSelect: { selectProcess($0) },
                                itemText: { $0.name },
                                itemDetail: { "ISO: \($0.code)  k=\(String(format: "%.1f", $0.kFactor))" }
                            )
                            
                            if calculatedSpeed > 0 {
                                Text("Calc. Speed: \(String(format: "%.0f", calculatedSpeed)) mm/min")
                                    .font(RetroTheme.font(size: 9))
                                    .foregroundColor(RetroTheme.dim)
                                    .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .zIndex(100)
                        
                        Spacer(minLength: 20)
                        
                        // RIGHT: Result Display
                        VStack(alignment: .trailing, spacing: 5) {
                            Text("RECENT PASS (kJ/mm)")
                                .font(RetroTheme.font(size: 10))
                                .foregroundColor(RetroTheme.dim)
                            
                            Text(String(format: "%.2f", heatInput))
                                .font(RetroTheme.font(size: 36, weight: .black))
                                .foregroundColor(RetroTheme.primary)
                                .shadow(color: RetroTheme.primary.opacity(0.5), radius: 5)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(minWidth: 160, alignment: .trailing)
                        .zIndex(0)
                    }
                    .padding(.horizontal)
                    .zIndex(100)

                    // --- THE VISUAL FORMULA (INTERACTIVE) ---
                    // Formel: k * (U * I) / ((L / t) * 10^3)
                    VStack(spacing: 15) {
                        HStack(alignment: .center, spacing: 8) {
                            
                            // Faktor k
                            VStack(spacing: 0) {
                                Text(String(format: "%.1f", efficiency))
                                    .font(RetroTheme.font(size: 20, weight: .bold))
                                    .foregroundColor(RetroTheme.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
                                
                                Text("k")
                                    .font(RetroTheme.font(size: 10))
                                    .foregroundColor(RetroTheme.dim)
                                    .padding(.top, 4)
                            }
                            
                            Text("×").font(RetroTheme.font(size: 20)).foregroundColor(RetroTheme.primary)
                            
                            // Brøken
                            VStack(spacing: 4) {
                                // TELLER: Volt * Ampere
                                HStack(alignment: .bottom, spacing: 6) {
                                    
                                    RollingInputButton(
                                        label: "U (Volt)",
                                        value: voltageStr.toDouble,
                                        precision: 1,
                                        action: { activeInput = .voltage }
                                    )
                                    
                                    Text("×").foregroundColor(RetroTheme.dim)
                                    
                                    RollingInputButton(
                                        label: "I (Amp)",
                                        value: amperageStr.toDouble,
                                        precision: 0,
                                        action: { activeInput = .amperage }
                                    )
                                }
                                
                                // Brøkstrek
                                Rectangle()
                                    .fill(RetroTheme.primary)
                                    .frame(height: 2)
                                
                                // NEVNER: (Lengde / Tid) * 10^3
                                HStack(alignment: .top, spacing: 4) { // Litt tettere spacing
                                    
                                    // Parentes start
                                    Text("(")
                                        .font(RetroTheme.font(size: 18, weight: .light))
                                        .foregroundColor(RetroTheme.dim)
                                        .padding(.top, 10)
                                        
                                    RollingInputButton(
                                        label: "L (mm)",
                                        value: lengthStr.toDouble,
                                        precision: 0,
                                        action: { activeInput = .length }
                                    )
                                    
                                    Text("/")
                                        .font(RetroTheme.font(size: 16))
                                        .foregroundColor(RetroTheme.dim)
                                        .padding(.top, 10)

                                    RollingInputButton(
                                        label: "t (sec)",
                                        value: timeStr.toDouble,
                                        precision: 0,
                                        action: { activeInput = .time }
                                    )
                                    
                                    // Parentes slutt
                                    Text(")")
                                        .font(RetroTheme.font(size: 18, weight: .light))
                                        .foregroundColor(RetroTheme.dim)
                                        .padding(.top, 10)

                                    Text("×")
                                        .foregroundColor(RetroTheme.dim)
                                        .padding(.top, 10)
                                    
                                    // Konstant 10^3 (Sparer plass)
                                    HStack(alignment: .top, spacing: 0) {
                                        Text("10")
                                            .font(RetroTheme.font(size: 16, weight: .bold))
                                        Text("3")
                                            .font(RetroTheme.font(size: 10, weight: .bold))
                                            .baselineOffset(8) // Hever 3-tallet
                                    }
                                    .foregroundColor(RetroTheme.dim)
                                    .padding(.top, 8)
                                    .padding(.leading, 2)
                                }
                            }
                        }
                    }
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(RetroTheme.dim, lineWidth: 1).opacity(0.5))
                    .padding(.horizontal)
                    .zIndex(0)
                    
                    // --- SAVE & LOGS ---
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                TextField("ID (e.g. Root Pass)...", text: $customName)
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
                                .disabled(customName.isEmpty || heatInput == 0)
                            }
                            
                            if !history.isEmpty {
                                Text("> CALCULATED LOGS")
                                    .font(RetroTheme.font(size: 14, weight: .bold))
                                    .foregroundColor(RetroTheme.primary)
                                    .padding(.top, 10)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(history) { item in
                                        RetroHistoryRow(item: item) { deleteItems([item]) }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 50)
                    }
                    .zIndex(0)
                }
            }
        }
        .crtScreen()
        .navigationBarHidden(true)
        // --- SHEETS ---
        .sheet(item: $activeInput) { inputType in
            switch inputType {
            case .voltage:
                RollingPickerSheet(title: "SET VOLTAGE (V)", value: Binding(get: { voltageStr.toDouble }, set: { voltageStr = String($0) }), range: 10...45, step: 0.1, onDismiss: { activeInput = nil })
            case .amperage:
                RollingPickerSheet(title: "SET AMPERAGE (A)", value: Binding(get: { amperageStr.toDouble }, set: { amperageStr = String(format: "%.0f", $0) }), range: 10...600, step: 1.0, onDismiss: { activeInput = nil })
            case .time:
                RollingPickerSheet(title: "WELD TIME (sec)", value: Binding(get: { timeStr.toDouble }, set: { timeStr = String(format: "%.0f", $0) }), range: 1...600, step: 1.0, onDismiss: { activeInput = nil })
            case .length:
                RollingPickerSheet(title: "WELD LENGTH (mm)", value: Binding(get: { lengthStr.toDouble }, set: { lengthStr = String(format: "%.0f", $0) }), range: 10...5000, step: 10.0, onDismiss: { activeInput = nil })
            }
        }
    }
    
    // --- Logikk ---
    
    func selectProcess(_ process: WeldingProcess) {
        selectedProcessName = process.name
        efficiency = process.kFactor
        voltageStr = process.defaultVoltage
        amperageStr = process.defaultAmperage
        if timeStr.isEmpty { timeStr = "60" }
        if lengthStr.isEmpty { lengthStr = "300" }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func saveItem() {
        let val = String(format: "%.2f kJ/mm", heatInput)
        let newItem = SavedCalculation(name: customName, resultValue: val, category: "HeatInput")
        modelContext.insert(newItem)
        customName = ""
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func deleteItems(_ items: [SavedCalculation]) {
        withAnimation {
            for item in items { modelContext.delete(item) }
        }
    }
}
