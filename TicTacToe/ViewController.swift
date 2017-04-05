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
    
    private let disposeBag = DisposeBag()
    private var cells: Array<Cell> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cells = [
            Cell(uiElement: pieceTL, position: Position(x: 0, y: 0)),
            Cell(uiElement: pieceTC, position: Position(x: 1, y: 0)),
            Cell(uiElement: pieceTR, position: Position(x: 2, y: 0)),
            Cell(uiElement: pieceCL, position: Position(x: 0, y: 1)),
            Cell(uiElement: pieceCC, position: Position(x: 1, y: 1)),
            Cell(uiElement: pieceCR, position: Position(x: 2, y: 1)),
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
        
        let reset$ = reset.rx.tap
            .debug("reset tap")
            .startWith()
        
        let clicks$: Array<Observable<(uiElement: UIButton, position: Position)>> = cells.reduce([], { result, cell in
            return result +
                [cell.uiElement.rx.tap
                    .map {
                        return (uiElement: cell.uiElement, position: cell.position)
                    }
                    .take(1)]
        })
        
        // game state
        let gameState$ = Observable.merge(clicks$)
            .scan(defaultGameState, accumulator: { (prevState: GameState, move: (uiElement: UIButton, position: Position)) -> GameState in
                let justMovedPlayer = prevState.activePlayer
                let nextPlayer = prevState.activePlayer.type == PlayerType.x ? Player(type: PlayerType.o) : Player(type: PlayerType.x)
                let markedPosition = move.position
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
                
                print("ret \(nextPlayer)")
                return GameState(activePlayer: nextPlayer, board: updatedPositions)
            })
            .startWith(defaultGameState)
    
        
        
        let winner$ = gameState$
        
        // this could also be the onComplete of the render? because at that point, all tap observables have completed
        let tie$ = gameState$
        
        
//        gameState$ map activePlayer to label field above the board
        
        
        
        
        
        let winner$ = gameStates$
            .map({ state in
                // rows
                // columns
                // diagonals
                
            })
        
        // this could also be the onComplete of the render? because at that point, all tap observables have completed
        let tie$ = gameStates$
            .map({ state in
                // every piece has been played
            })
        
        
        let gameEnd$ = Observable.combineLatest(winner$, tie$)
        
        // perform a render of the entire new game state
        // explicitly discard any return values by using `_`
        _ = gameStates$
//            .takeUntil(gameEnd$)
            .flatMap({ state -> Observable<Cell> in
                return Observable.from(state.board.reduce([], +))
            })
            .filter { $0.owner != nil }
            .do(onNext: { (cell) in
                cell.uiElement.setImage(UIImage(named: cell.owner!.imageFile), for: UIControlState())
            })
            .subscribe(
                onNext: { cell in
                    print("render done")
                }
            )
        
        let r = Observable.combineLatest(winner$, tie$)
            .subscribe(
                onNext: { x in
                    print("game over!")
            }
        )
        
        // handle reset merges by flatMap
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

