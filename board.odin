package main

import "core:fmt"
import rl "vendor:raylib"

Board :: struct {
    position: [2]i32,
    height: int,
    width: int,
    squares: [dynamic][dynamic]Square,
    pieces: [dynamic]Piece
}

Square :: struct {
    row: int,
    col: int,
    color: rl.Color,
    rect: rl.Rectangle
}

Piece_type :: enum {
    KING,
    QUEEN,
    KNIGHT,
    PAWN,
    PISHOP,
    ROOK
}

Piece :: struct {
    number: int, // id for pieces which have duplicates (pawns, khights, pishops, rooks)
    player: Player,
    rect: rl.Rectangle,
    position_on_board: [2]int, // {row, col}
    texture: rl.Texture2D,
    type: Piece_type,
    is_active: bool
}

COLUMNS :: [8]string{"a", "b", "c", "d", "e", "f", "g", "h"}
ROWS :: [8]string{"1", "2", "3", "4", "5", "6", "7", "8"}
SQUARE_SIZE :: 100

@(private)
create_squares :: proc(board: ^Board) {
    square_start_x := board.position.x
    square_start_y := board.position.y
    square_color: rl.Color

    for i := 0; i < len(ROWS); i += 1  {
        row_array: [dynamic]Square

        for column, col_idx in COLUMNS {
            if i % 2 == 0 {
                if col_idx % 2 == 0 {
                    square_color = rl.BROWN
                } else {
                    square_color = rl.BEIGE
                }
            } else {
                if col_idx % 2 != 0 {
                    square_color = rl.BROWN
                } else {
                    square_color = rl.BEIGE
                }
            }

            rect := rl.Rectangle{
                x = f32(square_start_x),
                y = f32(square_start_y),
                width = f32(SQUARE_SIZE),
                height = f32(SQUARE_SIZE)
            }

            square := Square{
                color = square_color,
                row = i,
                col = col_idx,
                rect = rect
            }

            square_start_x += SQUARE_SIZE
            append(&row_array, square)

        }
        append(&board.squares, row_array)
        clear(&row_array)

        square_start_x = board.position.x
        square_start_y -= SQUARE_SIZE
    }
}

@(private)
move_piece :: proc(game: ^Game, piece_to_move: ^Piece, destination: ^Square) {
    if !is_valid_move(game, piece_to_move, destination) {
        return
    }

    piece_to_move.rect.x = destination.rect.x
    piece_to_move.rect.y = destination.rect.y
    piece_to_move.position_on_board = {destination.row, destination.col}
}

@(private)
add_pieces :: proc(game: ^Game) {
    /* WHITE QUEEN */
    wq_texture := rl.LoadTexture("./assets/wq.png")
    wq_texture.height = SQUARE_SIZE
    wq_texture.width = SQUARE_SIZE

    wq_rect := rl.Rectangle{
        x = game.board.squares[1][1].rect.x,
        y = game.board.squares[1][1].rect.y,
        height = SQUARE_SIZE,
        width = SQUARE_SIZE
    }

    wq_piece := Piece{
        texture = wq_texture,
        player = Player.WHITE,
        type = Piece_type.QUEEN,
        rect = wq_rect,
        is_active = false,
        position_on_board = {1,1}
    }
    append(&game.board.pieces, wq_piece)

    /* WHITE ROOK 1 */

    /* WHITE ROOK 2 */

}

is_valid_move :: proc(game: ^Game, piece: ^Piece, move_to: ^Square) -> bool {
    moves := valid_moves(game, piece)
    defer delete(moves)

    for move in moves {
        if move.col == move_to.col && move.row == move_to.row {
            return true
        }
    }

    return false
}

valid_moves :: proc(game: ^Game, piece: ^Piece) -> [dynamic]Square {
    moves: [dynamic]Square
    board := game.board

    if piece.type == .QUEEN {
        add_valid_moves_east(&board, piece, &moves)
        add_valid_moves_west(&board, piece, &moves)
        add_valid_moves_north(&board, piece, &moves)
        add_valid_moves_south(&board, piece, &moves)
        add_valid_moves_north_east(&board, piece, &moves)
        add_valid_moves_north_west(&board, piece, &moves)
        add_valid_moves_south_east(&board, piece, &moves)
        add_valid_moves_south_west(&board, piece, &moves)

    }
    return moves
}

/*
If true, it means that we detected a piece
and if in a loop, we should break out
*/
@(private = "file")
append_move :: proc(board: ^Board, piece: ^Piece, square_to_add: ^Square, dest: ^[dynamic]Square) -> bool {
    has_piece, found_piece := square_has_piece(board, square_to_add)
    if has_piece {
        if piece.player != found_piece.player {
            append(dest, square_to_add^)
        }
        return true
    } else {
        append(dest, square_to_add^)
    }

    return false
}

@(private = "file")
square_has_piece :: proc(board: ^Board, square: ^Square) -> (bool, ^Piece) {
    for &piece in board.pieces {
        piece_coords := piece.position_on_board
        if piece_coords.x == square.row && piece_coords.y == square.col {
            return true, &piece
        }
    }

    return false, nil
}

@(private = "file")
add_valid_moves_north :: proc(board: ^Board, piece: ^Piece, moves: ^[dynamic]Square) {
    for i := piece.position_on_board.x + 1; i < len(ROWS); i += 1 {
        s := board.squares[i][piece.position_on_board.y]

        should_break := append_move(board, piece, &s, moves)
        if should_break {
            break
        }
    }
}

@(private = "file")
add_valid_moves_south :: proc(board: ^Board, piece: ^Piece, moves: ^[dynamic]Square) {
    for i := piece.position_on_board.x - 1; i >= 0; i -= 1 {
        s := board.squares[i][piece.position_on_board.y]

        should_break := append_move(board, piece, &s, moves)
        if should_break {
            break
        }
    }
}

@(private = "file")
add_valid_moves_east :: proc(board: ^Board, piece: ^Piece, moves: ^[dynamic]Square) {
    for i := piece.position_on_board.y + 1; i < len(COLUMNS); i += 1 {
        s := board.squares[piece.position_on_board.x][i]

        should_break := append_move(board, piece, &s, moves)
        if should_break {
            break
        }
    }
}

@(private = "file")
add_valid_moves_west :: proc(board: ^Board, piece: ^Piece, moves: ^[dynamic]Square) {
    for i := piece.position_on_board.y - 1; i >= 0; i -= 1 {
        s := board.squares[piece.position_on_board.x][i]

        should_break := append_move(board, piece, &s, moves)
        if should_break {
            break
        }
    }
}


@(private = "file")
add_valid_moves_north_west :: proc(board: ^Board, piece: ^Piece, moves: ^[dynamic]Square) {
    col_idx := piece.position_on_board.y - 1
    for i := piece.position_on_board.x + 1; i < len(ROWS); i += 1 {
        if col_idx < 0 {
            break
        }

        s := board.squares[i][col_idx]

        should_break := append_move(board, piece, &s, moves)
        if should_break {
            break
        }
        col_idx -= 1
    }
}

@(private = "file")
add_valid_moves_north_east :: proc(board: ^Board, piece: ^Piece, moves: ^[dynamic]Square) {
    col_idx := piece.position_on_board.y + 1
    for i := piece.position_on_board.x + 1; i < len(ROWS); i += 1 {
        if col_idx >= len(COLUMNS) {
            break
        }

        s := board.squares[i][col_idx]

        should_break := append_move(board, piece, &s, moves)
        if should_break {
            break
        }

        col_idx += 1
    }
}

@(private = "file")
add_valid_moves_south_east :: proc(board: ^Board, piece: ^Piece, moves: ^[dynamic]Square) {
    col_idx := piece.position_on_board.y + 1
    for i := piece.position_on_board.x - 1; i >= 0; i -= 1 {
        if col_idx >= len(COLUMNS) {
            break
        }

        s := board.squares[i][col_idx]

        should_break := append_move(board, piece, &s, moves)
        if should_break {
            break
        }

        col_idx += 1
    }
}

@(private = "file")
add_valid_moves_south_west :: proc(board: ^Board, piece: ^Piece, moves: ^[dynamic]Square) {
    col_idx := piece.position_on_board.y - 1
    for i := piece.position_on_board.x - 1; i >= 0; i -= 1 {
        if col_idx < 0 {
            break
        }

        s := board.squares[i][col_idx]

        should_break := append_move(board, piece, &s, moves)
        if should_break {
            break
        }

        col_idx -= 1
    }
}



