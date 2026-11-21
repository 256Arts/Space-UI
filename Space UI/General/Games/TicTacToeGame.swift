// Created by 256 Arts Developer on 2026-08-23.

/// The rules of the lock screen's tic-tac-toe, with no SwiftUI in them, so `TicTacToePage` is only the drawing
/// of a board and a whole round can be played in a test without a view.
///
/// The page keeps the timing: a won round is held on screen for its animation, and only then does the page
/// call ``startNextRound()``. Everything before that — whose turn, who won, the score — is decided here.
struct TicTacToeGame {

    enum CellOwner {
        case player, opponent
    }

    struct CellCoord: Hashable {
        let row: Int
        let column: Int
    }

    /// What a tap did, so the page knows which sound to play and whether a round is now waiting to be cleared.
    enum MoveOutcome {
        case rejected, played, roundOver
    }

    private static let side = 3

    private static let allCoords: [CellCoord] = (0..<side).flatMap { row in
        (0..<side).map { CellCoord(row: row, column: $0) }
    }

    /// Every three-in-a-row, derived rather than typed out: the three rows, the three columns, then the two
    /// diagonals.
    private static let lines: [[CellCoord]] = {
        let rows = (0..<side).map { row in (0..<side).map { CellCoord(row: row, column: $0) } }
        let columns = (0..<side).map { column in (0..<side).map { CellCoord(row: $0, column: column) } }
        let diagonals = [
            (0..<side).map { CellCoord(row: $0, column: $0) },
            (0..<side).map { CellCoord(row: $0, column: side - 1 - $0) }
        ]
        return rows + columns + diagonals
    }()

    private(set) var board = [[CellOwner?]](repeating: [CellOwner?](repeating: nil, count: side), count: side)
    /// The line that won the round, which the page holds up before clearing. Doubles as the "round is over"
    /// flag: no move is accepted while it is set.
    private(set) var winningLine: [CellCoord]?
    private(set) var playerWins = 0
    private(set) var opponentWins = 0

    private var roundWinner: CellOwner?

    subscript(coord: CellCoord) -> CellOwner? {
        board[coord.row][coord.column]
    }

    /// Plays `coord` for the player and, unless that already decided the round, the opponent's reply.
    mutating func select(_ coord: CellCoord) -> MoveOutcome {
        guard winningLine == nil, self[coord] == nil else { return .rejected }
        board[coord.row][coord.column] = .player
        if let outcome = outcomeIfRoundDecided(lastMoveBy: .player) { return outcome }
        opponentTurn()
        return outcomeIfRoundDecided(lastMoveBy: .opponent) ?? .played
    }

    /// Awards the finished round and clears the board for the next one. A draw was already cleared, so this
    /// only has a winner to award when the page is calling it at the end of the win animation.
    mutating func startNextRound() {
        switch roundWinner {
        case .player:
            playerWins += 1
        case .opponent:
            opponentWins += 1
        case nil:
            break
        }
        clearBoard()
    }

    /// The round's outcome if the last move decided it, or `nil` if play continues. A win is held for the
    /// page to animate; a draw simply clears, since there is nothing to look at.
    private mutating func outcomeIfRoundDecided(lastMoveBy player: CellOwner) -> MoveOutcome? {
        if let line = Self.lines.first(where: { line in line.allSatisfy { self[$0] == player } }) {
            winningLine = line
            roundWinner = player
            return .roundOver
        }
        if !Self.allCoords.contains(where: { self[$0] == nil }) {
            clearBoard()
            return .played
        }
        return nil
    }

    /// The opponent plays at random — it is set dressing on a sci-fi console, not an opponent to beat.
    private mutating func opponentTurn() {
        guard let choice = Self.allCoords.filter({ self[$0] == nil }).randomElement() else { return }
        board[choice.row][choice.column] = .opponent
    }

    private mutating func clearBoard() {
        board = [[CellOwner?]](repeating: [CellOwner?](repeating: nil, count: Self.side), count: Self.side)
        winningLine = nil
        roundWinner = nil
    }

}
