import SwiftUI

struct StatsView: View {
    @ObservedObject var game: WordleGame
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.wordleBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("STATISTICS")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .font(.system(size: 18))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)

                Divider().background(Color.wordleHeaderLine)

                // Summary numbers
                HStack(spacing: 20) {
                    StatNumber(value: game.statistics.gamesPlayed,  label: "Played")
                    StatNumber(value: game.statistics.winPercentage, label: "Win %")
                    StatNumber(value: game.statistics.currentStreak, label: "Current\nStreak")
                    StatNumber(value: game.statistics.maxStreak,     label: "Max\nStreak")
                }
                .padding(.vertical, 20)

                Divider().background(Color.wordleHeaderLine)

                // Guess distribution
                VStack(spacing: 8) {
                    Text("GUESS DISTRIBUTION")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 12)

                    let maxVal = maxDistribution()
                    VStack(spacing: 4) {
                        ForEach(1...6, id: \.self) { n in
                            DistributionBar(
                                number:    n,
                                count:     game.statistics.guessDistribution["\(n)"] ?? 0,
                                maxCount:  maxVal,
                                highlight: game.gameState == .won && game.currentRow == n
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Divider().background(Color.wordleHeaderLine).padding(.top, 12)

                // Buttons row
                HStack(spacing: 12) {
                    if game.gameState != .playing {
                        ShareLink(item: game.shareText()) {
                            Label("SHARE", systemImage: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .background(Color.wordleGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    Button {
                        isPresented = false
                        game.newGame(daily: false)
                    } label: {
                        Text("NEW GAME")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(Color(hex: "3A3A3C"))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private func maxDistribution() -> Int {
        let vals = (1...6).compactMap { game.statistics.guessDistribution["\($0)"] }
        return vals.max() ?? 1
    }
}

// MARK: - Sub-views

private struct StatNumber: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DistributionBar: View {
    let number: Int
    let count: Int
    let maxCount: Int
    let highlight: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text("\(number)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 14, alignment: .leading)

            GeometryReader { geo in
                let fraction = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                let barWidth = max(28, geo.size.width * fraction)
                HStack {
                    ZStack(alignment: .trailing) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(highlight ? Color.wordleGreen : Color(hex: "3A3A3C"))
                            .frame(width: barWidth)
                        Text("\(count)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.trailing, 6)
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(height: 24)
        }
    }
}
