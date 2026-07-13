import SwiftUI

struct StatsView: View {
    @ObservedObject var game: LetterLogicGame
    @Binding var isPresented: Bool

    /// Drives the milestone confetti burst inside this sheet.
    @State private var streakConfetti = false

    /// Milestone captured once when the sheet appears, so it stays visible for
    /// this presentation even after we mark it celebrated.
    @State private var milestoneToCelebrate: Int? = nil

    /// Drives the "give up this game?" confirmation on New Game.
    @State private var showNewGameConfirm = false

    private var dark: Bool { game.darkTheme }

    /// True when tapping New Game would abandon an active game and cost a streak.
    private var wouldAbandonStreak: Bool {
        game.gameState == .playing && game.statistics.currentStreak > 0
    }

    private func startNewGame() {
        isPresented = false
        game.newGame()
    }

    var body: some View {
        ZStack {
            AppTheme.background(dark: dark).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("STATISTICS")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText(dark: dark))
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppTheme.primaryText(dark: dark))
                            .font(.system(size: 18))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)

                Divider().background(AppTheme.divider(dark: dark))

                // Streak milestone celebration (every 25 consecutive wins)
                if let milestone = milestoneToCelebrate {
                    StreakMilestoneBanner(
                        milestone: milestone,
                        shareText: game.streakShareText(streak: milestone),
                        accent:    game.palette.correct,
                        dark:      dark
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }

                // Summary numbers
                HStack(alignment: .top, spacing: 8) {
                    StatNumber(value: game.statistics.gamesPlayed,   label: "Played",         dark: dark)
                    StatNumber(value: game.statistics.winPercentage, label: "Win %",          dark: dark)
                    StatNumber(value: game.statistics.currentStreak, label: "Current Streak", dark: dark)
                    StatNumber(value: game.statistics.maxStreak,     label: "Max Streak",     dark: dark)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 20)

                Divider().background(AppTheme.divider(dark: dark))

                // Guess distribution
                VStack(spacing: 8) {
                    Text("GUESS DISTRIBUTION")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText(dark: dark))
                        .padding(.top, 12)

                    let maxVal = maxDistribution()
                    VStack(spacing: 4) {
                        ForEach(1...6, id: \.self) { n in
                            DistributionBar(
                                number:    n,
                                count:     game.statistics.guessDistribution["\(n)"] ?? 0,
                                maxCount:  maxVal,
                                highlight: game.gameState == .won && game.guessesUsed == n,
                                accent:    game.palette.correct,
                                dark:      dark
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Divider().background(AppTheme.divider(dark: dark)).padding(.top, 12)

                // Buttons row
                HStack(spacing: 12) {
                    // Hidden while the streak banner is up so there's only one
                    // Share action on screen (the banner's SHARE STREAK).
                    if game.gameState != .playing && milestoneToCelebrate == nil {
                        ShareLink(item: game.shareText()) {
                            Label("SHARE", systemImage: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .background(game.palette.correct)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    Button {
                        if wouldAbandonStreak {
                            showNewGameConfirm = true
                        } else {
                            startNewGame()
                        }
                    } label: {
                        Text("NEW GAME")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(AppTheme.grayFill(dark: dark))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .confirmationDialog(
                        "Give up this game?",
                        isPresented: $showNewGameConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("End Game & Reset Streak", role: .destructive) {
                            game.breakStreak()
                            startNewGame()
                        }
                        Button("Keep Playing", role: .cancel) { }
                    } message: {
                        Text("You're on a \(game.statistics.currentStreak)-game win streak. Starting a new game gives up the current one and resets your streak to 0.")
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        // Milestone confetti bursts over the sheet when the banner is shown.
        .overlay {
            if milestoneToCelebrate != nil {
                ConfettiView(isActive: $streakConfetti)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            if let m = game.pendingStreakMilestone {
                milestoneToCelebrate = m
                streakConfetti = true
                game.markStreakMilestoneCelebrated(m)
            }
        }
    }

    private func maxDistribution() -> Int {
        let vals = (1...6).compactMap { game.statistics.guessDistribution["\($0)"] }
        return vals.max() ?? 1
    }
}

// MARK: - Sub-views

private struct StreakMilestoneBanner: View {
    let milestone: Int
    let shareText: String
    let accent: Color
    let dark: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text("🔥 \(milestone)-GAME STREAK! 🔥")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("You've won \(milestone) in a row. Share the milestone!")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            ShareLink(item: shareText) {
                Label("SHARE STREAK", systemImage: "flame.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(accent)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct StatNumber: View {
    let value: Int
    let label: String
    let dark: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppTheme.primaryText(dark: dark))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.primaryText(dark: dark))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DistributionBar: View {
    let number: Int
    let count: Int
    let maxCount: Int
    let highlight: Bool
    let accent: Color
    let dark: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text("\(number)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText(dark: dark))
                .frame(width: 14, alignment: .leading)

            GeometryReader { geo in
                let fraction = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                let barWidth = max(28, geo.size.width * fraction)
                HStack {
                    ZStack(alignment: .trailing) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(highlight ? accent : AppTheme.grayFill(dark: dark))
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
