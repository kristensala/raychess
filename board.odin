package main

import "core:fmt"
import "core:mem"
import "core:crypto"
import "core:slice"
import "core:encoding/uuid"
import rl "vendor:raylib"

Board :: struct {
    position: [2]i32,
    height: int,
    width: int,
    squares: [dynamic][dynamic]Square,
    pieces: [dynamic]Piece,
    white_king_pos: [2]int,
    black_king_pos: [2]int
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
    // pos while dragging the piece
    rect: rl.Rectangle,
    // pos on the board
    // can use this to know the starting pos when making the move
    position_on_board: [2]int, // {row, col}
    texture: rl.Texture2D,
    type: Piece_Type
}

COLUMNS :: [8]string{"a", "b", "c", "d", "e", "f", "g", "h"}
ROWS :: [8]string{"1", "2", "3", "4", "5", "6", "7", "8"}
SQUARE_SIZE :: 100

init_board :: proc(game: ^Game) {
    board := Board {
        position = {0, 700},
    }
    create_squares(&board)

    game.board = board
    add_pieces(game)
}

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

    board_pieces_clone := slice.clone_to_dynamic(game.board.pieces[:])
    defer delete(board_pieces_clone)
    append(&game.board_history, board_pieces_clone)
}

@(private)
move_piece :: proc(game: ^Game, piece_to_move: ^Piece, destination: Square) -> bool {
    if !is_valid_move(game, piece_to_move^, destination) {
        return false
    }

    has_piece, piece, piece_index := square_has_piece(game.board, destination)
    if has_piece && piece.player != piece_to_move.player && piece.type != .KING {
        fmt.println("removing piece from board: ", piece)

        piece.position_on_board = {}

        piece_to_move.rect.x = destination.rect.x
        piece_to_move.rect.y = destination.rect.y
        piece_to_move.position_on_board = {destination.row, destination.col}

        // @note: order is important
        // whites and blacks need to be bunched up respectively
        // wait what... am I racist...
        ordered_remove(&game.board.pieces, piece_index)
    } else {
        piece_to_move.rect.x = destination.rect.x
        piece_to_move.rect.y = destination.rect.y
        piece_to_move.position_on_board = {destination.row, destination.col}
    }

    if piece_to_move.type == .KING {
        if piece_to_move.player == .WHITE {
            game.board.white_king_pos = piece_to_move.position_on_board
        }

        if piece_to_move.player == .BLACK {
            game.board.black_king_pos = piece_to_move.position_on_board
        }
    }

    save_move(game)
    return true
}

// @note: do not add pieces in a random order
// first add ALL whites then ALL blacks
// or the other way around
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
    game.board.white_king_pos = wk_pos
    append(&game.board.pieces, wk_piece)

    /* WHITE QUEEN */
    wq_texture := rl.LoadTexture("./assets/wq.png")
    wq_texture.height = SQUARE_SIZE
    wq_texture.width = SQUARE_SIZE

    wq_pos := [2]int{2, 3}
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

    // BLACK KING
    bk_pos := [2]int{7, 4}
    bk_texture := rl.LoadTexture("./assets/bk.png")
    bk_texture.height = SQUARE_SIZE
    bk_texture.width = SQUARE_SIZE

    bk_rect := rl.Rectangle{
        x = game.board.squares[bk_pos.x][bk_pos.y].rect.x,
        y = game.board.squares[bk_pos.x][bk_pos.y].rect.y,
        height = SQUARE_SIZE,
        width = SQUARE_SIZE
    }

    bk_piece := Piece{
        number = uuid.generate_v7(),
        texture = bk_texture,
        player = Player.BLACK,
        type = Piece_Type.KING,
        rect = bk_rect,
        position_on_board = bk_pos
    }
    game.board.black_king_pos = bk_pos
    append(&game.board.pieces, bk_piece)


    /* BLACK QUEEN */
    bq_pos := [2]int{7, 3}
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

// note: Enemy king square is highlighted
// as valid move square, to detect if it is 
// under check, but do not allow it as an actual valid move
is_valid_move :: proc(game: ^Game, piece_to_move: Piece, move_to: Square) -> bool {
    // if move_to Square has enemy king on it return false
    for piece in game.board.pieces {
        if piece.type == .KING &&
            piece.player != piece_to_move.player &&
            piece.position_on_board.x == move_to.row &&
            piece.position_on_board.y == move_to.col
        {
            return false
        }
    }

    moves := valid_moves(game, piece_to_move)
    defer delete(moves)

    for valid_move in moves {
        if valid_move.col == move_to.col && valid_move.row == move_to.row {
            return true
        }
    }

    return false
}

// @note: if ignore_king is true then
// valid moves are calculated across the full board
// to see which squares are covered by opponent pieces
// and this allows me to calculate correct moves for the king.

// 'ignore_king = true' means that when calculating valid squares
// king position on the board will not block valid moves for QUEEN, ROOKS, BISHOPS
valid_moves :: proc(
    game: ^Game,
    piece: Piece,
    ignore_king: bool = false
) -> [dynamic]Square {
    moves: [dynamic]Square
    if piece.type == .KING {
        add_valid_moves_east(game, piece, &moves)
        add_valid_moves_west(game, piece, &moves)
        add_valid_moves_north(game, piece, &moves)
        add_valid_moves_south(game, piece, &moves)
        add_valid_moves_north_east(game, piece, &moves)
        add_valid_moves_north_west(game, piece, &moves)
        add_valid_moves_south_east(game, piece, &moves)
        add_valid_moves_south_west(game, piece, &moves)

        // Calculate valid moves for the king by taking
        // into consideration which scuares are covered by opponent pieces
        // mock a king move
        // and then see if it is still in check
        // if so, then not a valid move

        // when calculating moves for the king
        // here ignore opponents king
        if ignore_king {
            return moves
        }

        game_clone := new_clone(game^)
        defer free(game_clone)

        valid_king_moves: [dynamic]Square
        for square in moves {
            if piece.player == .BLACK {
                game_clone.board.black_king_pos = {square.row, square.col}
            }

            if piece.player == .WHITE {
                game_clone.board.white_king_pos = {square.row, square.col}
            }

            // @bug: pieces do not block the check from opponent piece
            ok := will_king_be_in_check(game_clone, piece.player)
            if !ok {
                append(&valid_king_moves, square)
            }

        }
        return valid_king_moves
    }

    if piece.type == .QUEEN {
        add_valid_moves_east(game, piece, &moves, ignore_king)
        add_valid_moves_west(game, piece, &moves, ignore_king)
        add_valid_moves_north(game, piece, &moves, ignore_king)
        add_valid_moves_south(game, piece, &moves, ignore_king)
        add_valid_moves_north_east(game, piece, &moves, ignore_king)
        add_valid_moves_north_west(game, piece, &moves, ignore_king)
        add_valid_moves_south_east(game, piece, &moves, ignore_king)
        add_valid_moves_south_west(game, piece, &moves, ignore_king)

        return moves
    }

    if piece.type == .ROOK {
        add_valid_moves_east(game, piece, &moves, ignore_king)
        add_valid_moves_west(game, piece, &moves, ignore_king)
        add_valid_moves_north(game, piece, &moves, ignore_king)
        add_valid_moves_south(game, piece, &moves, ignore_king)
        return moves
    }

    if piece.type == .BISHOP {
        add_valid_moves_north_east(game, piece, &moves, ignore_king)
        add_valid_moves_north_west(game, piece, &moves, ignore_king)
        add_valid_moves_south_east(game, piece, &moves, ignore_king)
        add_valid_moves_south_west(game, piece, &moves, ignore_king)
        return moves
    }

    return moves
}

// @todo:
// take this into consideration
// when calculating valid moves.
//
// I should also return the piece which gives the check
// then I can use its pos and the kings pos
// to calculate squares to block the check or maybe take the piece

// this shit is broken
@require_results
is_king_in_check :: proc(game: ^Game, player: Player, ignore_king: bool = false) -> (bool, ^Piece) {
    for &piece in game.board.pieces {
        // check over opponents pieces
        if piece.player == player {
            continue
        }

        // check if white king is in check by current only black piece
        piece_valid_moves := valid_moves(game, piece, ignore_king)
        defer delete(piece_valid_moves)

        for valid_move in piece_valid_moves {
            if valid_move.row == game.board.white_king_pos.x && valid_move.col == game.board.white_king_pos.y {
                return true, &piece
            }
        }
    }
    return false, nil
}

will_king_be_in_check :: proc(game_clone: ^Game, player_moving: Player) -> bool {
    for &piece in game_clone.board.pieces {
        // skip player own pieces
        if piece.player == player_moving {
            continue
        }

        valid_moves := valid_moves(game_clone, piece, true)
        defer delete(valid_moves)

        for valid_move in valid_moves {
            if player_moving == .WHITE {
                if valid_move.row == game_clone.board.white_king_pos.x && valid_move.col == game_clone.board.white_king_pos.y {
                    return true
                }
            }

            if player_moving == .BLACK {
                if valid_move.row == game_clone.board.black_king_pos.x && valid_move.col == game_clone.board.black_king_pos.y {
                    return true
                }
            }
        }
    }

    return false
}

/*
    If true, it means that we detected a piece
    and if in a loop, we should break out
*/
@(private = "file")
append_move :: proc(
    game: ^Game,
    piece: Piece,
    square_to_add: Square,
    dest: ^[dynamic]Square,
    ignore_king: bool = false
) -> bool {
    has_piece, found_piece, _ := square_has_piece(game.board, square_to_add)
    if has_piece {
        if piece.player != found_piece.player {
            append(dest, square_to_add)
        }
        if found_piece.type == .KING && ignore_king {
            return false
        }
        return true
    }

    append(dest, square_to_add)
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
add_valid_moves_north :: proc(
    game: ^Game,
    piece: Piece,
    moves: ^[dynamic]Square,
    ignore_king: bool = false
) {
    for i := piece.position_on_board.x + 1; i < len(ROWS); i += 1 {
        s := game.board.squares[i][piece.position_on_board.y]

        should_break := append_move(game, piece, s, moves, ignore_king)
        if should_break || piece.type == .KING {
            break
        }
    }
}

@(private = "file")
add_valid_moves_south :: proc(
    game: ^Game,
    piece: Piece,
    moves: ^[dynamic]Square,
    ignore_king: bool = false
) {
    for i := piece.position_on_board.x - 1; i >= 0; i -= 1 {
        s := game.board.squares[i][piece.position_on_board.y]

        should_break := append_move(game, piece, s, moves, ignore_king)
        if should_break || piece.type == .KING {
            break
        }
    }
}

@(private = "file")
add_valid_moves_east :: proc(
    game: ^Game,
    piece: Piece,
    moves: ^[dynamic]Square,
    ignore_king: bool = false
) {
    for i := piece.position_on_board.y + 1; i < len(COLUMNS); i += 1 {
        s := game.board.squares[piece.position_on_board.x][i]

        should_break := append_move(game, piece, s, moves, ignore_king)
        if should_break || piece.type == .KING {
            break
        }
    }
}

@(private = "file")
add_valid_moves_west :: proc(
    game: ^Game,
    piece: Piece, 
    moves: ^[dynamic]Square, 
    ignore_king: bool = false
) {
    for i := piece.position_on_board.y - 1; i >= 0; i -= 1 {
        s := game.board.squares[piece.position_on_board.x][i]

        should_break := append_move(game, piece, s, moves, ignore_king)
        if should_break  || piece.type == .KING {
            break
        }
    }
}

@(private = "file")
add_valid_moves_north_west :: proc(
    game: ^Game,
    piece: Piece,
    moves: ^[dynamic]Square,
    ignore_king: bool = false
) {
    col_idx := piece.position_on_board.y - 1
    for i := piece.position_on_board.x + 1; i < len(ROWS); i += 1 {
        if col_idx < 0 {
            break;
        }

        s := game.board.squares[i][col_idx]

        should_break := append_move(game, piece, s, moves, ignore_king)
        if should_break  || piece.type == .KING {
            break
        }
        col_idx -= 1
    }
}

@(private = "file")
add_valid_moves_north_east :: proc(
    game: ^Game,
    piece: Piece,
    moves: ^[dynamic]Square,
    ignore_king: bool = false
) {
    col_idx := piece.position_on_board.y + 1
    for i := piece.position_on_board.x + 1; i < len(ROWS); i += 1 {
        if col_idx >= len(COLUMNS) {
            break
        }

        s := game.board.squares[i][col_idx]

        should_break := append_move(game, piece, s, moves, ignore_king)
        if should_break  || piece.type == .KING {
            break
        }

        col_idx += 1
    }
}

@(private = "file")
add_valid_moves_south_east :: proc(
    game: ^Game,
    piece: Piece,
    moves: ^[dynamic]Square,
    ignore_king: bool = false
) {
    col_idx := piece.position_on_board.y + 1
    for i := piece.position_on_board.x - 1; i >= 0; i -= 1 {
        if col_idx >= len(COLUMNS) {
            break
        }

        s := game.board.squares[i][col_idx]
        should_break := append_move(game, piece, s, moves, ignore_king)
        if should_break  || piece.type == .KING {
            break
        }

        col_idx += 1
    }
}

@(private = "file")
add_valid_moves_south_west :: proc(
    game: ^Game,
    piece: Piece,
    moves: ^[dynamic]Square,
    ignore_king: bool = false
) {
    col_idx := piece.position_on_board.y - 1
    for i := piece.position_on_board.x - 1; i >= 0; i -= 1 {
        if col_idx < 0 {
            break
        }

        s := game.board.squares[i][col_idx]

        should_break := append_move(game, piece, s, moves, ignore_king)
        if should_break  || piece.type == .KING {
            break
        }

        col_idx -= 1
    }
}

@(private = "file")
save_move :: proc(game: ^Game) -> mem.Allocator_Error {
    pieces_clone := slice.clone_to_dynamic(game.board.pieces[:]) or_return
    append(&game.board_history, pieces_clone) or_return
    return nil
}

