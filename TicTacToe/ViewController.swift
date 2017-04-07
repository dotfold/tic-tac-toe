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
    
    @IBOutlet weak var player1ActiveIndicator: UIImageView!
    @IBOutlet weak var player2ActiveIndicator: UIImageView!
    
    @IBOutlet weak var player1Scorecard: UILabel!
    @IBOutlet weak var tiedGameScorecard: UILabel!
    @IBOutlet weak var player2Scorecard: UILabel!
    
    @IBOutlet weak var gameEndMessage: UILabel!
    
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
        
        let defaultScoreboard = Scoreboard()
        
        // player 1 is always first
        self.player1ActiveIndicator.alpha = 1
        self.player2ActiveIndicator.alpha = 0
        
        
        // handle reset merges by flatMap
        // MARK: New Game
        let reset$ = reset.rx.tap
            .debug("reset tap")
            .map { _ in defaultGameState }
            .startWith(defaultGameState)
        
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
        let gameState$ = Observable.merge(clicks$)
            .scan(defaultGameState, accumulator: { (prevState: GameState, move: (uiElement: UIButton, position: Position)) -> GameState in
                
                // don't mark any new positions if the game has completed
                if (prevState.complete) { return prevState }
                
                let justMovedPlayer = prevState.activePlayer
                let nextPlayer = prevState.activePlayer.type == PlayerType.x ? Player(type: PlayerType.o) : Player(type: PlayerType.x)
                let markedPosition = move.position
                
                // loop the rows to mark the newly clicked cell with the appropriate player
                let updatedPositions = prevState.board.enumerated().map({ (index, row) -> [Cell] in
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
                
                // finally, check to see if this move resulted in a game end state
                let completed = findWinner(board: updatedPositions).type != PlayerType.none // || checkTiedBoard(board: updatedPositions)
                return GameState(activePlayer: nextPlayer, board: updatedPositions, complete: completed)
            })
            .startWith(defaultGameState)
            .share()
        
        // MARK: Winner
        let winner$ = gameState$
            .flatMap { Observable.of(findWinner(board: $0.board)) }
            .filter { $0.type != PlayerType.none }
            .debug("found a winner!")
            .share()
        
        // MARK: Tied board
        // this could also be the onComplete of the render? because at that point, all tap observables have completed
        let tie$ = gameState$
            .flatMap { Observable.of(checkTiedBoard(board: $0.board)) }
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
            .takeUntil(Observable.combineLatest(winner$, tie$))
            .subscribe()
        
        // MARK: Scoreboard
        let scoreBoard$ = Observable.merge(winner$, tie$)
            .filter { $0.type != PlayerType.none }
            .scan(defaultScoreboard, accumulator: { (prevScoreboard: Scoreboard, player: Player) -> Scoreboard in
                var updatedScoreboard = Scoreboard()
                updatedScoreboard.update(with: player)
                return updatedScoreboard
            })
            .startWith(defaultScoreboard)
        
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
            .filter{ $0.type != PlayerType.none }
            .take(1)
        
        // Start a new game countdown timer
        // skip 1 second, then take 3
        // but only when the game has ended, so use a concat.
        // this is mapped to an Int with value 0 because the resulting sequence from concat
        // must have two sequences that yeild the same type.
        let gameEndedCountdown$ = gameEnd$.map { _ in 0 }.concat(
            Observable<Int>.interval(1, scheduler: MainScheduler.instance)
                .map({ time in 3 - time })
                .take(3 + 1)
//                .skip(1)
//                .take(3)
            )
            // and skip that first 0
            .skip(1)
        
        _ = Observable.combineLatest(gameEnd$, gameEndedCountdown$)
            .map { (winner, remaining) -> String in
                let message = winner.type == PlayerType.tied
                    ? "Game tied... starting new game in \(remaining)"
                    : "\(winner.description) wins! Starting new game in \(remaining)"
                
                return message
            }
            .bindTo(self.gameEndMessage.rx.text)
        
        
        // MARK: Render
        // perform a render of the entire new game state
        // explicitly discard any return values by using `_`
        _ = gameState$
            .flatMap({ state -> Observable<Cell> in
                return Observable.from(state.board.reduce([], +))
            })
            .filter { $0.owner != nil }
            .do(onNext: { (cell) in
                cell.uiElement.setImage(UIImage(named: cell.owner!.imageFile), for: UIControlState())
            })
            .subscribe()
    }
    
    func handleEndState (with cell: Cell) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

