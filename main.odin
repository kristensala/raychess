package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

Player :: enum {
    WHITE,
    BLACK
}

Game_mode :: enum {
    FREE
}

Game :: struct {
    board: Board,
    mode: Game_mode
}

@(private = "file") hovered_square_vec: [2]int
@(private = "file") highlighted_squares: [dynamic]Square
@(private = "file") is_reset_pressed: bool
@(private = "file") selected_piece: ^Piece

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

        for p in game.board.pieces {
            rl.DrawRectangleRec(p.rect, rl.Fade(rl.WHITE, 0))
            rl.DrawTexture(
                p.texture,
                i32(p.rect.x),
                i32(p.rect.y),
                rl.WHITE
            )
        }

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
    pieces_on_board := &game.board.pieces

    // Check which square the mouse is hovering
    for row, row_idx in game.board.squares {
        for square, square_idx in row {
            is_collision := rl.CheckCollisionPointRec(mouse_pos, square.rect)
            if is_collision {
                hovered_square_vec = {row_idx, square_idx}
            }

            if selected_piece != nil {
                for &piece in pieces_on_board {
                    if rl.CheckCollisionPointRec(mouse_pos, piece.rect) && selected_piece == &piece {
                        if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
                            piece.rect.x = mouse_pos.x - (SQUARE_SIZE / 2)
                            piece.rect.y = mouse_pos.y - (SQUARE_SIZE / 2)
                        }
                        if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
                            square_to_move_to := game.board.squares[hovered_square_vec.x][hovered_square_vec.y]
                            moved := move_piece(game, &piece, &square_to_move_to)
                            if !moved {
                                // snap back
                                starting_pos := piece.position_on_board
                                starting_square := game.board.squares[starting_pos.x][starting_pos.y]
                                piece.rect = starting_square.rect
                            }
                            selected_piece = nil
                        }
                    }
                }
            }
        }
    }

    // highlight valid squares for the selected piece
    for &piece in pieces_on_board {
        if rl.CheckCollisionPointRec(mouse_pos, piece.rect) {
            if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
                if selected_piece != nil && piece.number == selected_piece.number {
                    selected_piece = nil
                    //clear(&highlighted_squares)
                } else {
                    selected_piece = &piece
                    //highlighted_squares = valid_moves(game, &piece)
                }
            }
        }
    }

    if is_reset_pressed {
        selected_piece = nil
        reset_game(game)
    }
}

@(private = "file")
draw :: proc(board: ^Board) {
    draw_board(board)
    draw_current_active_square_coordinates(board)

    is_reset_pressed = rl.GuiButton(rl.Rectangle{900, 10, 50, 20}, "Reset")
}

@(private = "file")
draw_board :: proc(board: ^Board) {
    for row, row_idx in board.squares {
        for square, square_idx in row {
            rl.DrawRectangleRec(square.rect, square.color)

            if hovered_square_vec.x == row_idx && hovered_square_vec.y == square_idx {
                rl.DrawRectangleRec(square.rect, rl.Fade(rl.GRAY, .5))
            }

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

click_and_move :: proc() {
    // @todo: drag the piece
    // click and move the piece
    /*for &piece in pieces_on_board {
                    if rl.CheckCollisionPointRec(mouse_pos, square.rect) && 
                       piece.number == selected_piece.number && 
                       !rl.CheckCollisionPointRec(mouse_pos, piece.rect)
                    {
                        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
                            square_to_move_to := game.board.squares[row_idx][square_idx]
                            move_piece(game, &piece, &square_to_move_to)
                        }
                    }
                }*/

}

