//
//  Appfeature.swift
//  Sveiseformler
//
//  Created by Frode Halrynjo on 13/01/2026.
//

import SwiftUI

enum AppFeature: String, Identifiable, CaseIterable {
    case heatInput
    case carbonEquivalent
    case schaeffler
    case depositionRate
    case dictionary

    
    var id: String { rawValue }
    
    // ENDRING: Endret fra String til LocalizedStringKey
    var title: LocalizedStringKey {
        switch self {
        case .heatInput: return "HEAT INPUT"
        case .carbonEquivalent: return "CARBON EQUIVALENT"
        case .schaeffler: return "SCHAEFFLER"
        case .depositionRate: return "DEPOSITION RATE"
        case .dictionary: return "DICTIONARY"

        }
    }
    
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
