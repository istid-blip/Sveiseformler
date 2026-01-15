import SwiftUI
import SwiftData

@main
struct SveiseformlerApp: App {
    // 1. Hent valgt språk. Merk at vi endret default til "nb" tidligere.
    @AppStorage("app_language") private var languageCode: String = "nb"

    var sharedModelContainer: ModelContainer = {
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
                // 2. Setter språket i miljøet
                .environment(\.locale, Locale(identifier: languageCode))
                // 3. DETTE ER TRIKSET:
                // Ved å sette .id til språkkoden, tvinger vi hele appen til
                // å lastes inn på nytt når språket endres.
                .id(languageCode)
        }
        .modelContainer(sharedModelContainer)
    }
}
