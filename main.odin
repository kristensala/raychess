package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

Player :: enum {
    WHITE,
    BLACK
}

Game_Mode :: enum {
    FREE
}

Game :: struct {
    board: Board,
    mode: Game_Mode
}

@(private = "file") hovered_square_vec: [2]int
@(private = "file") highlighted_squares: [dynamic]Square
@(private = "file") is_reset_pressed: bool
@(private = "file") selected_piece: ^Piece
@(private = "file") move_sound: rl.Sound

@(private = "file") SHOW_VALID_SQUARES := true 

main :: proc() {
    rl.InitWindow(1000, 800, "RayChess")
    rl.SetWindowMonitor(1)

    rl.InitAudioDevice()
    move_sound = rl.LoadSound("./assets/move-self.mp3")
    rl.SetTargetFPS(60)

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

        draw_init(game)

        rl.EndDrawing()
    }

    for piece in game.board.pieces {
        rl.UnloadTexture(piece.texture)
    }

    rl.UnloadSound(move_sound)
    rl.CloseWindow()
}

@(private = "file")
update :: proc(game: ^Game) {
    mouse_pos := rl.GetMousePosition()
    pieces_on_board := &game.board.pieces

    if (mouse_pos.x >= 810 ||
        mouse_pos.y < 0 ||
        mouse_pos.y >= 810 ||
        mouse_pos.x < 0) && selected_piece != nil
    {
        starting_pos := selected_piece.position_on_board
        starting_square := game.board.squares[starting_pos.x][starting_pos.y]
        selected_piece.rect = starting_square.rect
        selected_piece = nil

        if SHOW_VALID_SQUARES {
            clear(&highlighted_squares)
        }
    }

    // highlight valid squares for the selected piece
    for &piece in pieces_on_board {
        if rl.CheckCollisionPointRec(mouse_pos, piece.rect) {
            if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
                if selected_piece != nil && piece.number == selected_piece.number {
                    selected_piece = nil
                    if SHOW_VALID_SQUARES {
                        clear(&highlighted_squares)
                    }
                } else {
                    selected_piece = &piece
                    if SHOW_VALID_SQUARES {
                        highlighted_squares = valid_moves(game, piece)
                    }
                }
            }
        }
    }

    // Check which square the mouse is hovering
    for row, row_idx in game.board.squares {
        for square, square_idx in row {
            is_collision := rl.CheckCollisionPointRec(mouse_pos, square.rect)
            if is_collision {
                hovered_square_vec = {row_idx, square_idx}
            }

            if selected_piece != nil {
                for &piece in pieces_on_board {
                    if rl.CheckCollisionPointRec(mouse_pos, square.rect) && selected_piece == &piece {
                        if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
                            piece.rect.x = mouse_pos.x - 50
                            piece.rect.y = mouse_pos.y - 50
                        }
                        if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
                            square_to_move_to := game.board.squares[hovered_square_vec.x][hovered_square_vec.y]
                            moved := move_piece(game, &piece, square_to_move_to)
                            if moved {
                                rl.PlaySound(move_sound)
                            }

                            if !moved {
                                // snap back
                                starting_pos := piece.position_on_board
                                starting_square := game.board.squares[starting_pos.x][starting_pos.y]
                                piece.rect = starting_square.rect
                            }
                            selected_piece = nil

                            if SHOW_VALID_SQUARES {
                                clear(&highlighted_squares)
                            }
                        }
                    }
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
draw_init :: proc(game: Game) {
    draw_board(game.board)
    draw_current_active_square_coordinates(game.board)

    is_reset_pressed = rl.GuiButton(rl.Rectangle{900, 10, 50, 20}, "Reset")

    /*
        The order we render pieces is important
        because if white pieces are rendered first
        then they always appear behing the black pieces when
        making a 'taking' move.

        So when current selected piece is black then we
        draw white pieces first, If white then black
        This also means that pieces can not be added to the list
        in a random order: first add all white then all black
        pieces. !IMPORTANT: do not mix and match them
    */
    if selected_piece != nil && selected_piece.player == Player.BLACK {
        for piece in game.board.pieces {
            rl.DrawRectangleRec(piece.rect, rl.Fade(rl.WHITE, 0))
            rl.DrawTexture(
                piece.texture,
                i32(piece.rect.x),
                i32(piece.rect.y),
                rl.WHITE
            )
        }
    } else {
        #reverse for piece in game.board.pieces {
            rl.DrawRectangleRec(piece.rect, rl.Fade(rl.WHITE, 0))
            rl.DrawTexture(
                piece.texture,
                i32(piece.rect.x),
                i32(piece.rect.y),
                rl.WHITE
            )
        }
    }
}

@(private = "file")
draw_board :: proc(board: Board) {
    for row, row_idx in board.squares {
        for square, square_idx in row {
            // @todo: draw coordinates on the board
            rl.DrawRectangleRec(square.rect, square.color)

            if hovered_square_vec.x == row_idx && hovered_square_vec.y == square_idx {
                rl.DrawRectangleRec(square.rect, rl.Fade(rl.PURPLE, .5))
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
draw_current_active_square_coordinates :: proc(board: Board) {
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

// @todo: remove later
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

