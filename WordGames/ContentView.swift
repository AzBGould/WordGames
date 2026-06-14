import SwiftUI

struct ContentView: View {
    @StateObject private var game = WordleGame()
    @State private var showStats    = false
    @State private var showSettings = false

    var body: some View {
        GameView(
            game:         game,
            showStats:    $showStats,
            showSettings: $showSettings
        )
        .preferredColorScheme(game.darkTheme ? .dark : .light)
        .sheet(isPresented: $showStats) {
            StatsView(game: game, isPresented: $showStats)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(game: game, isPresented: $showSettings)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        // Auto-show stats when a game ends (small delay so flip finishes)
        .onChange(of: game.gameState) { _, state in
            if state != .playing {
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    showStats = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
