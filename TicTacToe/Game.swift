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
    
    init (activePlayer: Player) {
        self.activePlayer = activePlayer
    }
    
    init (activePlayer: Player, board: [[Cell]]) {
        self.activePlayer = activePlayer
        self.board = board
    }
    
    init (activePlayer: Player, board: [[Cell]], complete: Bool) {
        self.activePlayer = activePlayer
        self.board = board
        self.complete = complete
    }
}

struct Scoreboard {
    
    var xWinCount = 0
    var oWinCount = 0
    var tiedGameCount = 0
    
    mutating func update (with player: Player) {
        
        switch player.type {
            case PlayerType.tied:
                tiedGameCount += 1
                break
            case PlayerType.x:
                xWinCount += 1
                break
            case PlayerType.o:
                oWinCount += 1
                break
            default:
                print("no update to be made")
        }
    }
}
