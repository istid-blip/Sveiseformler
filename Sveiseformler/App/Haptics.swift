import SwiftUI

struct Haptics {
    
    // Nøkkelen vi bruker i UserDefaults
    private static let settingsKey = "enable_haptics"
    
    // Sjekker om haptics er påskrudd (default: true)
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: settingsKey) as? Bool ?? true
    }
    
    /// Kjører en standard "impact" vibrasjon (light, medium, heavy, rigid, soft)
    static func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Kjører en "notification" vibrasjon (success, warning, error)
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    /// Kjører en "selection" vibrasjon (f.eks. rullehjul)
    static func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
