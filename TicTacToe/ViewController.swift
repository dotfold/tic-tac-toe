//
//  ViewController.swift
//  TicTacToe
//
//  Created by James McNamee on 3/4/17.
//  Copyright © 2017 James McNamee. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    // MARK: IBOutlets
    @IBOutlet weak var pieceTL: UIButton!
    @IBOutlet weak var pieceTC: UIButton!
    @IBOutlet weak var pieceTR: UIButton!
    @IBOutlet weak var pieceCL: UIButton!
    @IBOutlet weak var pieceCC: UIButton!
    @IBOutlet weak var pieceCR: UIButton!
    @IBOutlet weak var pieceBL: UIButton!
    @IBOutlet weak var pieceBC: UIButton!
    @IBOutlet weak var pieceBR: UIButton!
    
    @IBOutlet weak var reset: UIButton!
    @IBOutlet weak var resetScoresButton: UIButton!
    
    @IBOutlet weak var player1ActiveIndicator: UIImageView!
    @IBOutlet weak var player2ActiveIndicator: UIImageView!
    
    @IBOutlet weak var player1Scorecard: UILabel!
    @IBOutlet weak var tiedGameScorecard: UILabel!
    @IBOutlet weak var player2Scorecard: UILabel!
    
    @IBOutlet weak var gameEndMessage: UILabel!
    @IBOutlet weak var newGameButton: UIButton!
    
    @IBOutlet weak var playerModeSwitch: UISwitch!
    
    private let disposeBag = DisposeBag()
    private var cells: Array<Cell> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: Setup
        self.cells = [
            
            // top row
            Cell(uiElement: pieceTL, position: Position(x: 0, y: 0)),
            Cell(uiElement: pieceTC, position: Position(x: 1, y: 0)),
            Cell(uiElement: pieceTR, position: Position(x: 2, y: 0)),
            
            // middle row
            Cell(uiElement: pieceCL, position: Position(x: 0, y: 1)),
            Cell(uiElement: pieceCC, position: Position(x: 1, y: 1)),
            Cell(uiElement: pieceCR, position: Position(x: 2, y: 1)),
            
            // bottom row
            Cell(uiElement: pieceBL, position: Position(x: 0, y: 2)),
            Cell(uiElement: pieceBC, position: Position(x: 1, y: 2)),
            Cell(uiElement: pieceBR, position: Position(x: 2, y: 2))
        ]
        
        let defaultGameState = GameState(
            activePlayer: Player(type: PlayerType.x),
            board: [
                [self.cells[0], self.cells[1], self.cells[2]],
                [self.cells[3], self.cells[4], self.cells[5]],
                [self.cells[6], self.cells[7], self.cells[8]]
            ]
        )
        
        let defaultAIGameState = GameState(
            activePlayer: Player(type: PlayerType.x),
            board: [
                [self.cells[0], self.cells[1], self.cells[2]],
                [self.cells[3], self.cells[4], self.cells[5]],
                [self.cells[6], self.cells[7], self.cells[8]]
            ],
            isAI: true
        )
        
        let defaultScoreboard = Scoreboard()
        
        // player 1 is always first for a new game set
        self.player1ActiveIndicator.alpha = 1
        self.player2ActiveIndicator.alpha = 0
        
        self.newGameButton.alpha = 0
        
        // On = single player
        self.playerModeSwitch.setOn(true, animated: true)
        
        
        // handle reset merges by flatMap
        // MARK: New Game
        let reset$ = reset.rx.tap
            .map { _ in defaultGameState }
            .startWith(defaultGameState)
        
        let newGame$ = newGameButton.rx.tap
            .map { _ in defaultGameState }
            .startWith(defaultGameState)
        
        let resetScores$ = resetScoresButton.rx.tap
            .map { _ in defaultGameState }
            .startWith(defaultGameState)
        
        let playerModeChange$ = playerModeSwitch.rx.value
            .debug("player mode changed")
            .do(onNext: { (state) in
                print("mode change \(state)")
            })
            .map { value in
                value ? defaultGameState : defaultAIGameState
            }
        
        // MARK: Cell clickstreams
        let clicks$: Array<Observable<(uiElement: UIButton, position: Position)>> = self.cells.reduce([], { result, cell in
            // Map each cell to a Tuple
            // For each cell, only take one tap event, these will be reset for each new game
            return result +
                [cell.uiElement.rx.tap
                    .map {
                        return (uiElement: cell.uiElement, position: cell.position)
                    }]
        })
        
        // MARK: Game State
        // game state - this is the state for each single game

        // merge all signals that should produce a new (default) game state
        let gameState$ = Observable.merge(reset$, newGame$, resetScores$, playerModeChange$)
            // start with the default state that the observable produced
            .flatMapLatest({ newDefaultState in
                return Observable.merge(clicks$)
                    .scan(newDefaultState, accumulator: { (prevState: GameState, move: (uiElement: UIButton, position: Position)) -> GameState in
                        
                        print("scan \(newDefaultState.isAI) \(prevState.isAI)")
                        
                        // if the cell is already filled, don't build a new gamestate
                        if prevState.board[move.position.y][move.position.x].owner != nil { return prevState }
                        
                        // don't mark any new positions if the game has completed
                        if prevState.complete { return prevState }
                        
                        
                        let justMovedPlayer = prevState.activePlayer
                        var nextPlayer = prevState.activePlayer.type == PlayerType.x ? Player(type: PlayerType.o) : Player(type: PlayerType.x)
                        let markedPosition = move.position
                        
                        // loop the rows to mark the newly clicked cell with the appropriate player
                        var updatedPositions = prevState.board.enumerated().map({ (index, row) -> [Cell] in
                            if index == markedPosition.y {
                                let inner = row.enumerated().map({ (indexInRow, cell) -> Cell in
                                    if indexInRow == markedPosition.x {
                                        return Cell(owner: justMovedPlayer, uiElement: move.uiElement, position: move.position)
                                    }
                                    return cell
                                })
                                return inner
                            }
                            return row
                        })
                        
                        // if this is an AI game...
                        // we have the move from the
                        if prevState.isAI {
                           
                            // find the best cell to mark
                            let aiPosition = Position(x: 2, y: 2)
                            let aiElement = self.cells[8].uiElement
                            
                            // update the positions again with our new cell
                            updatedPositions = updatedPositions.enumerated().map({ (index, row) -> [Cell] in
                                if index == aiPosition.y {
                                    let inner = row.enumerated().map({ (indexInRow, cell) -> Cell in
                                        if indexInRow == aiPosition.x {
                                            return Cell(owner: nextPlayer, uiElement: aiElement, position: aiPosition)
                                        }
                                        return cell
                                    })
                                    return inner
                                }
                                return row
                            })
                            
                            // now set the player back to the justMovedPlayer
                            nextPlayer = justMovedPlayer
                        }
                        
                        
                        // finally, check to see if this move resulted in a game end state
                        let processWinner = findWinner(board: updatedPositions)
                        let maybeWinner = processWinner.type != PlayerType.none && processWinner.type != PlayerType.tied
                        let maybeTie = !maybeWinner && checkTiedBoard(board: updatedPositions).type == PlayerType.tied
                        let completed = maybeWinner || maybeTie
                        return GameState(activePlayer: nextPlayer, board: updatedPositions, complete: completed)
                    })
                    .startWith(defaultGameState)
                    .share()
            })
        
        // MARK: Winner
        let winner$ = gameState$
            .filter { $0.complete }
            .flatMap { Observable.of(findWinner(board: $0.board)) }
            .filter { $0.type != PlayerType.none && $0.type != PlayerType.tied }
            .share()
        
        // MARK: Tied board
        let tie$ = gameState$
            .filter { $0.complete }
            .flatMap { Observable.of(checkTiedBoard(board: $0.board)) }
            .filter { $0.type == PlayerType.tied }
            .share()
        
        
        // MARK: Player Activity Indicators
        // create two cold observables off of gameState$ that map to the side-effecting code
        // to turn on/off the relevant indicators
        let playerOneActive$ = gameState$
            .map { $0.activePlayer }
            .filter { $0.type == PlayerType.x }
            .do(onNext: { [unowned self] (Player) in
                self.player1ActiveIndicator.alpha = 1
                self.player2ActiveIndicator.alpha = 0
            })
        
        let playerTwoActive$ = gameState$
            .map { $0.activePlayer }
            .filter { $0.type == PlayerType.o }
            .do(onNext: { [unowned self] (Player) in
                self.player1ActiveIndicator.alpha = 0
                self.player2ActiveIndicator.alpha = 1
            })
        
         _ = Observable.combineLatest(playerOneActive$, playerTwoActive$)
            .subscribe()
        
        // MARK: Scoreboard
        let scoreBoard$ = Observable.merge(resetScores$)
            .flatMapLatest({ _ in
                return Observable.merge(winner$, tie$)
                    .filter { $0.type != PlayerType.none }
                    .scan(defaultScoreboard, accumulator: { (prevScoreboard: Scoreboard, player: Player) -> Scoreboard in
                        var newScores = Scoreboard()
                        newScores = newScores.update(from: prevScoreboard, player: player)
                        return newScores
                    })
                    .startWith(defaultScoreboard)
            })
        
        _ = scoreBoard$
            .map { String($0.xWinCount) }
            .bindTo(self.player1Scorecard.rx.text)
            .addDisposableTo(self.disposeBag)
        
        _ = scoreBoard$
            .map { String($0.oWinCount) }
            .bindTo(self.player2Scorecard.rx.text)
            .addDisposableTo(self.disposeBag)
        
        _ = scoreBoard$
            .map { String($0.tiedGameCount) }
            .bindTo(self.tiedGameScorecard.rx.text)
            .addDisposableTo(self.disposeBag)
        
        // MARK: Game end display
        let gameEnd$ = Observable.merge(winner$, tie$)
        _ = gameEnd$
            .filter{ $0.type != PlayerType.none }
            .map { (winner) -> String in
                let message = winner.type == PlayerType.tied
                    ? "Game tied!"
                    : "\(winner.description) wins!"
                
                return message
            }
            // bind the countdown message to the UI
            .bindTo(self.gameEndMessage.rx.text).addDisposableTo(self.disposeBag)
        
        _ = gameEnd$
            .filter{ $0.type != PlayerType.none }
            .map { _ in 1 }
            .bindTo(self.newGameButton.rx.alpha)
        
        // fresh game state, clear the message
        _ = gameState$
            .filter{ !$0.complete }
            .map { _ in return "" }
            // bind the countdown message to the UI
            .bindTo(self.gameEndMessage.rx.text).addDisposableTo(self.disposeBag)
        
        _ = gameState$
            .filter{ !$0.complete }
            .map { _ in 0 }
            .bindTo(self.newGameButton.rx.alpha)
        
        // MARK: Render
        // perform a render of the entire new game state
        // explicitly discard any return values by using `_`
        let render$ = gameState$
            .flatMap({ state -> Observable<Cell> in
                return Observable.from(state.board.reduce([], +))
            })
        
        let renderMarkedCells$ = render$
            .filter { $0.owner != nil }
            .do(onNext: { (cell) in
                cell.uiElement.setImage(UIImage(named: cell.owner!.imageFile), for: UIControlState())
            })

        let renderUnmarkedCells$ = render$
            .filter { $0.owner == nil }
            .do(onNext: { (cell) in
                cell.uiElement.setImage(nil, for: UIControlState())
            })
        
        // This is what starts everything, just one call to subscribe()
        // all the cold observables now become 'hot' and the compositions will take place as values are produced
        _ = Observable.combineLatest(renderMarkedCells$, renderUnmarkedCells$).subscribe()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

