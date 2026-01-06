import SwiftUI
import SwiftData

struct DictionaryView: View {
    // 1. Environment & Data
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // 2. Query (Your existing logic)
    @Query(sort: \DictionaryTerm.english) var terms: [DictionaryTerm]
    
    @State private var searchText = ""
    
    // 3. Search Logic
    var filteredTerms: [DictionaryTerm] {
        if searchText.isEmpty {
            return terms
        } else {
            return terms.filter {
                $0.english.localizedStandardContains(searchText) ||
                $0.translation.localizedStandardContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            RetroTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // --- HEADER ---
                VStack(spacing: 10) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Text("< BACK")
                                .font(RetroTheme.font(size: 16, weight: .bold))
                                .foregroundColor(RetroTheme.primary)
                                .padding(5)
                                .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 1))
                        }
                        
                        Spacer()
                        
                        Text("DATABASE_SEARCH")
                            .font(RetroTheme.font(size: 18, weight: .heavy))
                            .foregroundColor(RetroTheme.primary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // --- SEARCH BAR (Terminal Style) ---
                    HStack {
                        Text("> QUERY:")
                            .font(RetroTheme.font(size: 16, weight: .bold))
                            .foregroundColor(RetroTheme.primary)
                        
                        TextField("ENGLISH OR NORSK...", text: $searchText)
                            .font(RetroTheme.font(size: 16))
                            .foregroundColor(RetroTheme.primary)
                            .accentColor(RetroTheme.primary)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.square.fill")
                                    .foregroundColor(RetroTheme.primary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.black)
                    .overlay(Rectangle().stroke(RetroTheme.primary, lineWidth: 2))
                    .padding(.horizontal)
                }
                .padding(.bottom, 10)
                
                Divider().background(RetroTheme.primary)
                
                // --- RESULTS LIST ---
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if filteredTerms.isEmpty {
                            // Empty State
                            VStack(spacing: 20) {
                                Text(terms.isEmpty ? "INITIALIZING DATABASE..." : "NO MATCHES FOUND")
                                    .font(RetroTheme.font(size: 16))
                                    .foregroundColor(RetroTheme.dim)
                                    .padding(.top, 50)
                            }
                        } else {
                            // List Items
                            ForEach(filteredTerms) { item in
                                RetroTermRow(item: item)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadJSONIfNeeded()
        }
        .crtScreen() // Apply CRT Effect
        .navigationBarHidden(true)
    }
    
    // --- SILENT LOADER (Your Logic) ---
    func loadJSONIfNeeded() {
        guard terms.isEmpty else { return }
        
        guard let url = Bundle.main.url(forResource: "welding_terms_no", withExtension: "json") else {
            print("❌ Critical: JSON file missing.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decodedTerms = try JSONDecoder().decode([TermDTO].self, from: data)
            
            for dto in decodedTerms {
                let newTerm = DictionaryTerm(
                    english: dto.english,
                    translation: dto.translation,
                    languageCode: dto.languageCode
                )
                modelContext.insert(newTerm)
            }
            
            try? modelContext.save()
            print("✅ Database initialized with \(decodedTerms.count) terms.")
            
        } catch {
            print("❌ Error loading dictionary: \(error)")
        }
    }
}

// MARK: - Subviews

struct RetroTermRow: View {
    let item: DictionaryTerm
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                // English
                Text(item.english.uppercased())
                    .font(RetroTheme.font(size: 16, weight: .bold))
                    .foregroundColor(RetroTheme.primary)
                
                // Translation
                HStack {
                    Text("NO >")
                        .font(RetroTheme.font(size: 12))
                        .foregroundColor(RetroTheme.dim)
                    Text(item.translation)
                        .font(RetroTheme.font(size: 14))
                        .foregroundColor(RetroTheme.primary.opacity(0.8))
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.black)
        .overlay(
            Rectangle().stroke(RetroTheme.dim, lineWidth: 1)
        )
    }
}

// Helper struct for JSON decoding
struct TermDTO: Codable {
    let english: String
    let translation: String
    let languageCode: String
}
