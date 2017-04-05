//
//  Board.swift
//  TicTacToe
//
//  Created by James McNamee on 3/4/17.
//  Copyright © 2017 James McNamee. All rights reserved.
//

import UIKit
import Foundation

class Board: NSObject {
    
    static let BOARD_CELL_COUNT = 9
    
    var currentPlayer: Player
    
    override init() {
        self.currentPlayer = Player(type: PlayerType.x)
    }
    
    init(players: Array<Player>) {
        print("Created Board")
        
        // begin with first player
        self.currentPlayer = players[0]
    }
}

struct Position {
    var x: Int
    var y: Int
}

struct Cell {
    var owner: Player?
    var position: Position
    var uiElement: UIButton
    
    init (uiElement: UIButton, position: Position) {
        self.uiElement = uiElement
        self.position = position
    }
    
    init (owner: Player, uiElement: UIButton, position: Position) {
        self.owner = owner
        self.uiElement = uiElement
        self.position = position
    }
}

struct GameState {
    let nilPlayer: Player = Player()
    var board: [[Cell]] = [[], [], []]
    var activePlayer: Player
    
    init (activePlayer: Player) {
        self.activePlayer = activePlayer
    }
    
    init (activePlayer: Player, board: [[Cell]]) {
        self.activePlayer = activePlayer
        self.board = board
    }
}
