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
