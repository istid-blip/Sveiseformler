import SwiftUI
import SwiftData

// Definisjon av sveiseprosesser (EN 1011-1)
struct WeldingProcess: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let kFactor: Double
    let defaultVoltage: String
    let defaultAmperage: String
}

struct HeatInputView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // --- QUERY FOR GROUPS (JOBS) ---
    @Query(sort: \WeldGroup.date, order: .reverse)
    private var jobHistory: [WeldGroup]
    
    // State for Rullevelger
    enum InputType: Identifiable {
        case voltage, amperage, time, length
        var id: Int { hashValue }
    }
    @State private var activeInput: InputType?
    
    // Lagret Data
    @AppStorage("heat_selected_process_name") private var selectedProcessName: String = "MAG / FCAW"
    @AppStorage("heat_voltage") private var voltageStr: String = ""
    @AppStorage("heat_amperage") private var amperageStr: String = ""
    @AppStorage("heat_time") private var timeStr: String = ""
    @AppStorage("heat_length") private var lengthStr: String = ""
    @AppStorage("heat_efficiency") private var efficiency: Double = 0.8
    @AppStorage("heat_pass_counter") private var passCounter: Int = 1
    
    // --- JOB MANAGEMENT STATE ---
    @State private var currentJobName: String = ""
    @State private var activeJobID: UUID?
    
    // Prosesser
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

    var heatInput: Double {
        let v = voltageStr.toDouble
        let i = amperageStr.toDouble
        let t = timeStr.toDouble
        let l = lengthStr.toDouble
        if l == 0 { return 0 }
        return ((v * i * t) / (l * 1000)) * efficiency
    }
    
    var calculatedSpeed: Double {
        let l = lengthStr.toDouble
        let t = timeStr.toDouble
        if t == 0 { return 0 }
        return (l / t) * 60
    }
    
    var body: some View {
        ZStack {
            RetroTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- HEADER ---
                HStack {
                    // RETRO-KNAPPEN ER TILBAKE HER:
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
                    
                    // --- JOB NAME INPUT ---
                    HStack {
                        Text("JOB:")
                            .font(RetroTheme.font(size: 12))
                            .foregroundColor(RetroTheme.dim)
                        
                        TextField("UNTITLED JOB...", text: $currentJobName)
                            .font(RetroTheme.font(size: 14, weight: .bold))
                            .foregroundColor(RetroTheme.primary)
                            .accentColor(RetroTheme.primary)
                        
                        if activeJobID != nil {
                            Text("• REC")
                                .font(RetroTheme.font(size: 10, weight: .bold))
                                .foregroundColor(.red)
                                .blinkEffect()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, -10)
                    
                    // --- TOP SECTION ---
                    HStack(alignment: .top, spacing: 0) {
                        // LEFT: Process
                        VStack(alignment: .leading, spacing: 5) {
                            Text("PROCESS")
                                .font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                            RetroDropdown(title: "PROCESS", selection: currentProcess, options: processes, onSelect: { selectProcess($0) }, itemText: { $0.name }, itemDetail: { "ISO: \($0.code) k=\($0.kFactor)" })
                            if calculatedSpeed > 0 {
                                Text("Speed: \(String(format: "%.0f", calculatedSpeed)) mm/min").font(RetroTheme.font(size: 9)).foregroundColor(RetroTheme.dim).padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).zIndex(100)
                        
                        Spacer(minLength: 20)
                        
                        // RIGHT: Result
                        VStack(alignment: .trailing, spacing: 5) {
                            Text("CURRENT PASS (kJ/mm)").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                            Text(String(format: "%.2f", heatInput)).font(RetroTheme.font(size: 36, weight: .black)).foregroundColor(RetroTheme.primary).shadow(color: RetroTheme.primary.opacity(0.5), radius: 5).minimumScaleFactor(0.8)
                        }
                        .frame(minWidth: 160, alignment: .trailing).zIndex(0)
                    }
                    .padding(.horizontal).zIndex(100)

                    // --- FORMULA ---
                    VStack(spacing: 15) {
                        HStack(alignment: .center, spacing: 8) {
                            VStack(spacing: 0) {
                                Text(String(format: "%.1f", efficiency)).font(RetroTheme.font(size: 20, weight: .bold)).foregroundColor(RetroTheme.primary).padding(.horizontal, 12).padding(.vertical, 8).overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
                                Text("k").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim).padding(.top, 4)
                            }
                            Text("×").font(RetroTheme.font(size: 20)).foregroundColor(RetroTheme.primary)
                            VStack(spacing: 4) {
                                HStack(alignment: .bottom, spacing: 6) {
                                    RollingInputButton(label: "U (V)", value: voltageStr.toDouble, precision: 1, action: { activeInput = .voltage })
                                    Text("×").foregroundColor(RetroTheme.dim)
                                    RollingInputButton(label: "I (A)", value: amperageStr.toDouble, precision: 0, action: { activeInput = .amperage })
                                }
                                Rectangle().fill(RetroTheme.primary).frame(height: 2)
                                HStack(alignment: .top, spacing: 4) {
                                    Text("(").font(RetroTheme.font(size: 18)).foregroundColor(RetroTheme.dim).padding(.top, 10)
                                    RollingInputButton(label: "L (mm)", value: lengthStr.toDouble, precision: 0, action: { activeInput = .length })
                                    Text("/").font(RetroTheme.font(size: 16)).foregroundColor(RetroTheme.dim).padding(.top, 10)
                                    RollingInputButton(label: "t (s)", value: timeStr.toDouble, precision: 0, action: { activeInput = .time })
                                    Text(")").font(RetroTheme.font(size: 18)).foregroundColor(RetroTheme.dim).padding(.top, 10)
                                    Text("×").foregroundColor(RetroTheme.dim).padding(.top, 10)
                                    HStack(alignment: .top, spacing: 0) { Text("10").font(RetroTheme.font(size: 16, weight: .bold)); Text("3").font(RetroTheme.font(size: 10, weight: .bold)).baselineOffset(8) }.foregroundColor(RetroTheme.dim).padding(.top, 8)
                                }
                            }
                        }
                    }
                    .padding().overlay(RoundedRectangle(cornerRadius: 10).stroke(RetroTheme.dim, lineWidth: 1).opacity(0.5)).padding(.horizontal).zIndex(0)
                    
                    // --- ACTIONS & HISTORY ---
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            
                            // BUTTONS
                            HStack(spacing: 15) {
                                // NEW SESSION BUTTON
                                Button(action: startNewSession) {
                                    VStack(spacing: 2) {
                                        Text("NEW JOB")
                                            .font(RetroTheme.font(size: 12, weight: .bold))
                                        Text("RESET")
                                            .font(RetroTheme.font(size: 8))
                                    }
                                    .foregroundColor(RetroTheme.primary)
                                    .frame(width: 80, height: 50)
                                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                                    .background(Color.black)
                                }
                                
                                // LOG PASS BUTTON
                                Button(action: logPass) {
                                    HStack {
                                        Text("LOG PASS #\(passCounter)")
                                            .font(RetroTheme.font(size: 16, weight: .heavy))
                                        Spacer()
                                        Image(systemName: "arrow.right.to.line")
                                    }
                                    .padding()
                                    .foregroundColor(Color.black)
                                    .background(heatInput > 0 ? RetroTheme.primary : RetroTheme.dim)
                                }
                                .disabled(heatInput == 0)
                            }
                            
                            // HISTORY LIST (JOBS)
                            if !jobHistory.isEmpty {
                                HStack {
                                    Text("> JOB HISTORY")
                                        .font(RetroTheme.font(size: 14, weight: .bold))
                                        .foregroundColor(RetroTheme.primary)
                                    Spacer()
                                }
                                .padding(.top, 10)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(jobHistory) { job in
                                        // Navigation Link til JobDetailView
                                        NavigationLink(destination: JobDetailView(job: job)) {
                                            RetroJobRow(job: job, isActive: job.id == activeJobID)
                                        }
                                        .buttonStyle(PlainButtonStyle())
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
        // VIKTIG: Skjuler system-knappen, men lar vår egne "< MENU" knapp fungere
        .navigationBarBackButtonHidden(true)
        .sheet(item: $activeInput) { inputType in
            switch inputType {
            case .voltage: RollingPickerSheet(title: "VOLTAGE (V)", value: Binding(get: { voltageStr.toDouble }, set: { voltageStr = String($0) }), range: 10...45, step: 0.1, onDismiss: { activeInput = nil })
            case .amperage: RollingPickerSheet(title: "AMPERAGE (A)", value: Binding(get: { amperageStr.toDouble }, set: { amperageStr = String(format: "%.0f", $0) }), range: 10...600, step: 1.0, onDismiss: { activeInput = nil })
            case .time: RollingPickerSheet(title: "TIME (s)", value: Binding(get: { timeStr.toDouble }, set: { timeStr = String(format: "%.0f", $0) }), range: 1...600, step: 1.0, onDismiss: { activeInput = nil })
            case .length: RollingPickerSheet(title: "LENGTH (mm)", value: Binding(get: { lengthStr.toDouble }, set: { lengthStr = String(format: "%.0f", $0) }), range: 10...5000, step: 10.0, onDismiss: { activeInput = nil })
            }
        }
        .onAppear {
            // Sjekk om vi har en "aktiv" jobb som ikke er lagret i history enda?
        }
    }
    
    // --- LOGIKK ---
    
    func selectProcess(_ process: WeldingProcess) {
        selectedProcessName = process.name
        efficiency = process.kFactor
        voltageStr = process.defaultVoltage
        amperageStr = process.defaultAmperage
        if timeStr.isEmpty { timeStr = "60" }
        if lengthStr.isEmpty { lengthStr = "300" }
        Haptics.play(.light)
    }
    
    func startNewSession() {
        activeJobID = nil
        passCounter = 1
        currentJobName = ""
        Haptics.play(.medium)
    }
    
    func logPass() {
        let job: WeldGroup
        
        if let id = activeJobID, let existingJob = jobHistory.first(where: { $0.id == id }) {
            job = existingJob
            if !currentJobName.isEmpty {
                job.name = currentJobName
            }
        } else {
            let name = currentJobName.isEmpty ? "Job \(Date().formatted(.dateTime.day().month().hour().minute()))" : currentJobName
            job = WeldGroup(name: name)
            modelContext.insert(job)
            activeJobID = job.id
            currentJobName = name
        }
        
        let resultString = String(format: "%.2f kJ/mm", heatInput)
        let passName = "Pass #\(passCounter)"
        
        let newPass = SavedCalculation(
            name: passName,
            resultValue: resultString,
            category: "HeatInput",
            voltage: voltageStr.toDouble,
            amperage: amperageStr.toDouble,
            travelTime: timeStr.toDouble,
            weldLength: lengthStr.toDouble,
            calculatedHeat: heatInput
        )
        
        newPass.group = job
        passCounter += 1
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}

// --- VIEW COMPONENT FOR JOB ROW ---
struct RetroJobRow: View {
    let job: WeldGroup
    let isActive: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(job.name)
                        .font(RetroTheme.font(size: 16, weight: .bold))
                        .foregroundColor(isActive ? Color.green : RetroTheme.primary)
                    
                    if isActive {
                        Text("• ACTIVE")
                            .font(RetroTheme.font(size: 9, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                
                Text("\(job.passes.count) passes recorded")
                    .font(RetroTheme.font(size: 10))
                    .foregroundColor(RetroTheme.dim)
            }
            
            Spacer()
            
            Text(job.date, format: .dateTime.day().month())
                .font(RetroTheme.font(size: 12))
                .foregroundColor(RetroTheme.dim)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(RetroTheme.dim)
        }
        .padding(12)
        .overlay(Rectangle().stroke(isActive ? Color.green : RetroTheme.dim.opacity(0.5), lineWidth: 1))
        .background(Color.black.opacity(0.3))
    }
}

extension View {
    func blinkEffect() -> some View {
        self.modifier(BlinkModifier())
    }
}
struct BlinkModifier: ViewModifier {
    @State private var isOn = false
    func body(content: Content) -> some View {
        content
            .opacity(isOn ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
                    isOn = true
                }
            }
    }
}
