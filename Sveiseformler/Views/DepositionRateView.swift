import SwiftUI
import SwiftData

struct DepositionRateView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Filter history for "Deposition" category
    @Query(filter: #Predicate<SavedCalculation> { $0.category == "Deposition" },
           sort: \SavedCalculation.timestamp, order: .reverse)
    private var history: [SavedCalculation]
    
    // --- Inputs ---
    @AppStorage("dep_wireDiameter") private var wireDiameter: String = ""
        @AppStorage("dep_wfs") private var wfs: String = ""
        @AppStorage("dep_efficiency") private var efficiency: Double = 0.95
        @AppStorage("dep_density") private var materialDensity: Double = 7.85
    
    @State private var customName: String = ""
    
    // --- Calculation Logic ---
    var depositionRate: Double {
        let d = Double(wireDiameter) ?? 0
        let speed = Double(wfs) ?? 0
        
        // 1. Calculate Wire Cross-Section Area (mm^2)
        // Area = pi * r^2
        let radius = d / 2.0
        let areaMm2 = Double.pi * (radius * radius)
        
        // 2. Volume per hour (cm^3/hr)
        // Convert speed m/min -> cm/hr: (speed * 100) * 60
        let lengthCmPerHour = (speed * 100) * 60
        
        // Convert Area mm^2 -> cm^2: divide by 100
        let areaCm2 = areaMm2 / 100.0
        
        let volumeCm3 = areaCm2 * lengthCmPerHour
        
        // 3. Weight (kg)
        // Weight = Volume * Density (g/cm^3)
        // Divide by 1000 to get kg
        let weightKg = (volumeCm3 * materialDensity) / 1000.0
        
        return weightKg * efficiency
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Wire Parameters")) {
                    HStack {
                        Text("Wire Diameter (mm)")
                        Spacer()
                        TextField("e.g. 1.2", text: $wireDiameter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Wire Feed Speed (m/min)")
                            .font(.caption) // Smaller font if text is long
                        Spacer()
                        TextField("e.g. 10.5", text: $wfs)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Material & Process")) {
                    // Material Picker changes the Density
                    Picker("Material", selection: $materialDensity) {
                        Text("Carbon Steel (7.85)").tag(7.85)
                        Text("Stainless Steel (8.00)").tag(8.00)
                        Text("Aluminum (2.70)").tag(2.70)
                    }
                    
                    // Efficiency Picker
                    Picker("Process Efficiency", selection: $efficiency) {
                        Text("MAG/Solid Wire (95%)").tag(0.95)
                        Text("FCAW/Flux Core (85%)").tag(0.85)
                        Text("Stick/SMAW (60%)").tag(0.60)
                    }
                }
                
                Section(header: Text("Result")) {
                    HStack {
                        Text("Deposition Rate:")
                            .fontWeight(.bold)
                        Spacer()
                        Text(String(format: "%.2f kg/hr", depositionRate))
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
                
                Section(header: Text("Save Result")) {
                    HStack {
                        TextField("Name (e.g. Root Pass)", text: $customName)
                        Button("Save") {
                            saveItem()
                        }
                        .disabled(customName.isEmpty || depositionRate == 0)
                        .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("History")) {
                    ForEach(history) { item in
                        HistoryPillRow(item: item)
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("Deposition Rate")
        }
        .scrollDismissesKeyboard(.immediately) // iOS 16+ feature
    }
    
    func saveItem() {
        let val = String(format: "%.2f kg/hr", depositionRate)
        let newItem = SavedCalculation(name: customName, resultValue: val, category: "Deposition")
        modelContext.insert(newItem)
        customName = ""
    }
    
    func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(history[index])
        }
    }
}

#Preview {
    DepositionRateView()
        .modelContainer(for: SavedCalculation.self, inMemory: true)
}
