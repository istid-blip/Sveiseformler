import SwiftUI

// Hjelpestruktur for språkvalg i Dropdown
struct LanguageOption: Identifiable, Equatable {
    let id: String    // F.eks "no", "en"
    let name: String  // F.eks "NORSK (NO)"
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // --- LAGREDE INNSTILLINGER ---
    @AppStorage("app_language") private var selectedLanguage: String = "no"
    @AppStorage("enable_crt_effect") private var enableCRT: Bool = true
    @AppStorage("enable_haptics") private var enableHaptics: Bool = true
    @AppStorage("default_process_code") private var defaultProcess: String = "135/136"
    
    @State private var showDeleteConfirmation = false
    
    // Definisjon av tilgjengelige språk
    // Her er det superenkelt å legge til flere linjer senere!
    private let languageOptions = [
        LanguageOption(id: "no", name: "NORSK (NO)"),
        LanguageOption(id: "en", name: "ENGLISH (EN)")
    ]
    
    // Hjelper for å finne det valgte objektet basert på lagret ID
    var currentLanguageOption: LanguageOption {
        languageOptions.first(where: { $0.id == selectedLanguage }) ?? languageOptions[0]
    }
    
    var body: some View {
        ZStack {
            RetroTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- HEADER ---
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 5) {
                            Text("< MAIN MENU")
                        }
                        .font(RetroTheme.font(size: 14, weight: .bold))
                        .foregroundColor(RetroTheme.primary)
                        .padding(8)
                        .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                    }
                    Spacer()
                    Text("MACHINE_SETUP")
                        .font(RetroTheme.font(size: 16, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // --- SECTION 1: LOCALIZATION (Nå med RetroDropdown!) ---
                        SettingsSection(title: "LOCALIZATION") {
                            HStack(alignment: .top) {
                                Text("SYSTEM LANGUAGE:")
                                    .font(RetroTheme.font(size: 14))
                                    .foregroundColor(RetroTheme.primary)
                                    .padding(.top, 12) // Justerer teksten så den liner opp med knappen
                                
                                Spacer()
                                
                                // HER GJENBRUKER VI RETRO DROPDOWN
                                // Vi bruker zIndex for å sikre at menyen legger seg over ting nedenfor
                                VStack {
                                    RetroDropdown(
                                        title: "LANGUAGE",
                                        selection: currentLanguageOption,
                                        options: languageOptions,
                                        onSelect: { option in
                                            selectedLanguage = option.id
                                            // UIImpactFeedbackGenerator ligger allerede inne i RetroDropdown
                                        },
                                        itemText: { $0.name },
                                        itemDetail: nil // Vi trenger ingen detalj-tekst for språk
                                    )
                                }
                                .frame(width: 160) // Setter en fast bredde som passer menyen
                                .zIndex(100)       // Viktig for at dropdown ikke skal havne bak neste seksjon
                            }
                        }
                        .zIndex(100) // Viktig for at hele seksjonen skal ligge øverst
                        
                        // --- SECTION 2: DISPLAY & I/O ---
                        SettingsSection(title: "DISPLAY & I/O") {
                            RetroToggleRow(title: "CRT SCANLINES", isOn: $enableCRT)
                            RetroToggleRow(title: "HAPTIC FEEDBACK", isOn: $enableHaptics)
                        }
                        .zIndex(90)
                        
                        // --- SECTION 3: DEFAULTS ---
                        SettingsSection(title: "DEFAULTS") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("DEFAULT PROCESS CODE:")
                                    .font(RetroTheme.font(size: 12))
                                    .foregroundColor(RetroTheme.dim)
                                
                                TextField("135...", text: $defaultProcess)
                                    .font(RetroTheme.font(size: 14))
                                    .foregroundColor(RetroTheme.primary)
                                    .padding(8)
                                    .background(Color.black)
                                    .overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
                            }
                        }
                        .zIndex(80)
                        
                        // --- SECTION 4: RESET ---
                        SettingsSection(title: "MEMORY BANK") {
                            Button(action: { showDeleteConfirmation = true }) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("FACTORY RESET / WIPE DATA")
                                }
                                .font(RetroTheme.font(size: 12, weight: .bold))
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .overlay(Rectangle().stroke(Color.red, lineWidth: 1))
                            }
                        }
                        .zIndex(70)
                        
                        // --- FOOTER ---
                        VStack(spacing: 5) {
                            Text("Sveiseformler v1.0.2")
                            Text("System ID: \(UUID().uuidString.prefix(8))")
                        }
                        .font(RetroTheme.font(size: 10))
                        .foregroundColor(RetroTheme.dim)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
        }
        .crtScreen()
        .navigationBarHidden(true)
        .alert("CONFIRM WIPE", isPresented: $showDeleteConfirmation) {
            Button("CANCEL", role: .cancel) { }
            Button("DELETE EVERYTHING", role: .destructive) {
                // Her kan vi legge inn logikk for å slette alt i SwiftData senere
            }
        } message: {
            Text("This will permanently delete all saved weld logs and jobs.")
        }
    }
}

// --- HJELPERE (Beholdes som før) ---

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("> \(title)")
                .font(RetroTheme.font(size: 12, weight: .bold))
                .foregroundColor(RetroTheme.dim)
            content
        }
    }
}

struct RetroToggleRow: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(RetroTheme.font(size: 14))
                .foregroundColor(RetroTheme.primary)
            Spacer()
            
            Button(action: {
                isOn.toggle()
                if isOn { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
            }) {
                HStack(spacing: 8) {
                    Text(isOn ? "[ ON ]" : "  OFF  ")
                        .font(RetroTheme.font(size: 14, weight: .bold))
                    
                    Circle()
                        .fill(isOn ? RetroTheme.primary : Color.clear)
                        .stroke(RetroTheme.primary, lineWidth: 1)
                        .frame(width: 8, height: 8)
                        .shadow(color: isOn ? RetroTheme.primary : .clear, radius: 2)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .foregroundColor(isOn ? RetroTheme.primary : RetroTheme.dim)
                .overlay(Rectangle().stroke(RetroTheme.dim.opacity(0.5), lineWidth: 1))
            }
        }
    }
}
