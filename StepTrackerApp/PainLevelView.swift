import Foundation
import SwiftUI

struct PainLevelView: View {
    @Binding var painLevel: Double
    
    var body: some View {
        VStack {
            Text("Pain Level")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            HStack(spacing: 10) {
                ForEach(1..<11) { index in
                    Image(systemName: "face.smiling")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(colorForPainLevel(index))
                        .opacity(painLevel >= Double(index) ? 1 : 0.3)
                }
            }
            .padding(.horizontal)
            
            Slider(value: $painLevel, in: 1...10, step: 1)
                .accentColor(.blue)
                .padding(.horizontal)
            
            Text("\(Int(painLevel)) / 10")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
        }
        .padding(.vertical)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private func colorForPainLevel(_ level: Int) -> Color {
        switch level {
        case 1...2:
            return .green
        case 3...4:
            return .yellow
        case 5...6:
            return .orange
        case 7...8:
            return .red
        default:
            return .purple
        }
    }
}
