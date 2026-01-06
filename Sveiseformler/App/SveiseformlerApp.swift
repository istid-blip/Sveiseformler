import SwiftUI
import SwiftData // <--- Don't forget this!

@main
struct SveiseformlerApp: App { // Your struct name might be different
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SavedCalculation.self, DictionaryTerm.self])
    }
}
