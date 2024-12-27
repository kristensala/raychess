package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"


Player :: enum {
    WHITE,
    BLACK
}

Game :: struct {
    board: Board,
}

@(private = "file")
hovered_square_vec: [2]int

@(private = "file")
highlighted_squares: [dynamic]Square

main :: proc() {
    rl.InitWindow(1000, 800, "RayChess")
    rl.SetWindowMonitor(1)

    board := Board {
        position = {0, 700},
    }
    create_squares(&board)

    game := Game {
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
    test_piece := &game.board.pieces[0]

    // Check which square the mouse is hovering
    for row, row_idx in game.board.squares {
        for square, square_idx in row {
            is_collision := rl.CheckCollisionPointRec(mouse_pos, square.rect)
            if is_collision {
                hovered_square_vec = {row_idx, square_idx}
            }

            if rl.CheckCollisionPointRec(mouse_pos, square.rect) && test_piece.is_active && !rl.CheckCollisionPointRec(mouse_pos, test_piece.rect) {
                if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
                    square_to_move_to := game.board.squares[row_idx][square_idx]
                    // @todo: get valid moves based on the Piece
                    move_piece(game, test_piece, &square_to_move_to)
                }
            }
        }
    }

    if rl.CheckCollisionPointRec(mouse_pos, test_piece.rect) {
        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            if test_piece.is_active {
                test_piece.is_active = false
                clear(&highlighted_squares)
            } else {
                test_piece.is_active = true
                highlighted_squares = valid_moves(game, test_piece)
            }

            /* note(kristen): drag and drop logic */
            /*test_piece.rect.x = mouse_pos.x - (SQUARE_SIZE / 2)
            test_piece.rect.y = mouse_pos.y - (SQUARE_SIZE / 2)*/
        }

        // note: snap the piece into the hovered square
        /*if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
            hovered_square := game.board.squares[hovered_square_vec.x][hovered_square_vec.y]
            test_piece.rect.x = hovered_square.rect.x
            test_piece.rect.y = hovered_square.rect.y
        }*/
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
                rl.DrawRectangleRec(square.rect, rl.Fade(rl.GRAY, .5))
            }

            // show valid moves
            for highlighted_square in highlighted_squares {
                if highlighted_square.row == square.row && highlighted_square.col == square.col {
                    rl.DrawRectangleRec(square.rect, rl.Fade(rl.ORANGE, .5))
                }

            }
        }
    }
}

@(private = "file")
draw_current_active_square_coordinates :: proc(board: ^Board) {
    rows := ROWS
    columns := COLUMNS

    coord := board.squares[hovered_square_vec.x][hovered_square_vec.y]
    coordinate_string := fmt.aprintf("{0}{1} (idx: {2}{3})", 
        rows[coord.row],
        columns[coord.col],
        coord.row,
        coord.col
    )
    defer delete(coordinate_string)

    coord_cstring := strings.clone_to_cstring(coordinate_string)
    defer delete(coord_cstring)

    rl.DrawText(coord_cstring, 0 ,0 , 20, rl.BLACK)
}

@(private = "file")
draw_pieces :: proc(board: ^Board) {
}

