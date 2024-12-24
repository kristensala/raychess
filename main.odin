package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"


Turn :: enum {
    WHITE,
    BLACK
}

Game :: struct {
    board: Board,
    turn: Turn
}

@(private = "file")
hovered_square_vec: [2]int

main :: proc() {
    rl.InitWindow(1000, 800, "RayChess")
    rl.SetWindowMonitor(1)

    board := Board {
        position = {0, 700},
    }
    create_squares(&board)
    // @todo: add piece

    game := Game {
        turn = Turn.WHITE,
        board = board
    }
    add_pieces(&game)

    for !rl.WindowShouldClose() {
        update(&game)

        rl.BeginDrawing()
        rl.ClearBackground(rl.RAYWHITE)

        draw(&board)

        // note: draw a piece test
        rl.DrawRectangleRec(game.board.pieces[0].rect, rl.Fade(rl.WHITE, 0))
        rl.DrawTexture(
            game.board.pieces[0].texture,
            i32(game.board.pieces[0].rect.x),
            i32(game.board.pieces[0].rect.y),
            rl.WHITE
        )

        rl.EndDrawing()
    }

    for piece in game.board.pieces {
        rl.UnloadTexture(piece.texture)
    }

    rl.CloseWindow()
}

@(private = "file")
update :: proc(game: ^Game) {
    mouse_pos := rl.GetMousePosition()

    // Check which square the mouse is hovering
    for row, row_idx in game.board.squares {
        for square, square_idx in row {
            is_collision := rl.CheckCollisionPointRec(mouse_pos, square.rect)
            if is_collision {
                hovered_square_vec = {row_idx, square_idx}
            }
        }
    }

    // @todo: drag and drop a chess piece
    // while mouse down, center the piece so
    // that the mouse would be in the center of the piece automagically
    test_piece := &game.board.pieces[0]
    if rl.CheckCollisionPointRec(mouse_pos, test_piece.rect) {
        if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
            test_piece.rect.x = mouse_pos.x - (SQUARE_SIZE / 2)
            test_piece.rect.y = mouse_pos.y - (SQUARE_SIZE / 2)

        }

        // note: snap the piece into the hovered square
        if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
            hovered_square := game.board.squares[hovered_square_vec.x][hovered_square_vec.y]
            fmt.println("released: ", hovered_square)
            test_piece.rect.x = hovered_square.rect.x
            test_piece.rect.y = hovered_square.rect.y
        }
    }
}

@(private = "file")
draw :: proc(board: ^Board) {
    draw_board(board)
    draw_current_active_square_coordinates(board)

}

@(private = "file")
draw_board :: proc(board: ^Board) {
    for row, row_idx in board.squares {
        for square, square_idx in row {
            rl.DrawRectangleRec(square.rect, square.color)

            if hovered_square_vec.x == row_idx && hovered_square_vec.y == square_idx {
                rl.DrawRectangleRec(square.rect, rl.GREEN)
            }
        }
    }
}

@(private = "file")
draw_current_active_square_coordinates :: proc(board: ^Board) {
    coord := board.squares[hovered_square_vec.x][hovered_square_vec.y].coordinate
    coordinate_string := fmt.aprintf("{0}{1}", coord.column, coord.row_nr + 1)
    defer delete(coordinate_string)

    coord_cstring := strings.clone_to_cstring(coordinate_string)
    defer delete(coord_cstring)

    rl.DrawText(coord_cstring, 0 ,0 , 20, rl.BLACK)
}

@(private = "file")
draw_pieces :: proc(board: ^Board) {
}

