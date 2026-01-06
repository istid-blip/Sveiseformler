import Foundation
import SwiftData

@Model
class DictionaryTerm {
    var english: String
    var translation: String
    var languageCode: String // e.g., "NO" for Norwegian
    
    init(english: String, translation: String, languageCode: String = "NO") {
        self.english = english
        self.translation = translation
        self.languageCode = languageCode
    }
}
