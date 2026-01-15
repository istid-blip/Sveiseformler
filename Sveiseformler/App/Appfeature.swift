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
    case wideverticaljogger
    
    var id: String { rawValue }
    
    // ENDRING: Endret fra String til LocalizedStringKey
    var title: LocalizedStringKey {
        switch self {
        case .heatInput: return "HEAT INPUT CALC"
        case .carbonEquivalent: return "CARBON EQUIV."
        case .schaeffler: return "SCHAEFFLER CALC"
        case .depositionRate: return "DEPOSITION RATE"
        case .dictionary: return "WELD DICTIONARY"
        // Fikset skrivefeil ("vide" -> "WIDE") og satte til store bokstaver
        case .wideverticaljogger: return "WIDE VERTICAL JOGGER"
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
        case .wideverticaljogger: WideVerticalJogger()
        }
    }
}
