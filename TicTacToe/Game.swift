//
//  Game.swift
//  TicTacToe
//
//  Created by James McNamee on 7/4/17.
//  Copyright © 2017 James McNamee. All rights reserved.
//

import Foundation

struct GameState {
    
    let nilPlayer: Player = Player()
    var board: [[Cell]] = [[], [], []]
    var activePlayer: Player
    var complete: Bool = false
    var isAI: Bool = false
    var isLocked: Bool = false
    
    init (activePlayer: Player) {
        self.activePlayer = activePlayer
    }
    
    init (activePlayer: Player, board: [[Cell]]) {
        self.activePlayer = activePlayer
        self.board = board
    }
    
    // AI mode default
    init (activePlayer: Player, board: [[Cell]], isAI: Bool) {
        self.activePlayer = activePlayer
        self.board = board
        self.isAI = isAI
    }
    
    // AI mode & completed
    init (activePlayer: Player, board: [[Cell]], complete: Bool, isAI: Bool) {
        self.activePlayer = activePlayer
        self.board = board
        self.complete = complete
        self.isAI = isAI
    }
    
    // lock the board so no further clicks will register
    init (activePlayer: Player, board: [[Cell]], complete: Bool, isAI: Bool, isLocked: Bool) {
        self.activePlayer = activePlayer
        self.board = board
        self.complete = complete
        self.isAI = isAI
        self.isLocked = isLocked
    }
}

struct Scoreboard {
    
    var xWinCount = 0
    var oWinCount = 0
    var tiedGameCount = 0
    
    func update (from scores: Scoreboard, player: Player) -> Scoreboard {
        switch player.type {
            case PlayerType.tied:
                var t = scores.tiedGameCount
                t += 1
                return Scoreboard(
                    xWinCount: scores.xWinCount,
                    oWinCount: scores.oWinCount,
                    tiedGameCount: t
                )
            case PlayerType.x:
                var x = scores.xWinCount
                x += 1
                return Scoreboard(
                    xWinCount: x,
                    oWinCount: scores.oWinCount,
                    tiedGameCount: scores.tiedGameCount
                )
            case PlayerType.o:
                var o = scores.oWinCount
                o += 1
                return Scoreboard(
                    xWinCount: scores.xWinCount,
                    oWinCount: o,
                    tiedGameCount: scores.tiedGameCount
                )
            default:
                print("no update to be made")
        }
        
        return Scoreboard()
    }
    
    init (xWinCount: Int = 0, oWinCount: Int = 0, tiedGameCount: Int = 0) {
        self.xWinCount = xWinCount
        self.oWinCount = oWinCount
        self.tiedGameCount = tiedGameCount
    }
}
