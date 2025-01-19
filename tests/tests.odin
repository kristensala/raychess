package tests

import "core:testing"
import "core:fmt"

import main "../"

@(test)
test_is_king_in_check :: proc(t: ^testing.T) {
    game := new(main.Game)
    defer free(game)

    board := main.Board {
        position = {0, 700},
        white_king_pos = {0, 5}
    }

    main.create_squares(&board)
    game.board = board

    pieces := make([dynamic]main.Piece)
    defer delete(pieces)

    append(&pieces,
        main.Piece{
            player = main.Player.WHITE,
            type = main.Piece_Type.KING,
            position_on_board = {0, 5}
        },
        main.Piece{
            player = main.Player.BLACK,
            type = main.Piece_Type.QUEEN,
            position_on_board = {0, 7}
        }
    )

    game.board.pieces = pieces

    is_check, from_piece := main.is_king_in_check(game, main.Player.WHITE)

    testing.expect(t,
        is_check == true && from_piece.type == main.Piece_Type.QUEEN,
        "White King should be under check by BLACK Queen"
    )
}

