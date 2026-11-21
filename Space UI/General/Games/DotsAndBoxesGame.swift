// Created by 256 Arts Developer on 2026-08-23.

/// The rules of the lock screen's dots and boxes, with no SwiftUI in them, so `DotsAndBoxesPage` is only the
/// drawing of a board and a whole game can be played in a test without a view.
///
/// The page keeps the timing: a finished game is held on screen before ``startNextGame()`` clears it. Board
/// size lives here rather than in the page because the rules are written against it; the page reads it back
/// for its own geometry.
struct DotsAndBoxesGame {

    enum CellOwner {
        case player, opponent
    }

    /// A side of a box, addressed by the dot grid. Horizontal edges run `0...boxRows` by `0..<boxCols`;
    /// vertical edges run `0..<boxRows` by `0...boxCols`.
    enum Edge: Hashable {
        case horizontal(row: Int, col: Int)
        case vertical(row: Int, col: Int)
    }

    /// What a tap did, so the page knows which sound to play and whether a game is now waiting to be cleared.
    enum MoveOutcome {
        case rejected, played, gameOver
    }

    let boxRows: Int
    let boxCols: Int

    private(set) var hEdges: [[Bool]]
    private(set) var vEdges: [[Bool]]
    private(set) var boxOwners: [[CellOwner?]]
    private(set) var playerWins = 0
    private(set) var opponentWins = 0
    /// Set while the finished board is held on screen. Doubles as the "no more moves" flag.
    private(set) var isGameOver = false

    init(boxRows: Int = 3, boxCols: Int = 3) {
        self.boxRows = boxRows
        self.boxCols = boxCols
        hEdges = Self.emptyEdges(rows: boxRows + 1, cols: boxCols)
        vEdges = Self.emptyEdges(rows: boxRows, cols: boxCols + 1)
        boxOwners = Self.unclaimedBoxes(rows: boxRows, cols: boxCols)
    }

    func isDrawn(_ edge: Edge) -> Bool {
        switch edge {
        case let .horizontal(r, c): hEdges[r][c]
        case let .vertical(r, c): vEdges[r][c]
        }
    }

    /// Draws `edge` for the player, then hands the opponent its turn unless the player claimed a box — a
    /// claim earns another turn, so the game simply waits for the next tap.
    mutating func tap(_ edge: Edge) -> MoveOutcome {
        guard !isGameOver, !isDrawn(edge) else { return .rejected }
        let claimed = applyMove(edge, owner: .player)
        if boardIsComplete {
            endGame()
            return .gameOver
        }
        if claimed == 0 {
            opponentTurn()
            if boardIsComplete {
                endGame()
                return .gameOver
            }
        }
        return .played
    }

    /// Clears the finished board for the next game. The score was already awarded when the game ended.
    mutating func startNextGame() {
        hEdges = Self.emptyEdges(rows: boxRows + 1, cols: boxCols)
        vEdges = Self.emptyEdges(rows: boxRows, cols: boxCols + 1)
        boxOwners = Self.unclaimedBoxes(rows: boxRows, cols: boxCols)
        isGameOver = false
    }

    // MARK: - Play

    private mutating func opponentTurn() {
        while !boardIsComplete {
            let undrawn = undrawnEdges()
            if let claiming = undrawn.first(where: { completesABox($0) }) {
                applyMove(claiming, owner: .opponent)
                continue // Claimed a box, so the opponent goes again.
            }
            // Prefer a move that doesn't hand the player a free box.
            let safe = undrawn.filter { !createsThreeSidedBox($0) }
            applyMove(safe.randomElement() ?? undrawn.randomElement()!, owner: .opponent)
            break
        }
    }

    @discardableResult
    private mutating func applyMove(_ edge: Edge, owner: CellOwner) -> Int {
        setDrawn(edge)
        var claimed = 0
        for box in adjacentBoxes(to: edge) where boxOwners[box.row][box.col] == nil && drawnSides(boxRow: box.row, boxCol: box.col) == 4 {
            boxOwners[box.row][box.col] = owner
            claimed += 1
        }
        return claimed
    }

    private mutating func endGame() {
        isGameOver = true
        let boxes = boxOwners.flatMap { $0 }
        let playerBoxes = boxes.filter { $0 == .player }.count
        let opponentBoxes = boxes.filter { $0 == .opponent }.count
        if playerBoxes > opponentBoxes {
            playerWins += 1
        } else if opponentBoxes > playerBoxes {
            opponentWins += 1
        }
    }

    // MARK: - Board queries

    private mutating func setDrawn(_ edge: Edge) {
        switch edge {
        case let .horizontal(r, c): hEdges[r][c] = true
        case let .vertical(r, c): vEdges[r][c] = true
        }
    }
    private func drawnSides(boxRow r: Int, boxCol c: Int) -> Int {
        var sides = 0
        if hEdges[r][c] { sides += 1 }     // top
        if hEdges[r + 1][c] { sides += 1 } // bottom
        if vEdges[r][c] { sides += 1 }     // left
        if vEdges[r][c + 1] { sides += 1 } // right
        return sides
    }
    private func adjacentBoxes(to edge: Edge) -> [(row: Int, col: Int)] {
        switch edge {
        case let .horizontal(r, c):
            var boxes = [(row: Int, col: Int)]()
            if r > 0 { boxes.append((r - 1, c)) }
            if r < boxRows { boxes.append((r, c)) }
            return boxes
        case let .vertical(r, c):
            var boxes = [(row: Int, col: Int)]()
            if c > 0 { boxes.append((r, c - 1)) }
            if c < boxCols { boxes.append((r, c)) }
            return boxes
        }
    }
    private func undrawnEdges() -> [Edge] {
        var edges = [Edge]()
        for r in 0...boxRows {
            for c in 0..<boxCols where !hEdges[r][c] {
                edges.append(.horizontal(row: r, col: c))
            }
        }
        for r in 0..<boxRows {
            for c in 0...boxCols where !vEdges[r][c] {
                edges.append(.vertical(row: r, col: c))
            }
        }
        return edges
    }
    private func completesABox(_ edge: Edge) -> Bool {
        adjacentBoxes(to: edge).contains { drawnSides(boxRow: $0.row, boxCol: $0.col) == 3 }
    }
    private func createsThreeSidedBox(_ edge: Edge) -> Bool {
        adjacentBoxes(to: edge).contains { drawnSides(boxRow: $0.row, boxCol: $0.col) == 2 }
    }
    private var boardIsComplete: Bool {
        undrawnEdges().isEmpty
    }

    private static func emptyEdges(rows: Int, cols: Int) -> [[Bool]] {
        [[Bool]](repeating: [Bool](repeating: false, count: cols), count: rows)
    }
    private static func unclaimedBoxes(rows: Int, cols: Int) -> [[CellOwner?]] {
        [[CellOwner?]](repeating: [CellOwner?](repeating: nil, count: cols), count: rows)
    }

}
