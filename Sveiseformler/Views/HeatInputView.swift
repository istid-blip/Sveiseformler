import SwiftUI
import SwiftData

// --- 1. DEFINISJON AV SVEISEPROSESS ---
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
    
    // --- ANIMASJON & STATE ---
    @Namespace private var animationNamespace
    
    enum InputTarget: String, Identifiable {
        case voltage, amperage, time, length
        var id: String { rawValue }
    }
    @State private var focusedField: InputTarget? = nil
    
    // --- QUERY ---
    @Query(sort: \WeldGroup.date, order: .reverse)
    private var jobHistory: [WeldGroup]
    
    // --- LAGRET DATA ---
    @AppStorage("heat_selected_process_name") private var selectedProcessName: String = "MAG / FCAW"
    @AppStorage("heat_voltage") private var voltageStr: String = ""
    @AppStorage("heat_amperage") private var amperageStr: String = ""
    @AppStorage("heat_time") private var timeStr: String = ""
    @AppStorage("heat_length") private var lengthStr: String = ""
    @AppStorage("heat_efficiency") private var efficiency: Double = 0.8
    @AppStorage("heat_pass_counter") private var passCounter: Int = 1
    
    // --- PERSISTENT JOB STATE ---
    @AppStorage("heat_active_job_id") private var storedJobID: String = ""
    @State private var currentJobName: String = ""
    
    var activeJobID: UUID? {
        get {
            if storedJobID.isEmpty { return nil }
            return UUID(uuidString: storedJobID)
        }
        nonmutating set {
            storedJobID = newValue?.uuidString ?? ""
        }
    }
    
    // --- PROSESSER ---
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
                // HEADER
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 5) { Text("< MAIN MENU") }
                            .font(RetroTheme.font(size: 16, weight: .bold))
                            .foregroundColor(RetroTheme.primary)
                            .padding(8)
                            .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                    Spacer()

                    
                    Spacer()
                    Text("HEAT INPUT")
                        .font(RetroTheme.font(size: 16, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                }
                .padding()
                
                // --- MAIN CONTENT ---
                ZStack(alignment: .bottom) {
                    
                    
                    VStack(spacing: 25) {
                        
                        // PROCESS & RESULT
                        HStack(alignment: .top, spacing: 0) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("PROCESS").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                                RetroDropdown(title: "PROCESS", selection: currentProcess, options: processes, onSelect: { selectProcess($0) }, itemText: { $0.name }, itemDetail: { "ISO 4063: \($0.code)" })
                                
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer(minLength: 20)
                            
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("CURRENT PASS (kJ/mm)").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                                Text(String(format: "%.2f", heatInput)).font(RetroTheme.font(size: 36, weight: .black)).foregroundColor(RetroTheme.primary).shadow(color: RetroTheme.primary.opacity(0.5), radius: 5).minimumScaleFactor(0.8)
                                if activeJobID != nil {
                                    Text("• LOGGING").font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(.red).blinkEffect()
                                }
                            }
                            .frame(minWidth: 160, alignment: .trailing)
                        }
                        .padding(.horizontal)
                        .zIndex(1000)
                        
                        // --- FORMULA INTERFACE ---
                        VStack(spacing: 15) {
                            HStack(alignment: .center, spacing: 8) {
                                VStack(spacing: 0) {
                                    Text("ISO 17671").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim).padding(4)
                                    Text(String(format: "%.1f", efficiency)).font(RetroTheme.font(size: 20, weight: .bold)).foregroundColor(RetroTheme.primary).padding(.horizontal, 12).padding(.vertical, 8)
                                    Text("k-factor").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim).padding(4)
                                }
                                Text("×").font(RetroTheme.font(size: 20)).foregroundColor(RetroTheme.dim)
                                
                                VStack(spacing: 4) {
                                    HStack(alignment: .bottom, spacing: 6) {
                                        SelectableInput(label: "Voltage (V)", value: voltageStr.toDouble, target: .voltage, currentFocus: focusedField, precision: 1) { focusedField = .voltage }
                                        Text("×").foregroundColor(RetroTheme.dim)
                                        SelectableInput(label: "Current (A)", value: amperageStr.toDouble, target: .amperage, currentFocus: focusedField, precision: 0) { focusedField = .amperage }
                                    }
                                    Rectangle().fill(RetroTheme.primary).frame(height: 2)
                                    HStack(alignment: .top, spacing: 4) {
                                        
                                        SelectableInput(label: "Length (mm)", value: lengthStr.toDouble, target: .length, currentFocus: focusedField, precision: 0) { focusedField = .length }
                                        Text("/").font(RetroTheme.font(size: 16)).foregroundColor(RetroTheme.dim).padding(.top, 10)
                                        SelectableInput(label: "time (s)", value: timeStr.toDouble, target: .time, currentFocus: focusedField, precision: 0) { focusedField = .time }
                                        
                                        Text("×").foregroundColor(RetroTheme.dim).padding(.top, 10)
                                        HStack(alignment: .top, spacing: 0) { Text("10").font(RetroTheme.font(size: 16, weight: .bold)); Text("3").font(RetroTheme.font(size: 10, weight: .bold)).baselineOffset(8) }.fixedSize(horizontal: true, vertical: false).foregroundColor(RetroTheme.dim).padding(.top, 8)
                                    }
                                    if calculatedSpeed > 0 {
                                        Text("Speed: \(String(format: "%.0f", calculatedSpeed)) mm/min").font(RetroTheme.font(size: 9)).foregroundColor(RetroTheme.dim).padding(.trailing,  40)
                                    }
                                }
                            }
                        }
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(RetroTheme.dim, lineWidth: 1).opacity(0.5))
                        .padding(.horizontal)
                        .zIndex(1)
                        
                        // --- ACTIONS & HISTORY ---
                            
                        HStack(spacing: 15) {
                            Button(action: startNewSession) {
                                VStack(spacing: 2) {
                                    Text("NEW JOB").font(RetroTheme.font(size: 12, weight: .bold))
                                    Text("RESET").font(RetroTheme.font(size: 8))
                                }
                                .foregroundColor(RetroTheme.primary).frame(width: 80, height: 50).overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1)).background(Color.black)
                            }
                            Button(action: logPass) {
                                HStack {
                                    Text("LOG PASS #\(passCounter)").font(RetroTheme.font(size: 20, weight: .heavy))
                                    Spacer()
                                    Image(systemName: "arrow.right.to.line")
                                }
                                .padding().foregroundColor(Color.black).background(heatInput > 0 ? RetroTheme.primary : RetroTheme.dim)
                            }
                            .disabled(heatInput == 0)
                        }
                        .padding(.horizontal)
                            
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 15) {
                                    if !jobHistory.isEmpty {
                                        HStack { Text("> JOB HISTORY").font(RetroTheme.font(size: 14, weight: .bold)).foregroundColor(RetroTheme.primary); Spacer() }.padding(.top, 10)
                                        LazyVStack(spacing: 12) {
                                            ForEach(jobHistory) { job in
                                                NavigationLink(destination: JobDetailView(job: job)) { RetroJobRow(job: job, isActive: job.id == activeJobID) }.buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 320)
                            }
                        }
                    
                    
                    // 2. TROMMEL OVERLAY (FLYTENDE & INTERAKTIVT)
                                        if let target = focusedField {
                                            VStack(spacing: 0) {
                                                
                                                // DEL 1: PUSTELUKE (Lar deg trykke på tallfeltene bak)
                                                // Ved å bruke contentShape(Rectangle) men IKKE ha noen gesture,
                                                // samt bruke .allowsHitTesting(false), sikrer vi at trykk her går "igjennom"
                                                // overlayet og treffer knappene (Voltage, Current osv.) bak.
                                                Color.clear
                                                    .allowsHitTesting(false)
                                                
                                                // DEL 2: BLOKKERINGSSONE + HJULET
                                                ZStack {
                                                    // "Skjoldet": En usynlig bakgrunn som dekker historikk-området.
                                                    // Denne fanger opp trykk slik at du IKKE scroller historikken bak,
                                                    // men vi legger på en gesture slik at du kan lukke hjulet ved å trykke på siden av det.
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
                                                    .padding(.bottom, 50) // Løfter hjulet opp fra bunnen
                                                }
                                                .frame(height: 340) // <-- VIKTIG: Juster denne høyden!
                                                // Denne høyden må være høy nok til å dekke historikken,
                                                // men lav nok til at den ikke dekker tall-knappene dine.
                                            }
                                            .ignoresSafeArea(edges: .bottom)
                                            .transition(.move(edge: .bottom))
                                            .zIndex(100)
                                        }
                }
            }
        }
        .onTapGesture {
            if focusedField != nil {
                withAnimation { focusedField = nil }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            restoreActiveJob()
        }
        .crtScreen()
    }
    
    // --- COMPONENTS & LOGIC ---

    @ViewBuilder
    func SelectableInput(label: String, value: Double, target: InputTarget, currentFocus: InputTarget?, precision: Int, action: @escaping () -> Void) -> some View {
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
                    .font(RetroTheme.font(size: 24, weight: .bold))
                    .foregroundColor(textColor)
                    .padding(.vertical, 4)
                    .frame(minWidth: 80)
                    .background(Color.black)
                    .overlay(Rectangle().stroke(borderColor, lineWidth: isSelected ? 2 : 1))
                
                Text(label)
                    .font(RetroTheme.font(size: 10))
                    .foregroundColor(RetroTheme.dim)
                    .padding(4)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    func binding(for field: InputTarget) -> Binding<Double> {
        switch field {
        case .voltage: return Binding(get: { voltageStr.toDouble }, set: { voltageStr = String(format: "%.1f", $0) })
        case .amperage: return Binding(get: { amperageStr.toDouble }, set: { amperageStr = String(format: "%.0f", $0) })
        case .time: return Binding(get: { timeStr.toDouble }, set: { timeStr = String(format: "%.0f", $0) })
        case .length: return Binding(get: { lengthStr.toDouble }, set: { lengthStr = String(format: "%.0f", $0) })
        }
    }
    func range(for field: InputTarget) -> ClosedRange<Double> {
        switch field {
        case .voltage: return 0...100
        case .amperage: return 0...1000
        case .time: return 0...3600
        case .length: return 0...10000
        }
    }
    func step(for field: InputTarget) -> Double {
        switch field {
        case .voltage: return 0.1
        default: return 1.0
        }
    
    }
    func selectProcess(_ process: WeldingProcess) {
        selectedProcessName = process.name
        efficiency = process.kFactor
        voltageStr = process.defaultVoltage
        amperageStr = process.defaultAmperage
        if timeStr.isEmpty { timeStr = "60" }
        if lengthStr.isEmpty { lengthStr = "300" }
        Haptics.selection()
    }
    
    // --- PERSISTENS LOGIKK ---
    
    func restoreActiveJob() {
        if let id = activeJobID {
            if let existingJob = jobHistory.first(where: { $0.id == id }) {
                currentJobName = existingJob.name
                passCounter = existingJob.passes.count + 1
            } else {
                activeJobID = nil
                currentJobName = ""
                passCounter = 1
            }
        }
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
                if !currentJobName.isEmpty && currentJobName != job.name {
                    job.name = currentJobName
                }
            } else {
                let name = currentJobName.isEmpty ? "Job \(Date().formatted(.dateTime.day().month().hour().minute()))" : currentJobName
                job = WeldGroup(name: name)
                modelContext.insert(job)
                activeJobID = job.id
                currentJobName = name
            }
            
            let newPass = SavedCalculation(
                name: "Pass #\(passCounter)",
                resultValue: String(format: "%.2f kJ/mm", heatInput),
                category: "HeatInput",
                voltage: voltageStr.toDouble,
                amperage: amperageStr.toDouble,
                travelTime: timeStr.toDouble,
                weldLength: lengthStr.toDouble,
                calculatedHeat: heatInput
            )
            
            newPass.group = job
            passCounter += 1
            
            job.date = Date()
            
            try? modelContext.save()
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
}

// --- JOB ROW ---
struct RetroJobRow: View {
    let job: WeldGroup
    let isActive: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(job.name).font(RetroTheme.font(size: 16, weight: .bold)).foregroundColor(isActive ? Color.green : RetroTheme.primary)
                    if isActive { Text("• LOGGING").font(RetroTheme.font(size: 9, weight: .bold)).foregroundColor(.green) }
                }
                Text("\(job.passes.count) passes recorded").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
            }
            Spacer()
            Text(job.date, format: .dateTime.day().month()).font(RetroTheme.font(size: 12)).foregroundColor(RetroTheme.dim)
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(RetroTheme.dim)
        }
        .padding(12).overlay(Rectangle().stroke(isActive ? Color.green : RetroTheme.dim.opacity(0.5), lineWidth: 1)).background(Color.black.opacity(0.3))
    }
}
