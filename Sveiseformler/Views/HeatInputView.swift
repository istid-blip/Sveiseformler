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
        case voltage, amperage, speed
        var id: Int { hashValue }
    }
    @State private var activeInput: InputType?
    
    // --- Lagret Data ---
    @AppStorage("heat_selected_process_name") private var selectedProcessName: String = "MAG / FCAW"
    @AppStorage("heat_voltage") private var voltageStr: String = ""
    @AppStorage("heat_amperage") private var amperageStr: String = ""
    @AppStorage("heat_travelSpeed") private var travelSpeedStr: String = ""
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
        let v = voltageStr.toDouble
        let i = amperageStr.toDouble
        let s = travelSpeedStr.toDouble
        
        if s == 0 { return 0 }
        
        // Formel: (U * I * 60) / (v * 1000) * k
        let energy = (v * i * 60) / (s * 1000)
        return energy * efficiency
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
                .zIndex(1) // Header ligger lavt
                
                VStack(spacing: 25) {
                    
                    // --- TOP SECTION: PROCESS (LEFT) & RESULT (RIGHT) ---
                    // Her bruker vi zIndex(100) for at dropdown skal havne øverst
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
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .zIndex(100) // VIKTIG: Menyen må ligge over resultatet og resten
                        
                        // Mellomrom
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
                    .zIndex(100) // Hele topp-seksjonen må ligge over formelen under

                    // --- THE VISUAL FORMULA (INTERACTIVE) ---
                    VStack(spacing: 15) {
                        HStack(alignment: .center, spacing: 8) {
                            
                            // Faktor k (Visuell)
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
                            
                            // Multiplikator
                            Text("×").font(RetroTheme.font(size: 20)).foregroundColor(RetroTheme.primary)
                            
                            // Brøken
                            VStack(spacing: 4) {
                                // Teller: Volt * Ampere * 60
                                HStack(alignment: .bottom, spacing: 6) {
                                    
                                    // VOLT KNAPP
                                    RollingInputButton(
                                        label: "U (Volt)",
                                        value: voltageStr.toDouble,
                                        precision: 1,
                                        action: { activeInput = .voltage }
                                    )
                                    
                                    Text("×").foregroundColor(RetroTheme.dim)
                                    
                                    // AMPERE KNAPP
                                    RollingInputButton(
                                        label: "I (Amp)",
                                        value: amperageStr.toDouble,
                                        precision: 0,
                                        action: { activeInput = .amperage }
                                    )
                                    
                                    Text("×").foregroundColor(RetroTheme.dim)
                                    
                                    // Konstant 60
                                    VStack(spacing: 0) {
                                        Text("60")
                                            .font(RetroTheme.font(size: 16, weight: .bold))
                                            .foregroundColor(RetroTheme.dim)
                                            .padding(.vertical, 8)
                                        Text("sec")
                                            .font(RetroTheme.font(size: 8))
                                            .foregroundColor(RetroTheme.dim)
                                            .padding(.top, 4)
                                    }
                                }
                                
                                // Brøkstrek
                                Rectangle()
                                    .fill(RetroTheme.primary)
                                    .frame(height: 2)
                                
                                // Nevner: Travel Speed * 1000
                                HStack(alignment: .top, spacing: 6) {
                                    
                                    // FART KNAPP
                                    RollingInputButton(
                                        label: "v (mm/min)",
                                        value: travelSpeedStr.toDouble,
                                        precision: 0,
                                        action: { activeInput = .speed }
                                    )
                                    
                                    Text("×").foregroundColor(RetroTheme.dim)
                                    
                                    // Konstant 1000
                                    VStack(spacing: 0) {
                                        Text("1000")
                                            .font(RetroTheme.font(size: 16, weight: .bold))
                                            .foregroundColor(RetroTheme.dim)
                                            .padding(.vertical, 8)
                                        Text("mm")
                                            .font(RetroTheme.font(size: 8))
                                            .foregroundColor(RetroTheme.dim)
                                            .padding(.top, 4)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(RetroTheme.dim, lineWidth: 1).opacity(0.5))
                    .padding(.horizontal)
                    .zIndex(0) // Formelen ligger under topp-seksjonen
                    
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
        // --- SHEET LOGIC FOR ROLLING PICKERS ---
        .sheet(item: $activeInput) { inputType in
            switch inputType {
            case .voltage:
                RollingPickerSheet(
                    title: "SET VOLTAGE (V)",
                    value: Binding(
                        get: { voltageStr.toDouble },
                        set: { voltageStr = String($0) }
                    ),
                    range: 10...45,
                    step: 0.1,
                    onDismiss: { activeInput = nil }
                )
            case .amperage:
                RollingPickerSheet(
                    title: "SET AMPERAGE (A)",
                    value: Binding(
                        get: { amperageStr.toDouble },
                        set: { amperageStr = String(format: "%.0f", $0) }
                    ),
                    range: 10...600,
                    step: 1.0,
                    onDismiss: { activeInput = nil }
                )
            case .speed:
                RollingPickerSheet(
                    title: "TRAVEL SPEED (mm/min)",
                    value: Binding(
                        get: { travelSpeedStr.toDouble },
                        set: { travelSpeedStr = String(format: "%.0f", $0) }
                    ),
                    range: 10...2000,
                    step: 5.0,
                    onDismiss: { activeInput = nil }
                )
            }
        }
    }
    
    // --- Logikk ---
    
    func selectProcess(_ process: WeldingProcess) {
        selectedProcessName = process.name
        efficiency = process.kFactor
        voltageStr = process.defaultVoltage
        amperageStr = process.defaultAmperage
        if travelSpeedStr.isEmpty { travelSpeedStr = "300" }
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
