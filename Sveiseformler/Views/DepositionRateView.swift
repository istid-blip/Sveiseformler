import SwiftUI
import SwiftData

struct DepositionRateView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Filter history for "Deposition" category
    @Query(filter: #Predicate<SavedCalculation> { $0.category == "Deposition" },
           sort: \SavedCalculation.timestamp, order: .reverse)
    private var history: [SavedCalculation]
    
    // --- Inputs ---
    // Using String for flexibility in text fields, mimicking the retro console input style
    @AppStorage("dep_wireDiameter") private var wireDiameter: String = ""
    @AppStorage("dep_wfs") private var wfs: String = ""
    @AppStorage("dep_efficiency") private var efficiency: Double = 0.95
    @AppStorage("dep_density") private var materialDensity: Double = 7.85
    
    @State private var customName: String = ""
    
    // --- Calculation Logic ---
    var depositionRate: Double {
        // Replace comma with dot to handle European keyboards
        let d = Double(wireDiameter.replacingOccurrences(of: ",", with: ".")) ?? 0
        let speed = Double(wfs.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        // 1. Area = pi * r^2 (mm^2)
        let radius = d / 2.0
        let areaMm2 = Double.pi * (radius * radius)
        
        // 2. Volume per hour (cm^3/hr)
        // m/min -> cm/hr: (speed * 100) * 60
        let lengthCmPerHour = (speed * 100) * 60
        
        // Area mm^2 -> cm^2: divide by 100
        let areaCm2 = areaMm2 / 100.0
        
        let volumeCm3 = areaCm2 * lengthCmPerHour
        
        // 3. Weight (kg) = Volume * Density / 1000
        let weightKg = (volumeCm3 * materialDensity) / 1000.0
        
        return weightKg * efficiency
    }
    
    var body: some View {
        ZStack {
            // Retro Background
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
                    Text("DEPOSITION_RATE")
                        .font(RetroTheme.font(size: 16, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // --- RESULT DISPLAY ---
                        VStack(spacing: 5) {
                            Text("OUTPUT (kg/h)")
                                .font(RetroTheme.font(size: 12))
                                .foregroundColor(RetroTheme.dim)
                            
                            Text(String(format: "%.2f", depositionRate))
                                .font(RetroTheme.font(size: 50, weight: .black))
                                .foregroundColor(RetroTheme.primary)
                                .shadow(color: RetroTheme.primary.opacity(0.5), radius: 5)
                            
                            // Efficiency & Material info
                            HStack {
                                Text("Eff: \(Int(efficiency * 100))%")
                                Text("|")
                                Text("Dens: \(String(format: "%.2f", materialDensity))")
                            }
                            .font(RetroTheme.font(size: 12))
                            .foregroundColor(RetroTheme.dim)
                        }
                        .padding(.top, 10)
                        
                        // --- INPUT SECTION ---
                        VStack(spacing: 20) {
                            
                            // Row 1: Wire Diameter & WFS
                            HStack(spacing: 15) {
                                RetroInputBlock(label: "DIAMETER (mm)", placeholder: "1.2", text: $wireDiameter)
                                RetroInputBlock(label: "WFS (m/min)", placeholder: "10.5", text: $wfs)
                            }
                            
                            // Row 2: Material Selection
                            VStack(alignment: .leading, spacing: 5) {
                                Text("MATERIAL TYPE")
                                    .font(RetroTheme.font(size: 10))
                                    .foregroundColor(RetroTheme.dim)
                                
                                Menu {
                                    Button("Carbon Steel (7.85)") { materialDensity = 7.85 }
                                    Button("Stainless Steel (8.00)") { materialDensity = 8.00 }
                                    Button("Aluminum (2.70)") { materialDensity = 2.70 }
                                } label: {
                                    HStack {
                                        Text(materialName(for: materialDensity))
                                            .font(RetroTheme.font(size: 16, weight: .bold))
                                        Spacer()
                                        Text("▼")
                                            .font(RetroTheme.font(size: 10))
                                    }
                                    .padding()
                                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                                    .foregroundColor(RetroTheme.primary)
                                }
                            }
                            
                            // Row 3: Efficiency Selection
                            VStack(alignment: .leading, spacing: 5) {
                                Text("WELDING PROCESS (EFFICIENCY)")
                                    .font(RetroTheme.font(size: 10))
                                    .foregroundColor(RetroTheme.dim)
                                
                                Menu {
                                    Button("MAG / Solid Wire (95%)") { efficiency = 0.95 }
                                    Button("FCAW / Flux Core (85%)") { efficiency = 0.85 }
                                    Button("SMAW / Stick (60%)") { efficiency = 0.60 }
                                } label: {
                                    HStack {
                                        Text(efficiencyName(for: efficiency))
                                            .font(RetroTheme.font(size: 16, weight: .bold))
                                        Spacer()
                                        Text("▼")
                                            .font(RetroTheme.font(size: 10))
                                    }
                                    .padding()
                                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                                    .foregroundColor(RetroTheme.primary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider().background(RetroTheme.dim)
                        
                        // --- SAVE & HISTORY ---
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
                                .disabled(customName.isEmpty || depositionRate == 0)
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
                }
            }
        }
        .crtScreen() // The scanline magic
        .navigationBarHidden(true)
    }
    
    // --- Helpers ---
    
    func materialName(for density: Double) -> String {
        switch density {
        case 7.85: return "CARBON STEEL (7.85)"
        case 8.00: return "STAINLESS (8.00)"
        case 2.70: return "ALUMINUM (2.70)"
        default: return "CUSTOM (\(density))"
        }
    }
    
    func efficiencyName(for eff: Double) -> String {
        switch eff {
        case 0.95: return "MAG/SOLID (0.95)"
        case 0.85: return "FCAW (0.85)"
        case 0.60: return "SMAW/STICK (0.60)"
        default: return "CUSTOM (\(eff))"
        }
    }
    
    func saveItem() {
        let val = String(format: "%.2f kg/hr", depositionRate)
        let newItem = SavedCalculation(name: customName, resultValue: val, category: "Deposition")
        modelContext.insert(newItem)
        customName = ""
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func deleteItems(_ items: [SavedCalculation]) {
        withAnimation {
            for item in items {
                modelContext.delete(item)
            }
        }
    }
}

// Helper component for text inputs
struct RetroInputBlock: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(RetroTheme.font(size: 10))
                .foregroundColor(RetroTheme.dim)
            
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .font(RetroTheme.font(size: 18, weight: .bold))
                .foregroundColor(RetroTheme.primary)
                .padding()
                .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                .tint(RetroTheme.primary)
        }
    }
}

#Preview {
    DepositionRateView()
        .modelContainer(for: SavedCalculation.self, inMemory: true)
}
