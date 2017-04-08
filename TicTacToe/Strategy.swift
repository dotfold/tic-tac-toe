//
//  Strategy.swift
//  TicTacToe
//
//  Created by James McNamee on 3/4/17.
//  Copyright © 2017 James McNamee. All rights reserved.
//

import Foundation
import UIKit

// search all combinations of winning cells to find if any of them contain all of the same player pieces
func findWinner (board rows: [[Cell]]) -> Player {
    
    let combinations: [[[Cell]]] = [
        // rows
        rows,
        getColumns(board: rows),
        getDiagonals(board: rows)
    ]
    
        // flatten one level
    let maybeWinner = combinations.reduce([], +)
        // for each array of possible winning combinations
        .reduce(Player(type: PlayerType.none), { (result, cells) -> Player? in
            // found the winning player, don't check any more
            if result?.type != PlayerType.none { return result }
            
            if areElementsEqual(array: cells, playerType: PlayerType.x) { return Player(type: PlayerType.x) }
            if areElementsEqual(array: cells, playerType: PlayerType.o) { return Player(type: PlayerType.o) }
            
            return Player(type: PlayerType.none)
        })
    
    return maybeWinner!
}

private func areElementsEqual (array: [Cell], playerType: PlayerType) -> Bool {
    var equal = true
    for cell in array {
        if cell.owner?.type != playerType {
            equal = false
        }
    }
    return equal
}

// We want to get the matching ith element of each of the row arrays
// in order to have an array of column arrays
// Swifts native zip only allows for two sequences
// so the second sequence is passed as a nested zipped sequence
// http://stackoverflow.com/questions/28686647/how-can-i-run-through-three-separate-arrays-in-the-same-for-loop
private func getColumns (board rows: [[Cell]]) -> [[Cell]] {
    var result: [[Cell]] = []
    for (r0, (r1, r2)) in zip(rows[0], zip(rows[1], rows[2])) {
        let inner = [r0, r1, r2]
        result.append(inner)
    }
    return result
}

// no easy functional operators for this that I'm aware of
private func getDiagonals (board rows: [[Cell]]) -> [[Cell]] {
    return [
        [rows[0][0], rows[1][1], rows[2][2]],
        [rows[0][2], rows[1][1], rows[2][0]]
    ]
}

// if there is no winner and all cells are marked with a valid player
// then the game is tied
func checkTiedBoard (board rows: [[Cell]]) -> Player {
    let tie = rows.reduce([], +)
        .filter { $0.owner != nil }
        .count == BOARD_CELL_COUNT
    
    return tie ? Player(type: PlayerType.tied) : Player(type: PlayerType.none)
}

// MARK: AI Strategy
// The heuristic for determning the best move for the AI is:
//  - find the first cell that is unplayed
//    - 1. if played, would the AI win?
//    - 2. if played by opponent, would they win?
//    - 3. this cell may be the best move
//    - 4. when search is exhausted, play the last result from 3.
func determineBestMove (board rows: [[Cell]]) -> (uiElement: UIButton, position: Position) {
    
    // the AI player is PlayerType.o
    
    var boardForSimulation = rows
    var cellToPlay = boardForSimulation[0][0]
    for row in 0 ... 2 {
        for col in 0 ... 2 {
            // is this cell owned?
            if boardForSimulation[row][col].owner == nil {
                
                // if we played this cell, did this move make the AI win?
                boardForSimulation[row][col].owner = Player(type: PlayerType.o)
                var simulatedWinner = findWinner(board: boardForSimulation)
                if simulatedWinner.type == PlayerType.o {
                    cellToPlay = boardForSimulation[row][col]
                    return (uiElement: cellToPlay.uiElement, position: cellToPlay.position)
                }
                
                // if the opponent played this cell next, did this move make the opponent win?
                boardForSimulation[row][col].owner = Player(type: PlayerType.x)
                simulatedWinner = findWinner(board: boardForSimulation)
                if simulatedWinner.type == PlayerType.x {
                    cellToPlay = boardForSimulation[row][col]
                    return (uiElement: cellToPlay.uiElement, position: cellToPlay.position)
                }
                
                cellToPlay = boardForSimulation[row][col]
            }
        }
    }
    
    // search has exhausted, play the last cell that we checked
    return (uiElement: cellToPlay.uiElement, position: cellToPlay.position)
}



