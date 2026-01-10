import SwiftUI
import SwiftData

@main
struct SveiseformlerApp: App {
    // 1. Hent valgt språk (standard "no" for norsk)
    @AppStorage("app_language") private var languageCode: String = "no"

    var sharedModelContainer: ModelContainer = {
        // VIKTIG: Legg til WeldGroup.self her for at jobbhistorikken skal virke!
        let schema = Schema([
            SavedCalculation.self,
            DictionaryTerm.self,
            WeldGroup.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 2. Her injiserer vi språket til hele appen!
                .environment(\.locale, Locale(identifier: languageCode))
        }
        .modelContainer(sharedModelContainer)
    }
}
