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
        
        // On = two human players
        self.playerModeSwitch.setOn(true, animated: true)
        
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
            .map { value in
                value ? defaultGameState : defaultAIGameState
            }
        
        // the playerModeChange$ stream dictates which gameMode should be used, but we want to project that game mode
        // when any of the reset streams project a value
        // so when any of those streams project a value, we are invoking the selector function with each latest value
        // and we always return the game state from the playerModeStream$
        // this ensures that any reset stream that produces a value will result in a fresh game of the mode that is currently selected
        let allResetStreams$ = Observable.combineLatest(reset$, newGame$, resetScores$, playerModeChange$) { (_, _, _, gameMode) -> GameState in
            return gameMode
        }
        
        // MARK: Cell clickstreams
        let clicks$: Array<Observable<(uiElement: UIButton, position: Position)>> = self.cells.reduce([], { result, cell in
            // Map each cell to a Tuple
            return result +
                [cell.uiElement.rx.tap
                    .map {
                        return (uiElement: cell.uiElement, position: cell.position)
                    }]
        })
        
        // MARK: Game State
        // game state - this is the state for each single game

        // merge all signals that should produce a new (default) game state
        let gameState$ = Observable.merge(allResetStreams$)
            // start with the default state that the observable produced
            .flatMapLatest({ newDefaultState in
                return Observable.merge(clicks$)
                    .scan(newDefaultState, accumulator: { (prevState: GameState, move: (uiElement: UIButton, position: Position)) -> GameState in
                        
                        func isGameCompleted (board: [[Cell]]) -> Bool {
                            let processWinner = findWinner(board: board)
                            let maybeWinner = processWinner.type != PlayerType.none && processWinner.type != PlayerType.tied
                            let maybeTie = !maybeWinner && checkTiedBoard(board: board).type == PlayerType.tied
                            let completed = maybeWinner || maybeTie
                            return completed
                        }
                        
                        func updatePositions(from board: [[Cell]], move: (uiElement: UIButton, position: Position), player: Player) -> [[Cell]] {
                            // loop the rows to mark the newly clicked cell with the appropriate player
                            return board.enumerated().map({ (index, row) -> [Cell] in
                                if index == move.position.y {
                                    let inner = row.enumerated().map({ (indexInRow, cell) -> Cell in
                                        if indexInRow == move.position.x {
                                            return Cell(owner: player, uiElement: move.uiElement, position: move.position)
                                        }
                                        return cell
                                    })
                                    return inner
                                }
                                return row
                            })
                        }
                        
                        // if the cell is already filled, don't build a new gamestate
                        if prevState.board[move.position.y][move.position.x].owner != nil { return prevState }
                        
                        // don't mark any new positions if the game has completed
                        if prevState.complete { return prevState }
                        
                        // determine which cell to mark in the updated board
                        let justMovedPlayer = prevState.activePlayer
                        var nextPlayer = prevState.activePlayer.type == PlayerType.x ? Player(type: PlayerType.o) : Player(type: PlayerType.x)
                        
                        var updatedPositions = updatePositions(from: prevState.board, move: move, player: justMovedPlayer)
                        
                        
                        // if this is an AI game...
                        // we have the move from the
                        if prevState.isAI && !isGameCompleted(board: updatedPositions) {
                           
                            // find the best cell to mark
                            let aiMove = determineBestMove(board: updatedPositions)
                            
                            // update the positions again with our new cell
                            updatedPositions = updatePositions(from: updatedPositions, move: aiMove, player: nextPlayer)
                            
                            // now set the player back to the justMovedPlayer
                            nextPlayer = justMovedPlayer
                        }
                        
                        let completed = isGameCompleted(board: updatedPositions)
                        return GameState(activePlayer: nextPlayer, board: updatedPositions, complete: completed, isAI: prevState.isAI)
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
        let scoreBoard$ = Observable.merge(resetScores$, playerModeChange$)
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
            // bind the message to the UI
            .bindTo(self.gameEndMessage.rx.text).addDisposableTo(self.disposeBag)
        
        _ = gameEnd$
            .filter{ $0.type != PlayerType.none }
            .map { _ in 1 }
            .bindTo(self.newGameButton.rx.alpha)
        
        // fresh game state, clear the message and hide the button
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

