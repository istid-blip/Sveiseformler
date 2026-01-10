import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // --- LAGREDE INNSTILLINGER ---
    // Språk (no = Norsk, en = Engelsk)
    @AppStorage("app_language") private var selectedLanguage: String = "no"
    
    // Visuelt
    @AppStorage("enable_crt_effect") private var enableCRT: Bool = true
    @AppStorage("enable_haptics") private var enableHaptics: Bool = true
    
    // Standarder
    @AppStorage("default_process_code") private var defaultProcess: String = "135/136"
    
    // Bekreftelse for sletting
    @State private var showDeleteConfirmation = false
    
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
                    Text("SYSTEM_CONFIG")
                        .font(RetroTheme.font(size: 16, weight: .heavy))
                        .foregroundColor(RetroTheme.primary)
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // --- SECTION 1: LOCALIZATION ---
                        SettingsSection(title: "LOCALIZATION") {
                            HStack {
                                Text("LANGUAGE:")
                                    .font(RetroTheme.font(size: 14))
                                    .foregroundColor(RetroTheme.primary)
                                Spacer()
                                
                                // Egen "Radio Button" løsning for retro look
                                HStack(spacing: 0) {
                                    LanguageButton(title: "NOR", code: "no", selected: $selectedLanguage)
                                    Rectangle().fill(RetroTheme.primary).frame(width: 1, height: 20)
                                    LanguageButton(title: "ENG", code: "en", selected: $selectedLanguage)
                                }
                                .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                            }
                        }
                        
                        // --- SECTION 2: DISPLAY & HAPTICS ---
                        SettingsSection(title: "DISPLAY & I/O") {
                            // CRT Toggle
                            RetroToggleRow(title: "CRT SCANLINES", isOn: $enableCRT)
                            
                            // Haptics Toggle
                            RetroToggleRow(title: "HAPTIC FEEDBACK", isOn: $enableHaptics)
                        }
                        
                        // --- SECTION 3: DEFAULTS ---
                        SettingsSection(title: "DEFAULTS") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("DEFAULT PROCESS CODE:")
                                    .font(RetroTheme.font(size: 12))
                                    .foregroundColor(RetroTheme.dim)
                                
                                // Enkel input for nå, kan byttes med dropdown senere
                                TextField("135...", text: $defaultProcess)
                                    .font(RetroTheme.font(size: 14))
                                    .foregroundColor(RetroTheme.primary)
                                    .padding(8)
                                    .background(Color.black)
                                    .overlay(Rectangle().stroke(RetroTheme.dim, lineWidth: 1))
                            }
                        }
                        
                        // --- SECTION 4: DATA MANAGEMENT ---
                        SettingsSection(title: "MEMORY BANK") {
                            Button(action: { showDeleteConfirmation = true }) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("FACTORY RESET / WIPE DATA")
                                }
                                .font(RetroTheme.font(size: 12, weight: .bold))
                                .foregroundColor(.red) // Rød tekst for fare
                                .padding()
                                .frame(maxWidth: .infinity)
                                .overlay(Rectangle().stroke(Color.red, lineWidth: 1))
                            }
                        }
                        
                        // --- FOOTER INFO ---
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
        .crtScreen() // Bruker effekten her også (med mindre vi skrur den av, se logikk under)
        .navigationBarHidden(true)
        .alert("CONFIRM WIPE", isPresented: $showDeleteConfirmation) {
            Button("CANCEL", role: .cancel) { }
            Button("DELETE EVERYTHING", role: .destructive) {
                // Her kan du legge inn funksjon for å slette alt fra SwiftData
            }
        } message: {
            Text("This will permanently delete all saved weld logs and jobs. This action cannot be undone.")
        }
    }
}

// --- HJELPEKOMPONENTER FOR SETTINGS ---

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
    let title: String
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
                    
                    // En liten "LED" indikator
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

struct LanguageButton: View {
    let title: String
    let code: String
    @Binding var selected: String
    
    var body: some View {
        Button(action: { selected = code }) {
            Text(title)
                .font(RetroTheme.font(size: 12, weight: selected == code ? .bold : .regular))
                .foregroundColor(selected == code ? Color.black : RetroTheme.primary)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(selected == code ? RetroTheme.primary : Color.black)
        }
    }
}
