import SwiftUI

struct CardView: View {
    let card: Card
    var cornerRadius: CGFloat = 6

    var body: some View {
        Image(card.imageName)
            .resizable()
            .interpolation(.high)
            .background(.white, in: RoundedRectangle(cornerRadius: cornerRadius))
            .accessibilityLabel(card.description)
    }
}

#Preview {
    HStack {
        CardView(card: Card(rank: 13, suit: .hearts))
        CardView(card: Card(rank: 12, suit: .spades))
        CardView(card: Card(rank: 11, suit: .diamonds))
    }
    .frame(height: 200)
    .padding()
    .background(.green)
}
