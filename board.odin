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
    coordinate: Coordinate,
    color: rl.Color,
    rect: rl.Rectangle
}

Coordinate :: struct {
    row_nr: int,
    column: string
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
    name: string,
    player: Player,
    rect: rl.Rectangle,
    texture: rl.Texture2D,
    type: Piece_type,
    is_active: bool
}

COLUMNS :: [8]string{"a", "b", "c", "d", "e", "f", "g", "h"}
SQUARE_SIZE :: 100

@(private)
create_squares :: proc(board: ^Board) {
    square_start_x := board.position.x
    square_start_y := board.position.y
    square_color: rl.Color

    for row in 0..=7 {
        row_array: [dynamic]Square

        for column, index in COLUMNS {
            if row % 2 == 0 {
                if index % 2 == 0 {
                    square_color = rl.BROWN
                } else {
                    square_color = rl.BEIGE
                }
            } else {
                if index % 2 != 0 {
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
                coordinate = Coordinate{
                    row_nr = row,
                    column = column
                },
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

add_pieces :: proc(game: ^Game) {
    /* WHITE QUEEN */
    wq_texture := rl.LoadTexture("./assets/wq.png")
    wq_texture.height = SQUARE_SIZE
    wq_texture.width = SQUARE_SIZE

    wq_rect := rl.Rectangle{
        x = game.board.squares[0][1].rect.x,
        y = game.board.squares[0][1].rect.y,
        height = SQUARE_SIZE,
        width = SQUARE_SIZE
    }

    wq_piece := Piece{
        texture = wq_texture,
        player = Player.WHITE,
        type = Piece_type.QUEEN,
        rect = wq_rect,
        is_active = false
    }
    append(&game.board.pieces, wq_piece)

    /* WHITE ROOK 1 */

    /* WHITE ROOK 2 */

}

valid_moves :: proc(game: ^Game, piece: ^Piece) -> [dynamic]Square {
    test := game.board.squares[0]
    return test
}



