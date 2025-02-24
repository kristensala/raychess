package main

import "core:fmt"
import "core:mem"
import "core:crypto"
import "core:slice"
import "core:encoding/uuid"
import rl "vendor:raylib"

COLUMNS :: [8]string{"a", "b", "c", "d", "e", "f", "g", "h"}
ROWS :: [8]string{"1", "2", "3", "4", "5", "6", "7", "8"}
SQUARE_SIZE :: 100

Player :: enum {
    NONE,
    WHITE,
    BLACK
}

Game :: struct {
    board: Board,
    board_history: [dynamic][dynamic]Piece,
    turn: Player
}

// @new
Piece_Key :: enum {
    QUEEN,
    KING,
    A_ROOK,
    H_ROOK,
    B_KNIGHT,
    G_KNIGHT,
    F_BISHOP,
    C_BISHOP,
    A_PAWN,
    B_PAWN,
    C_PAWN,
    D_PAWN,
    E_PAWN,
    F_PAWN,
    G_PAWN,
    H_PAWN,
}

Board :: struct {
    position: [2]i32,
    height: int,
    width: int,
    squares: [dynamic][dynamic]Square,
    pieces_map: map[Player]map[Piece_Key]Piece,
    squares_map: map[string]Square
}

Square :: struct {
    row: int,
    col: int,
    color: rl.Color,
    rect: rl.Rectangle
}

Piece :: struct {
    player: Player,
    rect: rl.Rectangle,
    texture: rl.Texture2D,
    position_on_board: [2]int, // {row, col}
    type: Piece_Key,
}


init_board :: proc(game: ^Game) {
    board := Board {
        position = {0, 700},
    }
    create_squares(&board)

    game.board = board
    add_pieces(game)
}

// @test
// keys will be a1 b1 g8 and so on... as strings
build_board :: proc(board: ^Board) {
    square_start_x := board.position.x
    square_start_y := board.position.y
    square_color: rl.Color

    squares: map[string]Square

    for row, row_idx in ROWS {
        for column, col_idx in COLUMNS {
            key := fmt.aprintf("{0}{1}", column, row)
            if row_idx % 2 == 0 {
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
                row = row_idx,
                col = col_idx,
                rect = rect
            }

            squares[key] = square
        }
    }
}

// @todo: build map rather than an array
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
    clear(&game.board.pieces_map)
    add_pieces(game)

    /*board_pieces_clone := slice.clone_to_dynamic(game.board.pieces[:])
    defer delete(board_pieces_clone)
    append(&game.board_history, board_pieces_clone)*/
}

@(private)
move_piece :: proc(game: ^Game, piece_to_move: ^Piece, destination: Square) -> bool {
    if !is_valid_move(game, piece_to_move, destination) {
        return false
    }

    has_piece, piece_key, piece_player := square_has_piece(game.board, destination)
    if has_piece && piece_player != piece_to_move.player && piece_key != .KING {
        piece := game.board.pieces_map[piece_player][piece_key]
        piece.position_on_board = {}

        piece_to_move.rect.x = destination.rect.x
        piece_to_move.rect.y = destination.rect.y
        piece_to_move.position_on_board = {destination.row, destination.col}

        delete_key(&game.board.pieces_map[piece_player], piece_key)
    } else {
        piece_to_move.rect.x = destination.rect.x
        piece_to_move.rect.y = destination.rect.y
        piece_to_move.position_on_board = {destination.row, destination.col}
    }

    save_move(game)
    return true
}

@(private = "file")
create_piece :: proc(piece_map: ^map[Piece_Key]Piece , game: Game, img: cstring, pos: [2]int, player: Player, key: Piece_Key) {
    texture := rl.LoadTexture(img)
    texture.height = SQUARE_SIZE
    texture.width = SQUARE_SIZE

    rect := rl.Rectangle{
        x = game.board.squares[pos.x][pos.y].rect.x,
        y = game.board.squares[pos.x][pos.y].rect.y,
        height = SQUARE_SIZE,
        width = SQUARE_SIZE
    }

    piece := Piece{
        texture = texture,
        player = player,
        rect = rect,
        type = key,
        position_on_board = pos
    }

    piece_map[key] = piece
}

add_pieces :: proc(game: ^Game) {
    white_pieces: map[Piece_Key]Piece

    /* White */
    create_piece(&white_pieces, game^, "./assets/wk.png", {0, 4}, .WHITE, Piece_Key.KING)
    create_piece(&white_pieces, game^, "./assets/wq.png", {0, 3}, .WHITE, Piece_Key.QUEEN)
    game.board.pieces_map[.WHITE] = white_pieces

    /* Black */
    black_pieces: map[Piece_Key]Piece

    create_piece(&black_pieces, game^, "./assets/bk.png", {7, 4}, .BLACK, Piece_Key.KING)
    create_piece(&black_pieces, game^, "./assets/bq.png", {7, 3}, .BLACK, Piece_Key.QUEEN)
    game.board.pieces_map[.BLACK] = black_pieces
}

// note: Enemy king square is highlighted
// as valid move square, to detect if it is 
// under check, but do not allow it as an actual valid move
is_valid_move :: proc(game: ^Game, piece_to_move: ^Piece, move_to: Square) -> bool {
    for player, player_pieces in game.board.pieces_map {
        for piece_key, player_piece in player_pieces {
            if piece_key == .KING &&
               player_piece.position_on_board.x == move_to.row &&
               player_piece.position_on_board.y == move_to.col
            {
                return false
            }
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
    piece: ^Piece,
    ignore_king: bool = false,
    checking_opponents_moves: bool = false
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

        if !checking_opponents_moves {
            opponent_pieces := game.board.pieces_map[.WHITE]
            // get the opponent 
            if piece.player == .WHITE {
                opponent_pieces = game.board.pieces_map[.BLACK]
            }

            valid_opponent_moves: [dynamic]Square
            defer delete(valid_opponent_moves)

            for _, &opponent_piece in opponent_pieces {
                valid := valid_moves(game, &opponent_piece, true, true)
                append(&valid_opponent_moves, ..valid[:])
            }

            valid_king_moves: [dynamic]Square
            for move in moves {
                is_valid_move := true
                for op in valid_opponent_moves {
                    if op.row == move.row && op.col == move.col {
                        is_valid_move = false
                        break
                    }
                }
                if is_valid_move {
                    append(&valid_king_moves, move)
                }
            }

            return valid_king_moves
        }

        return moves
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

    if piece.type == .A_ROOK {
        add_valid_moves_east(game, piece, &moves, ignore_king)
        add_valid_moves_west(game, piece, &moves, ignore_king)
        add_valid_moves_north(game, piece, &moves, ignore_king)
        add_valid_moves_south(game, piece, &moves, ignore_king)
        return moves
    }

    if piece.type == .C_BISHOP {
        add_valid_moves_north_east(game, piece, &moves, ignore_king)
        add_valid_moves_north_west(game, piece, &moves, ignore_king)
        add_valid_moves_south_east(game, piece, &moves, ignore_king)
        add_valid_moves_south_west(game, piece, &moves, ignore_king)
        return moves
    }

    return moves
}

is_king_in_check :: proc(
    game_clone: ^Game,
    player_moving: Player,
    checking_opponents_moves: bool = false
) -> bool {
    opponent_pieces := game_clone.board.pieces_map[.WHITE]
    if player_moving == .WHITE {
        opponent_pieces = game_clone.board.pieces_map[.BLACK]
    }
    defer delete(opponent_pieces)

    white_king_pos := game_clone.board.pieces_map[.WHITE][.KING]
    defer free(&white_king_pos)

    black_king_pos := game_clone.board.pieces_map[.BLACK][.KING]
    defer free(&black_king_pos)

    for piece_key, &piece in opponent_pieces {
        valid_moves := valid_moves(game_clone, &piece, true, checking_opponents_moves)
        defer delete(valid_moves)

        for valid_move in valid_moves {
            if player_moving == .WHITE {

                if valid_move.row == white_king_pos.position_on_board.x &&
                   valid_move.col == white_king_pos.position_on_board.y
                {
                    return true
                }
            }

            if player_moving == .BLACK {
                if valid_move.row == black_king_pos.position_on_board.x &&
                   valid_move.col == black_king_pos.position_on_board.y
                {
                    return true
                }
            }
        }
    }

    return false
}

// @todo: check if piece is pinned to the KING
@(private = "file")
append_move :: proc(
    game: ^Game,
    piece: ^Piece,
    square_to_add: Square,
    dest: ^[dynamic]Square,
    ignore_king: bool = false,
) -> bool {
    has_piece, found_piece_key, player := square_has_piece(game.board, square_to_add)
    if has_piece {
        if piece.player != player {
            append(dest, square_to_add)
        }

        // look past the king to see if the row/col/diagonal is off limits for the king
        if found_piece_key == .KING && ignore_king && piece.player != player {
            return false
        }

        return true
    }

    append(dest, square_to_add)
    return false
}

@(private = "file")
square_has_piece :: proc(board: Board, square: Square) -> (
    has_piece: bool,
    found_piece: Piece_Key,
    player: Player
) {
    for player, value in board.pieces_map {
        for piece_key, value in board.pieces_map[player] {
            if value.position_on_board.x == square.row && value.position_on_board.y == square.col {
                return true, piece_key, player
            }
        }
    }

    return false, nil, nil
}

@(private = "file")
add_valid_moves_north :: proc(
    game: ^Game,
    piece: ^Piece,
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
    piece: ^Piece,
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
    piece: ^Piece,
    moves: ^[dynamic]Square,
    ignore_king: bool = false,
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
    piece: ^Piece,
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
    piece: ^Piece,
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
    piece: ^Piece,
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
    piece: ^Piece,
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
    piece: ^Piece,
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
    /*pieces_clone := slice.clone_to_dynamic(game.board.pieces[:]) or_return
    append(&game.board_history, pieces_clone) or_return*/
    return nil
}

