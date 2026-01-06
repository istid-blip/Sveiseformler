import SwiftUI
import SwiftData

struct CarbonEquivalentView: View {
    // 1. Navigation & Context
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // 2. Query History
    @Query(filter: #Predicate<SavedCalculation> { $0.category == "CE" },
           sort: \SavedCalculation.timestamp, order: .reverse)
    private var history: [SavedCalculation]
    
    // 3. Inputs (Persisted)
    @AppStorage("ce_c") private var c: String = ""
    @AppStorage("ce_mn") private var mn: String = ""
    @AppStorage("ce_cr") private var cr: String = ""
    @AppStorage("ce_mo") private var mo: String = ""
    @AppStorage("ce_v") private var v: String = ""
    @AppStorage("ce_ni") private var ni: String = ""
    @AppStorage("ce_cu") private var cu: String = ""
    
    @State private var customName: String = ""
    
    // 4. Logic (IIW Formula)
    var ceValue: Double {
        let C_val = Double(c) ?? 0
        let Mn_val = Double(mn) ?? 0
        let Cr_val = Double(cr) ?? 0
        let Mo_val = Double(mo) ?? 0
        let V_val = Double(v) ?? 0
        let Ni_val = Double(ni) ?? 0
        let Cu_val = Double(cu) ?? 0
        
        let part1 = Mn_val / 6.0
        let part2 = (Cr_val + Mo_val + V_val) / 5.0
        let part3 = (Ni_val + Cu_val) / 15.0
        return C_val + part1 + part2 + part3
    }
    
    var isCritical: Bool {
        return ceValue > 0.40
    }
    
    var body: some View {
        ZStack {
            // Background
            RetroTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // --- HEADER (With Back Button) ---
                    HStack {
                        Button(action: { dismiss() }) {
                            Text("< BACK")
                                .font(RetroTheme.font(size: 16, weight: .bold))
                                .foregroundColor(RetroTheme.primary)
                                .padding(5)
                                .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                        }
                        
                        Spacer()
                        
                        Text("MODULE: CARB_EQUIV")
                            .font(RetroTheme.font(size: 18, weight: .heavy))
                            .foregroundColor(RetroTheme.primary)
                    }
                    .padding(.top)
                    
                    Divider().background(RetroTheme.primary)
                    
                    // --- INPUTS: Base Elements ---
                    Text("> CHEMICAL COMPOSITION (%)")
                        .font(RetroTheme.font(size: 14, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                    
                    HStack(spacing: 15) {
                        RetroInputMini(title: "C", text: $c)
                        RetroInputMini(title: "Mn", text: $mn)
                    }
                    
                    // --- INPUTS: Alloys ---
                    Text("> ALLOYS (%)")
                        .font(RetroTheme.font(size: 14, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                        .padding(.top, 5)
                    
                    VStack(spacing: 15) {
                        HStack(spacing: 15) {
                            RetroInputMini(title: "Cr", text: $cr)
                            RetroInputMini(title: "Mo", text: $mo)
                            RetroInputMini(title: "V", text: $v)
                        }
                        HStack(spacing: 15) {
                            RetroInputMini(title: "Ni", text: $ni)
                            RetroInputMini(title: "Cu", text: $cu)
                            Spacer() // Fill empty space
                        }
                    }
                    
                    Divider().background(RetroTheme.dim)
                    
                    // --- RESULTS DISPLAY ---
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("CE VALUE >>")
                                .font(RetroTheme.font(size: 16))
                            Spacer()
                            Text(String(format: "%.3f", ceValue))
                                .font(RetroTheme.font(size: 24, weight: .bold))
                                .foregroundColor(isCritical ? Color.red : RetroTheme.primary) // Red if critical
                        }
                        
                        // WARNING BOX
                        if isCritical {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("WARNING: PRE-HEAT REQUIRED")
                            }
                            .font(RetroTheme.font(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.red) // Retro Red Background
                        }
                    }
                    .padding()
                    .overlay(
                        Rectangle().stroke(isCritical ? Color.red : RetroTheme.primary, lineWidth: 2)
                    )
                    
                    // --- SAVE SECTION ---
                    VStack(alignment: .leading, spacing: 10) {
                        Text("> ARCHIVE RESULT")
                            .font(RetroTheme.font(size: 14))
                            .foregroundColor(RetroTheme.primary)
                        
                        HStack {
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
                    
                    // --- HISTORY SECTION ---
                    Text("> LOGS (CE ONLY)")
                        .font(RetroTheme.font(size: 16, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                        .padding(.top, 10)
                    
                    VStack(spacing: 12) {
                        ForEach(history) { item in
                            RetroHistoryRow(item: item) {
                                deleteItem(item)
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
                .padding()
            }
        }
        .crtScreen() // Apply CRT Effect
        .scrollDismissesKeyboard(.immediately)
        .navigationBarHidden(true)
    }
    
    // --- ACTIONS ---
    
    func saveItem() {
        let val = String(format: "%.3f", ceValue)
        let newItem = SavedCalculation(name: customName, resultValue: val, category: "CE")
        modelContext.insert(newItem)
        customName = ""
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func deleteItem(_ item: SavedCalculation) {
        withAnimation {
            modelContext.delete(item)
        }
    }
}

// MARK: - Local Helper Views
// (I added a "Mini" version of the input field so 3 fit in a row)

struct RetroInputMini: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(RetroTheme.font(size: 12))
                .foregroundColor(RetroTheme.primary)
            
            TextField("", text: $text)
                .font(RetroTheme.font(size: 16))
                .foregroundColor(RetroTheme.primary)
                .keyboardType(.decimalPad)
                .padding(8)
                .background(Color.black)
                .overlay(
                    Rectangle()
                        .stroke(RetroTheme.dim, lineWidth: 1)
                )
        }
    }
}
