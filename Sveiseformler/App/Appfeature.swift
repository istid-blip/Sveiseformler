//
//  Appfeature.swift
//  Sveiseformler
//
//  Created by Frode Halrynjo on 13/01/2026.
//

import SwiftUI

// Dette er en liste over alle verktøyene vi kan flytte på
enum AppFeature: String, Identifiable, CaseIterable {
    case heatInput
    case carbonEquivalent
    case schaeffler
    case depositionRate
    case dictionary
    
    var id: String { rawValue }
    
    // Teksten som vises i menyen
    var title: String {
        switch self {
        case .heatInput: return "HEAT INPUT CALC"
        case .carbonEquivalent: return "CARBON EQUIV."
        case .schaeffler: return "SCHAEFFLER CALC"
        case .depositionRate: return "DEPOSITION RATE"
        case .dictionary: return "WELD DICTIONARY"
        }
    }
    
    // Hvilken View den skal åpne
    @ViewBuilder
    var destination: some View {
        switch self {
        case .heatInput: HeatInputView()
        case .carbonEquivalent: CarbonEquivalentView()
        case .schaeffler: SchaefflerView()
        case .depositionRate: DepositionRateView()
        case .dictionary: DictionaryView()
        }
    }
}
