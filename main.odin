package main

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:slice"
import rl "vendor:raylib"

Player :: enum {
    WHITE,
    BLACK
}

Game :: struct {
    board: Board,
    board_history: [dynamic][dynamic]Piece
}

@(private = "file") hovered_square_vec: [2]int
@(private = "file") highlighted_squares: [dynamic]Square
@(private = "file") selected_piece: ^Piece
@(private = "file") move_sound: rl.Sound

// Buttons
@(private = "file") is_reset_pressed: bool
@(private = "file") is_next_move_pressed: bool
@(private = "file") is_prev_move_pressed: bool

@(private) current_move: int

// CONFIG
@(private = "file") SHOW_VALID_SQUARES := true 

main :: proc() {
    when ODIN_DEBUG {
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer {
            if len(track.allocation_map) > 0 {
                for _, entry in track.allocation_map {
                    fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
                }
            }
            if len(track.bad_free_array) > 0 {
                for entry in track.bad_free_array {
                    fmt.eprintf("%v bad free at %v\n", entry.location, entry.memory)
                }
            }
            mem.tracking_allocator_destroy(&track)
        }
    }

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
        board = board,
    }
    add_pieces(&game)

    board_pieces_clone := slice.clone_to_dynamic(game.board.pieces[:])
    defer delete(board_pieces_clone)
    append(&game.board_history, board_pieces_clone)

    for !rl.WindowShouldClose() {
        update_init(&game)

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
update_init :: proc(game: ^Game) {
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
    // and set/deselect the selected_piece
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
                        highlighted_squares = valid_moves(game, piece, nil)
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
                                current_move += 1
                            }

                            // hovered over a wrong square and could not make a move
                            // so snap back to where the move started
                            if !moved {
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
        current_move = 0

        clear(&game.board_history)
        reset_game(game)
    }

    // @todo: what to do when observing past moves and then making
    // a move while not in the latest state of the board
    //
    // #1 reset to latest state and do not allow the move
    if is_next_move_pressed {
        fmt.println("--------start-------")
        for state in game.board_history {
            for piece in state {
                fmt.println(piece.position_on_board, piece.type, piece.player)
            }
            fmt.println("---------------")
        }
        fmt.println("-------end--------")
        /*if current_move < len(move_history) - 1 {
            current_move += 1
        }

        fmt.println(current_move)
        fmt.println(len(move_history))
        game.board.pieces = move_history[current_move]*/
    }

    /*if is_prev_move_pressed {
        if current_move > 0 {
            current_move -= 1
        }
        fmt.println(current_move)
        fmt.println(move_history)
        game.board.pieces = move_history[current_move]
    }*/
}

@(private = "file")
draw_init :: proc(game: Game) {
    draw_board(game.board)
    draw_current_active_square_coordinates(game.board)

    is_reset_pressed = rl.GuiButton(rl.Rectangle{900, 10, 50, 20}, "Reset")
    is_prev_move_pressed = rl.GuiButton(rl.Rectangle{850, 50, 50, 20}, "Prev")
    is_next_move_pressed = rl.GuiButton(rl.Rectangle{910, 50, 50, 20}, "Next")

    /*
        The order we render pieces is important
        because if white pieces are rendered first
        then they always appear behing the black pieces when
        making a 'taking' move.

        So when current selected piece is black then we
        draw white pieces first, If white then black first.
        This also means that pieces can not be added to the list
        in a random order: first add all white then all black
        pieces. !IMPORTANT: do not mix and match them
    */
    if selected_piece != nil && selected_piece.player == Player.BLACK {
        for piece in game.board.pieces {
            draw_piece(piece)
        }
    } else {
        #reverse for piece in game.board.pieces {
            draw_piece(piece)
        }
    }
}

@(private = "file")
draw_piece :: proc(piece: Piece) {
    rl.DrawRectangleRec(piece.rect, rl.Fade(rl.WHITE, 0))
    rl.DrawTexture(
        piece.texture,
        i32(piece.rect.x),
        i32(piece.rect.y),
        rl.WHITE
    )
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

