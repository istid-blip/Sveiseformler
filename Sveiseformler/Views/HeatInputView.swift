import SwiftUI
import SwiftData
import Combine

// --- 1. SVEISEPROSESS ---
struct WeldingProcess: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let kFactor: Double
    let defaultVoltage: String
    let defaultAmperage: String
}

// --- 2. HOVEDVISNING (HeatInputView) ---
struct HeatInputView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // --- STATE ---
    enum InputTarget: String, Identifiable {
        case voltage, amperage, time, length
        var id: String { rawValue }
    }
    @State private var focusedField: InputTarget? = nil
    
    // --- NAVNGIVNING STATE ---
    @State private var isNamingJob: Bool = false
    @State private var tempJobName: String = ""
    @FocusState private var isJobNameFocused: Bool
    
    // --- DATA ---
    @Query(sort: \WeldGroup.date, order: .reverse) private var jobHistory: [WeldGroup]
    
    @AppStorage("heat_selected_process_name") private var selectedProcessName: String = "MAG / FCAW"
    @AppStorage("heat_voltage") private var voltageStr: String = ""
    @AppStorage("heat_amperage") private var amperageStr: String = ""
    @AppStorage("heat_time") private var timeStr: String = ""
    @AppStorage("heat_length") private var lengthStr: String = ""
    @AppStorage("heat_efficiency") private var efficiency: Double = 0.8
    @AppStorage("heat_pass_counter") private var passCounter: Int = 1
    @AppStorage("heat_active_job_id") private var storedJobID: String = ""
    @State private var currentJobName: String = ""
    
    // --- ROBUST STOPPEKLOKKE STATE ---
    @AppStorage("stopwatch_is_running") private var isTimerRunning: Bool = false
    @AppStorage("stopwatch_start_timestamp") private var timerStartTimestamp: Double = 0.0
    @AppStorage("stopwatch_accumulated_time") private var timerAccumulatedTime: Double = 0.0
    
    private let uiUpdateTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var activeJobID: UUID? {
        get { storedJobID.isEmpty ? nil : UUID(uuidString: storedJobID) }
        nonmutating set { storedJobID = newValue?.uuidString ?? "" }
    }
    
    // --- PROSESS DATA ---
    private let processes = [
        WeldingProcess(name: "SAW (Pulver)", code: "121", kFactor: 1.0, defaultVoltage: "30.0", defaultAmperage: "500"),
        WeldingProcess(name: "MMA (Pinne)", code: "111", kFactor: 0.8, defaultVoltage: "23.0", defaultAmperage: "120"),
        WeldingProcess(name: "MAG / FCAW", code: "135/136", kFactor: 0.8, defaultVoltage: "24.0", defaultAmperage: "200"),
        WeldingProcess(name: "TIG / GTAW", code: "141", kFactor: 0.6, defaultVoltage: "14.0", defaultAmperage: "110"),
        WeldingProcess(name: "Plasma", code: "15", kFactor: 0.6, defaultVoltage: "25.0", defaultAmperage: "150")
    ]
    
    var currentProcess: WeldingProcess { processes.first(where: { $0.name == selectedProcessName }) ?? processes[2] }

    var heatInput: Double {
        let v = voltageStr.toDouble; let i = amperageStr.toDouble; let t = timeStr.toDouble; let l = lengthStr.toDouble
        if l == 0 { return 0 }
        return ((v * i * t) / (l * 1000)) * efficiency
    }
    
    var calculatedSpeed: Double {
        let l = lengthStr.toDouble; let t = timeStr.toDouble
        return t == 0 ? 0 : (l / t) * 60
    }
    
    // --- BODY ---
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RetroTheme.background.ignoresSafeArea()
                
                ZStack {
                    VStack(spacing: 0) {
                        // HEADER
                        HStack {
                            Button(action: { dismiss() }) {
                                HStack(spacing: 5) { Text("< MAIN MENU") }
                                    .font(RetroTheme.font(size: 16, weight: .bold))
                                    .foregroundColor(RetroTheme.primary)
                                    .padding(8)
                                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                            }
                            Spacer(); Spacer()
                            Text("HEAT INPUT").font(RetroTheme.font(size: 16, weight: .heavy)).foregroundColor(RetroTheme.primary)
                        }.padding()
                        
                        // MAIN CONTENT
                        VStack(spacing: 25) {
                            // RESULTAT OMRÅDE
                            HStack(alignment: .top, spacing: 0) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("PROCESS").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                                    RetroDropdown(title: "PROCESS", selection: currentProcess, options: processes, onSelect: { selectProcess($0) }, itemText: { $0.name }, itemDetail: { "ISO 4063: \($0.code)" })
                                        .allowsHitTesting(focusedField == nil)
                                        .opacity(focusedField != nil ? 0.6 : 1.0)
                                    
                                }.frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
                                
                                Spacer(minLength: 20)
                                
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text("CURRENT PASS (kJ/mm)").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                                    Text(String(format: "%.2f", heatInput)).font(RetroTheme.font(size: 36, weight: .black)).foregroundColor(RetroTheme.primary).shadow(color: RetroTheme.primary.opacity(0.5), radius: 5).fixedSize(horizontal: true, vertical: true)
                                    if activeJobID != nil { Text("• LOGGING").font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(.red).blinkEffect() }
                                }.frame(minWidth: 160, alignment: .trailing)
                            }.padding(.horizontal).zIndex(1000)
                            
                            // INPUT / NAVNGIVNING BOKS
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isNamingJob ? Color.green.opacity(0.15) : Color.black.opacity(0.2))
                                    .stroke(isNamingJob ? Color.green : RetroTheme.dim, lineWidth: isNamingJob ? 2 : 1)
                                    .animation(.easeOut(duration: 0.2), value: isNamingJob)
                                
                                if isNamingJob {
                                    VStack(spacing: 15) {
                                        Text("SAVE JOB RECORD").font(RetroTheme.font(size: 12, weight: .bold)).foregroundColor(Color.green)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("JOB NAME / ID").font(RetroTheme.font(size: 9)).foregroundColor(Color.green.opacity(0.8))
                                            TextField("E.g. Project X-12", text: $tempJobName)
                                                .font(RetroTheme.font(size: 18, weight: .bold)).foregroundColor(Color.green).padding(10).background(Color.black.opacity(0.5)).overlay(Rectangle().stroke(Color.green, lineWidth: 1))
                                                .focused($isJobNameFocused).submitLabel(.done).onSubmit { finalizeAndSaveJob() }
                                        }.padding(.horizontal, 30)
                                        HStack(spacing: 20) {
                                            Button("UNDO / CANCEL") { withAnimation(.spring(response: 0.3)) { isNamingJob = false; isJobNameFocused = false } }
                                                .font(RetroTheme.font(size: 11, weight: .bold)).foregroundColor(Color.green.opacity(0.7))
                                            Button("SAVE & RESET") { finalizeAndSaveJob() }
                                                .font(RetroTheme.font(size: 11, weight: .bold)).foregroundColor(.black).padding(.horizontal, 16).padding(.vertical, 10).background(Color.green)
                                        }
                                    }.transition(.scale(scale: 0.95).combined(with: .opacity))
                                } else {
                                    VStack(spacing: 15) {
                                        HStack(alignment: .center, spacing: 8) {
                                            VStack(spacing: 0) {
                                                Text("ISO 17671").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
                                                Text(String(format: "%.1f", efficiency)).font(RetroTheme.font(size: 20, weight: .bold)).foregroundColor(RetroTheme.primary).padding(8)
                                                Text("k-factor").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
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
                                                Text("Speed: \(String(format: "%.0f", calculatedSpeed)) mm/min")
                                                                                                    .font(RetroTheme.font(size: 9))
                                                                                                    .foregroundColor(RetroTheme.dim)
                                                                                                    .padding(.trailing, 40)
                                            }
                                        }
                                    }.padding().transition(.scale(scale: 0.95).combined(with: .opacity))
                                }
                            }.padding(.horizontal).frame(height: 180).zIndex(1)
                            
                            // KNAPPER & HISTORIKK
                            HStack(spacing: 15) {
                                Button(action: {
                                    if activeJobID != nil { tempJobName = currentJobName; withAnimation { isNamingJob = true }; DispatchQueue.main.asyncAfter(deadline: .now()+0.1) { isJobNameFocused = true } } else { startNewSession() }
                                }) {
                                    VStack(spacing: 2) { Text("NEW JOB").font(RetroTheme.font(size: 12, weight: .bold)); Text(activeJobID != nil ? "FINISH" : "RESET").font(RetroTheme.font(size: 8)) }
                                        .foregroundColor(RetroTheme.primary).frame(width: 80, height: 50).overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1)).background(Color.black)
                                }
                                .disabled(isNamingJob)
                                .allowsHitTesting(focusedField == nil)
                                .opacity((isNamingJob || focusedField != nil) ? 0.3 : 1.0)
                                
                                Button(action: logPass) {
                                    HStack { Text("LOG PASS #\(passCounter)").font(RetroTheme.font(size: 20, weight: .heavy)); Spacer(); Image(systemName: "arrow.right.to.line") }
                                        .padding().foregroundColor(Color.black).background(heatInput > 0 ? RetroTheme.primary : RetroTheme.dim)
                                }.disabled(heatInput == 0 || isNamingJob)
                            }.padding(.horizontal)
                            
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
                                }.padding(.horizontal).padding(.bottom, 320)
                            }
                        }
                    }
                    .frame(height: geometry.size.height)
                    .offset(y: -5)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if focusedField != nil {
                            withAnimation { focusedField = nil }
                        }
                    }
                }
                
                if let target = focusedField {
                    VStack {
                        Spacer()
                        UnifiedInputDrawer(
                            target: target,
                            value: binding(for: target),
                            range: range(for: target),
                            step: step(for: target),
                            isRecording: $isTimerRunning,
                            onReset: resetStopwatch,
                            onToggle: toggleStopwatch
                        )
                        .padding(.bottom, 50)
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .id("DrawerContainer")
                    .transition(.move(edge: .bottom))
                    .zIndex(100)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarBackButtonHidden(true)
        .onAppear { restoreActiveJob() }
        .crtScreen()
        .onReceive(uiUpdateTimer) { _ in
            if isTimerRunning {
                let now = Date().timeIntervalSince1970
                let elapsed = now - timerStartTimestamp
                let total = timerAccumulatedTime + elapsed
                timeStr = String(format: "%.0f", total)
            }
        }
    }
    
    // --- STOPPEKLOKKE LOGIKK ---
    
    func toggleStopwatch() {
        if isTimerRunning {
            let now = Date().timeIntervalSince1970
            let elapsed = now - timerStartTimestamp
            timerAccumulatedTime += elapsed
            isTimerRunning = false
            Haptics.play(.medium)
        } else {
            timerStartTimestamp = Date().timeIntervalSince1970
            isTimerRunning = true
            Haptics.play(.heavy)
        }
    }
    
    func resetStopwatch() {
        isTimerRunning = false
        timerAccumulatedTime = 0
        timerStartTimestamp = 0
        timeStr = "0"
        Haptics.play(.medium)
    }
    
    // --- HJELPEFUNKSJONER ---
    @ViewBuilder func SelectableInput(label: String, value: Double, target: InputTarget, currentFocus: InputTarget?, precision: Int, action: @escaping () -> Void) -> some View {
        let isSelected = (currentFocus == target)
        Button(action: { withAnimation(.spring(response: 0.3)) { action(); Haptics.selection() } }) {
            VStack(spacing: 0) {
                Text(String(format: "%.\(precision)f", value)).font(RetroTheme.font(size: 24, weight: .bold)).foregroundColor(currentFocus != nil && !isSelected ? RetroTheme.dim : RetroTheme.primary).padding(.vertical, 4).frame(minWidth: 80).background(Color.black).overlay(Rectangle().stroke(currentFocus != nil && !isSelected ? RetroTheme.dim : RetroTheme.primary, lineWidth: isSelected ? 2 : 1))
                Text(label).font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim).padding(4).fixedSize(horizontal: true, vertical: false)
            }
        }.buttonStyle(PlainButtonStyle())
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
        switch field { case .voltage: return 0...100; case .amperage: return 0...1000; case .time: return 0...3600; case .length: return 0...10000 }
    }
    func step(for field: InputTarget) -> Double { return field == .voltage ? 0.1 : 1.0 }
    
    func selectProcess(_ process: WeldingProcess) {
        selectedProcessName = process.name; efficiency = process.kFactor; voltageStr = process.defaultVoltage; amperageStr = process.defaultAmperage
        if timeStr.isEmpty { timeStr = "60" }; if lengthStr.isEmpty { lengthStr = "300" }; Haptics.selection()
    }
    func restoreActiveJob() { if let id = activeJobID, let existingJob = jobHistory.first(where: { $0.id == id }) { currentJobName = existingJob.name; passCounter = existingJob.passes.count + 1 } else { activeJobID = nil; currentJobName = ""; passCounter = 1 } }
    func startNewSession() { activeJobID = nil; passCounter = 1; currentJobName = ""; Haptics.play(.medium) }
    func finalizeAndSaveJob() { if let id = activeJobID, let existingJob = jobHistory.first(where: { $0.id == id }) { existingJob.name = tempJobName.isEmpty ? "Job \(Date().formatted(.dateTime.day().month().hour().minute()))" : tempJobName; try? modelContext.save() }; withAnimation(.spring(response: 0.3)) { isNamingJob = false; isJobNameFocused = false }; startNewSession(); UINotificationFeedbackGenerator().notificationOccurred(.success) }
    
    // --- OPPDATERT LOG PASS FUNKSJON ---
    func logPass() {
        // 1. Frys tiden hvis den går, slik at vi logger nøyaktig verdi
        if isTimerRunning {
            let now = Date().timeIntervalSince1970
            let elapsed = now - timerStartTimestamp
            timerAccumulatedTime += elapsed
            timeStr = String(format: "%.0f", timerAccumulatedTime)
            isTimerRunning = false
        }
        
        // 2. Lagre jobben (Bruker current values)
        let job: WeldGroup
        if let id = activeJobID, let existingJob = jobHistory.first(where: { $0.id == id }) { job = existingJob; if !currentJobName.isEmpty && currentJobName != job.name { job.name = currentJobName } }
        else { let name = currentJobName.isEmpty ? "Job \(Date().formatted(.dateTime.day().month().hour().minute()))" : currentJobName; job = WeldGroup(name: name); modelContext.insert(job); activeJobID = job.id; currentJobName = name }
        let newPass = SavedCalculation(name: "Pass #\(passCounter)", resultValue: String(format: "%.2f kJ/mm", heatInput), category: "HeatInput", voltage: voltageStr.toDouble, amperage: amperageStr.toDouble, travelTime: timeStr.toDouble, weldLength: lengthStr.toDouble, calculatedHeat: heatInput)
        newPass.group = job; passCounter += 1; job.date = Date(); try? modelContext.save(); UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        // 3. RESETT KLOKKEN (Klar for neste sveis)
        timerAccumulatedTime = 0
        timerStartTimestamp = 0
        timeStr = "0"
    }
}

// --- 3. UNIFIED INPUT DRAWER ---
struct UnifiedInputDrawer: View {
    let target: HeatInputView.InputTarget
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    
    // Stoppeklokke kontroll
    @Binding var isRecording: Bool
    var onReset: () -> Void
    var onToggle: () -> Void
    
    @State private var pulseOpacity = 1.0
    
    // Jogger State
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    private let friction: Double = 12.0
    private let spacing: CGFloat = 20
    private let visibleTicks: Int = 5
    
    var body: some View {
        ZStack {
            // STATISK BAKGRUNN (Sikrer stabilitet)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .frame(width: 320, height: 280)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RetroTheme.dim, lineWidth: 1))
                .shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 15)
            
            // INNHOLDS-BYTTE (Med Cross-Fade)
            Group {
                if target == .time {
                    // --- STOPPEKLOKKE INNHOLD ---
                    VStack(spacing: 20) {
                        HStack {
                            Text("STOPWATCH").font(RetroTheme.font(size: 12, weight: .bold)).foregroundColor(RetroTheme.dim)
                            Spacer()
                            if isRecording {
                                HStack(spacing: 6) {
                                    Circle().fill(Color.red).frame(width: 8, height: 8).opacity(pulseOpacity)
                                    Text("REC").font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(.red)
                                }.onAppear { withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { pulseOpacity = 0.3 } }
                            }
                        }.padding(.horizontal, 30).padding(.top, 10)
                        
                        Spacer()
                        Text(String(format: "%02d", Int(value))).font(.system(size: 70, weight: .black, design: .monospaced)).foregroundColor(isRecording ? .red : RetroTheme.primary).shadow(color: (isRecording ? Color.red : RetroTheme.primary).opacity(0.3), radius: 10).contentTransition(.numericText(value: value))
                        Text("SECONDS").font(RetroTheme.font(size: 10, weight: .bold)).foregroundColor(RetroTheme.dim).offset(y: -10)
                        Spacer()
                        
                        HStack(spacing: 30) {
                            Button(action: onReset) {
                                VStack { Image(systemName: "arrow.counterclockwise").font(.title2); Text("RESET").font(RetroTheme.font(size: 9, weight: .bold)) }
                                    .foregroundColor(RetroTheme.dim).frame(width: 80, height: 60).overlay(RoundedRectangle(cornerRadius: 8).stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1))
                            }
                            Button(action: {
                                onToggle()
                                if !isRecording { pulseOpacity = 1.0 }
                            }) {
                                ZStack {
                                    Circle().fill(isRecording ? Color.red.opacity(0.2) : RetroTheme.primary.opacity(0.2)).frame(width: 70, height: 70)
                                    Circle().stroke(isRecording ? Color.red : RetroTheme.primary, lineWidth: 2).frame(width: 70, height: 70)
                                    Image(systemName: isRecording ? "stop.fill" : "play.fill").font(.title).foregroundColor(isRecording ? .red : RetroTheme.primary)
                                }
                            }
                        }.padding(.bottom, 30)
                    }
                    .frame(width: 320, height: 280)
                    .transition(.opacity)
                    
                } else {
                    // --- RULLEHJUL INNHOLD ---
                    VStack {
                        GeometryReader { geo in
                            let midY = geo.size.height / 2
                            ZStack {
                                ForEach(getVisibleIndices(), id: \.self) { index in
                                    let distanceFromCenter = (CGFloat(index) - CGFloat(value / step)) * spacing
                                    let yPos = midY + distanceFromCenter
                                    if yPos > -20 && yPos < geo.size.height + 20 {
                                        HStack { Rectangle().fill(RetroTheme.primary).frame(width: isMajorTick(Double(index)) ? 80 : 40, height: 2) }
                                            .position(x: geo.size.width / 2, y: yPos)
                                            .opacity(calculateOpacity(yPos: yPos, height: geo.size.height))
                                            .scaleEffect(x: calculateScale(yPos: yPos, height: geo.size.height))
                                    }
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(Rectangle().fill(RetroTheme.primary.opacity(0.1)).frame(height: 24).overlay(Rectangle().stroke(RetroTheme.primary.opacity(0.5), lineWidth: 1)).allowsHitTesting(false))
                    }
                    .frame(width: 320, height: 280)
                    .transition(.opacity)
                    // HER ER FIKSEN: Vi gjør hele flaten trykkbar, selv der det er tomt/gjennomsiktig
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let delta = gesture.translation.height - lastDragValue
                                dragOffset += delta
                                let stepsToTake = Int(dragOffset / friction)
                                if stepsToTake != 0 {
                                    let velocity = abs(delta)
                                    var multiplier: Double = 1.0
                                    if velocity > 25 { multiplier = 10.0 } else if velocity > 10 { multiplier = 5.0 } else if velocity > 4 { multiplier = 2.0 }
                                    let change = -1.0 * Double(stepsToTake) * step * multiplier
                                    let newValue = value + change
                                    if range.contains(newValue) { value = (newValue * 100).rounded() / 100; Haptics.selection() }
                                    dragOffset -= Double(stepsToTake) * friction
                                }
                                lastDragValue = gesture.translation.height
                            }
                            .onEnded { _ in lastDragValue = 0; dragOffset = 0 }
                    )
                }
            }
        }
    }
    
    // Jogger Helpers
    private func getVisibleIndices() -> [Int] {
        let centerIndex = Int(value / step)
        return (centerIndex - visibleTicks - 2 ... centerIndex + visibleTicks + 2).map { $0 }
    }
    private func isMajorTick(_ index: Double) -> Bool { Int(index) % 5 == 0 }
    private func calculateOpacity(yPos: CGFloat, height: CGFloat) -> Double {
        let distance = abs((height/2) - yPos); let threshold = (height/2) - 10
        return distance > threshold ? 0 : Double(1 - (distance / threshold))
    }
    private func calculateScale(yPos: CGFloat, height: CGFloat) -> CGFloat {
        return 1.0 - (abs((height/2) - yPos) / height) * 0.3
    }
}

// --- 4. JOB ROW (For history) ---
struct RetroJobRow: View {
    let job: WeldGroup; let isActive: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack { Text(job.name).font(RetroTheme.font(size: 16, weight: .bold)).foregroundColor(isActive ? Color.green : RetroTheme.primary); if isActive { Text("• LOGGING").font(RetroTheme.font(size: 9, weight: .bold)).foregroundColor(.green) } }
                Text("\(job.passes.count) passes recorded").font(RetroTheme.font(size: 10)).foregroundColor(RetroTheme.dim)
            }
            Spacer(); Text(job.date, format: .dateTime.day().month()).font(RetroTheme.font(size: 12)).foregroundColor(RetroTheme.dim); Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(RetroTheme.dim)
        }.padding(12).overlay(Rectangle().stroke(isActive ? Color.green : RetroTheme.dim.opacity(0.5), lineWidth: 1)).background(Color.black.opacity(0.3))
    }
}
