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

@(test)
test_king_valid_moves :: proc(t: ^testing.T) {
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

    white_king := main.Piece{
        player = main.Player.WHITE,
        type = main.Piece_Type.KING,
        position_on_board = {0, 5}
    }

    append(&pieces,
        white_king,
        main.Piece{
            player = main.Player.BLACK,
            type = main.Piece_Type.QUEEN,
            position_on_board = {7, 6}
        }
    )

    game.board.pieces = pieces
    valid_moves_for_white_king := main.valid_moves(game, white_king, nil)
    defer delete(valid_moves_for_white_king)

    valid_expected_squares := [3][2]int{
        {0, 4},
        {1, 4},
        {1, 5}
    }

    found: bool 
    for move in valid_moves_for_white_king {
        found = false
        for expected_move in valid_expected_squares {
            if move.row == expected_move.x && move.col == expected_move.y {
                found = true
                break
            }
        }

        testing.expectf(t,
            found == true,
            "Found an invalid Square; row: %i col: %i", move.row, move.col
        )

    }


    testing.expect(t,
        len(valid_moves_for_white_king) == 3,
        "Invalid number of moves, should be 3"
    )
}

