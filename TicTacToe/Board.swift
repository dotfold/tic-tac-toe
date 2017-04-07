//
//  Board.swift
//  TicTacToe
//
//  Created by James McNamee on 3/4/17.
//  Copyright © 2017 James McNamee. All rights reserved.
//

import UIKit
import Foundation

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
