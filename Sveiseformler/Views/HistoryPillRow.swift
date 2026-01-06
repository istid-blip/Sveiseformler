import SwiftUI

struct HistoryPillRow: View {
    let item: SavedCalculation
    
    var body: some View {
        HStack {
            Text(item.name)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .cornerRadius(12)
            
            Spacer()
            
            Text(item.resultValue)
                .foregroundColor(.secondary)
        }
    }
}
