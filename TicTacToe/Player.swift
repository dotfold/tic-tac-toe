//
//  Player.swift
//  TicTacToe
//
//  Created by James McNamee on 3/4/17.
//  Copyright © 2017 James McNamee. All rights reserved.
//

import Foundation

enum PlayerType: Int {
    case x
    case o
    case tied
    case none
}

// usage: `let player1 = Player(type: PlayerType.x)`
struct Player {
    var type: PlayerType
    var imageFile: String
    var description: String
    
    init () {
        self.type = PlayerType.none
        self.imageFile = ""
        self.description = ""
    }
    
    init (type: PlayerType) {
        self.type = type
        self.imageFile = type == PlayerType.x ? "X_icon.png" : "O_icon.png"
        self.description = "Player \(String(describing: type).uppercased())"
    }
}
