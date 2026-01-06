import Foundation
import SwiftData

@Model
class SavedCalculation {
    var id: UUID
    var name: String
    var resultValue: String
    var timestamp: Date
    var category: String // "Heat" or "CE"
    
    init(name: String, resultValue: String, category: String) {
        self.id = UUID()
        self.name = name
        self.resultValue = resultValue
        self.timestamp = Date()
        self.category = category
    }
}
