package main

import "core:fmt"
import "core:crypto"
import "core:slice"
import "core:encoding/uuid"
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

Piece_Type :: enum {
    KING,
    QUEEN,
    KNIGHT,
    PAWN,
    BISHOP,
    ROOK
}

Piece :: struct {
    number: uuid.Identifier,
    player: Player,
    rect: rl.Rectangle,
    position_on_board: [2]int, // {row, col}
    texture: rl.Texture2D,
    type: Piece_Type
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
reset_game:: proc(game: ^Game) {
    clear(&game.board.pieces)
    add_pieces(game)
}

@(private)
move_piece :: proc(game: ^Game, piece_to_move: ^Piece, destination: Square) -> bool {
    if !is_valid_move(game, piece_to_move^, destination) {
        return false;
    }

    has_piece, piece, piece_index := square_has_piece(game.board, destination)
    if has_piece && piece.player != piece_to_move.player && piece.type != .KING {
        fmt.println("removing piece from board: ", piece)

        piece.position_on_board = {}

        // @note: need to snap into place before removing
        // the old piece for some reason.
        // Fixes the black piece not snapping
        // into the square after take
        piece_to_move.rect.x = destination.rect.x
        piece_to_move.rect.y = destination.rect.y
        piece_to_move.position_on_board = {destination.row, destination.col}

        // @note: order is important
        // whites and blacks need to be bunched up
        ordered_remove(&game.board.pieces, piece_index)
    } else {
        piece_to_move.rect.x = destination.rect.x
        piece_to_move.rect.y = destination.rect.y
        piece_to_move.position_on_board = {destination.row, destination.col}
    }

    //save_move(&game.board.pieces)

    return true;
}

// @note: do not add pieces in a random order
// first add ALL whites then ALL blacks
// or the other way around
@(private)
add_pieces :: proc(game: ^Game) {
    //------------WHITE PIECES---------------
    context.random_generator = crypto.random_generator()

    /* WHITE KING */
    wk_texture := rl.LoadTexture("./assets/wk.png")
    wk_texture.height = SQUARE_SIZE
    wk_texture.width = SQUARE_SIZE

    wk_pos := [2]int{0, 4}
    wk_rect := rl.Rectangle{
        x = game.board.squares[wk_pos.x][wk_pos.y].rect.x,
        y = game.board.squares[wk_pos.x][wk_pos.y].rect.y,
        height = SQUARE_SIZE,
        width = SQUARE_SIZE
    }

    wk_piece := Piece{
        number = uuid.generate_v7(),
        texture = wk_texture,
        player = Player.WHITE,
        type = Piece_Type.KING,
        rect = wk_rect,
        position_on_board = wk_pos
    }
    append(&game.board.pieces, wk_piece)

    /* WHITE QUEEN */
    wq_texture := rl.LoadTexture("./assets/wq.png")
    wq_texture.height = SQUARE_SIZE
    wq_texture.width = SQUARE_SIZE

    wq_pos := [2]int{0, 3}
    wq_rect := rl.Rectangle{
        x = game.board.squares[wq_pos.x][wq_pos.y].rect.x,
        y = game.board.squares[wq_pos.x][wq_pos.y].rect.y,
        height = SQUARE_SIZE,
        width = SQUARE_SIZE
    }

    wq_piece := Piece{
        number = uuid.generate_v7(),
        texture = wq_texture,
        player = Player.WHITE,
        type = Piece_Type.QUEEN,
        rect = wq_rect,
        position_on_board = wq_pos
    }
    append(&game.board.pieces, wq_piece)

    /* WHITE ROOK 1 */
    wr_pos := [2]int{0, 0}
    wr_texture := rl.LoadTexture("./assets/wr.png")
    wr_texture.height = SQUARE_SIZE
    wr_texture.width = SQUARE_SIZE

    wr_rect := rl.Rectangle{
        x = game.board.squares[wr_pos.x][wr_pos.y].rect.x,
        y = game.board.squares[wr_pos.x][wr_pos.y].rect.y,
        height = SQUARE_SIZE,
        width = SQUARE_SIZE
    }

    wr_piece := Piece{
        number = uuid.generate_v7(),
        texture = wr_texture,
        player = Player.WHITE,
        type = Piece_Type.ROOK,
        rect = wr_rect,
        position_on_board = wr_pos
    }
    append(&game.board.pieces, wr_piece)

    /* WHITE ROOK 2 */
    wrr_pos := [2]int{0, 7}
    wrr_rect := rl.Rectangle{
        x = game.board.squares[wrr_pos.x][wrr_pos.y].rect.x,
        y = game.board.squares[wrr_pos.x][wrr_pos.y].rect.y,
        height = SQUARE_SIZE,
        width = SQUARE_SIZE
    }

    wrr_piece := Piece{
        number = uuid.generate_v7(),
        texture = wr_texture,
        player = Player.WHITE,
        type = Piece_Type.ROOK,
        rect = wrr_rect,
        position_on_board = wrr_pos
    }
    append(&game.board.pieces, wrr_piece)

    //------------BLACK PIECES---------------

    /* BLACK QUEEN */
    bq_pos := [2]int{7, 4}
    bq_texture := rl.LoadTexture("./assets/bq.png")
    bq_texture.height = SQUARE_SIZE
    bq_texture.width = SQUARE_SIZE

    bq_rect := rl.Rectangle{
        x = game.board.squares[bq_pos.x][bq_pos.y].rect.x,
        y = game.board.squares[bq_pos.x][bq_pos.y].rect.y,
        height = SQUARE_SIZE,
        width = SQUARE_SIZE
    }

    bq_piece := Piece{
        number = uuid.generate_v7(),
        texture = bq_texture,
        player = Player.BLACK,
        type = Piece_Type.QUEEN,
        rect = bq_rect,
        position_on_board = bq_pos
    }
    append(&game.board.pieces, bq_piece)
}

is_valid_move :: proc(game: ^Game, piece: Piece, move_to: Square) -> bool {
    moves := valid_moves(game, piece)
    defer delete(moves)

    for move in moves {
        if move.col == move_to.col && move.row == move_to.row {
            return true
        }
    }

    return false
}

valid_moves :: proc(game: ^Game, piece: Piece) -> [dynamic]Square {
    moves: [dynamic]Square
    board := game.board

    if piece.type == .QUEEN {
        add_valid_moves_east(board, piece, &moves)
        add_valid_moves_west(board, piece, &moves)
        add_valid_moves_north(board, piece, &moves)
        add_valid_moves_south(board, piece, &moves)
        add_valid_moves_north_east(board, piece, &moves)
        add_valid_moves_north_west(board, piece, &moves)
        add_valid_moves_south_east(board, piece, &moves)
        add_valid_moves_south_west(board, piece, &moves)
        return moves
    }

    if piece.type == .ROOK {
        add_valid_moves_east(board, piece, &moves)
        add_valid_moves_west(board, piece, &moves)
        add_valid_moves_north(board, piece, &moves)
        add_valid_moves_south(board, piece, &moves)
        return moves
    }

    if piece.type == .BISHOP {
        add_valid_moves_north_east(board, piece, &moves)
        add_valid_moves_north_west(board, piece, &moves)
        add_valid_moves_south_east(board, piece, &moves)
        add_valid_moves_south_west(board, piece, &moves)
        return moves
    }

    return moves
}

@(private)
take_piece :: proc() {
}

/*
If true, it means that we detected a piece
and if in a loop, we should break out
*/
@(private = "file")
append_move :: proc(
    board: Board,
    piece: Piece,
    square_to_add: Square,
    dest: ^[dynamic]Square
) -> bool {
    has_piece, found_piece, _ := square_has_piece(board, square_to_add)
    if has_piece {
        if piece.player != found_piece.player && found_piece.type != .KING {
            append(dest, square_to_add)
        }
        return true
    } else {
        append(dest, square_to_add)
    }

    return false
}

@(private = "file")
square_has_piece :: proc(
    board: Board,
    square: Square
) -> (
    has_piece: bool,
    found_piece: ^Piece,
    found_piece_idx: int
) {
    for &piece, idx in board.pieces {
        piece_coords := piece.position_on_board
        if piece_coords.x == square.row && piece_coords.y == square.col {
            return true, &piece, idx
        }
    }

    return false, nil, -1
}

@(private = "file")
add_valid_moves_north :: proc(board: Board, piece: Piece, moves: ^[dynamic]Square) {
    for i := piece.position_on_board.x + 1; i < len(ROWS); i += 1 {
        s := board.squares[i][piece.position_on_board.y]

        should_break := append_move(board, piece, s, moves)
        if should_break {
            break
        }
    }
}

@(private = "file")
add_valid_moves_south :: proc(board: Board, piece: Piece, moves: ^[dynamic]Square) {
    for i := piece.position_on_board.x - 1; i >= 0; i -= 1 {
        s := board.squares[i][piece.position_on_board.y]

        should_break := append_move(board, piece, s, moves)
        if should_break {
            break
        }
    }
}

@(private = "file")
add_valid_moves_east :: proc(board: Board, piece: Piece, moves: ^[dynamic]Square) {
    for i := piece.position_on_board.y + 1; i < len(COLUMNS); i += 1 {
        s := board.squares[piece.position_on_board.x][i]

        should_break := append_move(board, piece, s, moves)
        if should_break {
            break
        }
    }
}

@(private = "file")
add_valid_moves_west :: proc(board: Board, piece: Piece, moves: ^[dynamic]Square) {
    for i := piece.position_on_board.y - 1; i >= 0; i -= 1 {
        s := board.squares[piece.position_on_board.x][i]

        should_break := append_move(board, piece, s, moves)
        if should_break {
            break
        }
    }
}


@(private = "file")
add_valid_moves_north_west :: proc(board: Board, piece: Piece, moves: ^[dynamic]Square) {
    col_idx := piece.position_on_board.y - 1
    for i := piece.position_on_board.x + 1; i < len(ROWS); i += 1 {
        if col_idx < 0 {
            break
        }

        s := board.squares[i][col_idx]

        should_break := append_move(board, piece, s, moves)
        if should_break {
            break
        }
        col_idx -= 1
    }
}

@(private = "file")
add_valid_moves_north_east :: proc(board: Board, piece: Piece, moves: ^[dynamic]Square) {
    col_idx := piece.position_on_board.y + 1
    for i := piece.position_on_board.x + 1; i < len(ROWS); i += 1 {
        if col_idx >= len(COLUMNS) {
            break
        }

        s := board.squares[i][col_idx]

        should_break := append_move(board, piece, s, moves)
        if should_break {
            break
        }

        col_idx += 1
    }
}

@(private = "file")
add_valid_moves_south_east :: proc(board: Board, piece: Piece, moves: ^[dynamic]Square) {
    col_idx := piece.position_on_board.y + 1
    for i := piece.position_on_board.x - 1; i >= 0; i -= 1 {
        if col_idx >= len(COLUMNS) {
            break
        }

        s := board.squares[i][col_idx]

        should_break := append_move(board, piece, s, moves)
        if should_break {
            break
        }

        col_idx += 1
    }
}

@(private = "file")
add_valid_moves_south_west :: proc(board: Board, piece: Piece, moves: ^[dynamic]Square) {
    col_idx := piece.position_on_board.y - 1
    for i := piece.position_on_board.x - 1; i >= 0; i -= 1 {
        if col_idx < 0 {
            break
        }

        s := board.squares[i][col_idx]

        should_break := append_move(board, piece, s, moves)
        if should_break {
            break
        }

        col_idx -= 1
    }
}

save_move :: proc(pieces: ^[dynamic]Piece) {
    t := slice.clone_to_dynamic(pieces[:])
    append(&move_history, t)
}

