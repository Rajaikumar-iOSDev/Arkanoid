const std = @import("std");
const ray = @import("raylib.zig");
// Global Variables Declaration
const screenWidth = 800;
const screenHeight = 450;

const screenWidthFloat: f32 = 800;
const screenHeightFloat: f32 = 450;

// Some Defines
const PLAYER_MAX_LIFE = 5;
const LINES_OF_BRICKS = 5;
const BRICKS_PER_LINE = 20;


const Player = struct {
    position: ray.Vector2,
    size: ray.Vector2,
    life: usize,
};

const Ball = struct {
    position: ray.Vector2,
    speed: ray.Vector2,
    radius: f32,
    active: bool,
};

const Brick = struct {
    position: ray.Vector2,
    active: bool,
};



var gameOver = false;
var pause = false;

var player: Player = .{ .position = .{ .x = 0, .y = 0 }, .size = .{ .x = 0, .y = 0 }, .life = 0 };
var ball: Ball = .{ .position = .{ .x = 0, .y = 0 }, .speed = .{ .x = 0, .y = 0 }, .radius = 0, .active = false };
var brick: [LINES_OF_BRICKS][BRICKS_PER_LINE]Brick = undefined;
var brickSize: ray.Vector2 = .{ .x = 0, .y = 0 };

// Main entry point

pub fn main() !void {
    try InitRayWindow();
    defer ray.CloseWindow();
    try InitGame();
    while (!ray.WindowShouldClose()) {
   UpdateDrawFrame();
     }
}
// Module Functions Definitions (local)

// Initialize game variables
fn InitGame() !void  {
    brickSize = ray.Vector2{ .x = @as(f32, screenWidth) / @as(f32, BRICKS_PER_LINE), .y = 40 };

    // Initialize player
    player.position = ray.Vector2{ .x = @as(f32, screenWidth) / 2, .y = @as(f32, screenHeight) * 7 / 8 };
    player.size = ray.Vector2{ .x = @as(f32, screenWidth) / 10, .y = 20 };
    player.life = PLAYER_MAX_LIFE;

    // Initialize ball
    ball.position = ray.Vector2{ .x = @as(f32, screenWidth) / 2, .y = @as(f32, screenHeight) * 7 / 8 - 30 };
    ball.speed = ray.Vector2{ .x = 0, .y = 0 };
    ball.radius = 7;
    ball.active = false;

    // Initialize bricks
    const initialDownPosition = 50;


    for (0..LINES_OF_BRICKS) |i| {
         for (0..BRICKS_PER_LINE) |j| {
            brick[i][j].position = ray.Vector2{ .x = @as(f32, @floatFromInt(j)) * brickSize.x + brickSize.x / 2, .y = @as(f32, @floatFromInt(i))   * brickSize.y + initialDownPosition };
            brick[i][j].active = true;
    }
  }

}
// Update game (one frame)
pub fn UpdateGame() void {
    if (!gameOver) {
        if (ray.IsKeyPressed('P')) pause = !pause;

        if (!pause) {
            if (ray.IsKeyDown(ray.KEY_LEFT)) player.position.x -= 5;
            if ((player.position.x - player.size.x/2) <= 0) player.position.x = player.size.x/2;
            if (ray.IsKeyDown(ray.KEY_RIGHT)) player.position.x += 5;
            if ((player.position.x + player.size.x/2) >= screenWidth) player.position.x = screenWidth - player.size.x/2;

            if (!ball.active) {
                if (ray.IsKeyPressed(ray.KEY_SPACE)) {
                    ball.active = true;
                    ball.speed = ray.Vector2 { .x = 0, .y = -5 };
                }
            }

            if (ball.active) {
                ball.position.x += ball.speed.x;
                ball.position.y += ball.speed.y;
            } else {
                ball.position = ray.Vector2 { .x = player.position.x, .y = screenHeight*7/8 - 30 };
            }

            if (((ball.position.x + ball.radius) >= screenWidthFloat) or ((ball.position.x - ball.radius) <= 0)) ball.speed.x *= -1;
            if ((ball.position.y - ball.radius) <= 0) ball.speed.y *= -1;
            if ((ball.position.y + ball.radius) >= screenHeightFloat) {
                ball.speed = ray.Vector2 { .x = 0, .y = 0 };
                ball.active = false;

                player.life -= 1;
            }

            if (ray.CheckCollisionCircleRec(ball.position, ball.radius, ray.Rectangle { .x = player.position.x - player.size.x/2, .y = player.position.y - player.size.y/2, .width = player.size.x, .height = player.size.y })) {
                if (ball.speed.y > 0) {
                    ball.speed.y *= -1;
                    ball.speed.x = (ball.position.x - player.position.x)/(player.size.x/2)*5;
                }
            }

            for (0..LINES_OF_BRICKS) |i|  {
            for (0..BRICKS_PER_LINE) |j| {
                    if (brick[i][j].active) {
                        if (((ball.position.y - ball.radius) <= (brick[i][j].position.y + brickSize.y/2)) and
                            ((ball.position.y - ball.radius) > (brick[i][j].position.y + brickSize.y/2 + ball.speed.y)) and
                            ((ray.fabs(ball.position.x - brick[i][j].position.x)) < (brickSize.x/2 + ball.radius*2/3)) and (ball.speed.y < 0)) {
                            brick[i][j].active = false;
                            ball.speed.y *= -1;
                        } else if (((ball.position.y + ball.radius) >= (brick[i][j].position.y - brickSize.y/2)) and
                                ((ball.position.y + ball.radius) < (brick[i][j].position.y - brickSize.y/2 + ball.speed.y)) and
                                ((ray.fabs(ball.position.x - brick[i][j].position.x)) < (brickSize.x/2 + ball.radius*2/3)) and (ball.speed.y > 0)) {
                            brick[i][j].active = false;
                            ball.speed.y *= -1;
                        } else if (((ball.position.x + ball.radius) >= (brick[i][j].position.x - brickSize.x/2)) and
                                ((ball.position.x + ball.radius) < (brick[i][j].position.x - brickSize.x/2 + ball.speed.x)) and
                                ((ray.fabs(ball.position.y - brick[i][j].position.y)) < (brickSize.y/2 + ball.radius*2/3)) and (ball.speed.x > 0)) {
                            brick[i][j].active = false;
                            ball.speed.x *= -1;
                        } else if (((ball.position.x - ball.radius) <= (brick[i][j].position.x + brickSize.x/2)) and
                                ((ball.position.x - ball.radius) > (brick[i][j].position.x + brickSize.x/2 + ball.speed.x)) and
                                ((ray.fabs(ball.position.y - brick[i][j].position.y)) < (brickSize.y/2 + ball.radius*2/3)) and (ball.speed.x < 0)) {
                            brick[i][j].active = false;
                            ball.speed.x *= -1;
                        }
                    }
                }
            }

            if (player.life <= 0){ gameOver = true;}
            else {
                gameOver = true;

                for (0..LINES_OF_BRICKS) |i|  {
            for (0..BRICKS_PER_LINE) |j| {
                        if (brick[i][j].active) gameOver = false;
                    }
                }
            }
        }
    } else {
        if (ray.IsKeyPressed(ray.KEY_ENTER)) {
            InitGame() catch |err| {
    // Handle error, e.g., log it or clean up resources
    std.debug.print("Failed to initialize game: {}\n", .{err});
};
            gameOver = false;
        }
    }
}
// Draw game (one frame)
pub fn DrawGame() void {
    ray.BeginDrawing();

    defer ray.EndDrawing();

    ray.ClearBackground(ray.RAYWHITE);

    if (!gameOver) {
        // Draw player bar
        ray.DrawRectangle(
            @intFromFloat(player.position.x - player.size.x / 2),
            @intFromFloat(player.position.y - player.size.y / 2),
            @intFromFloat(player.size.x),
            @intFromFloat(player.size.y),
            ray.BLACK
        );

        // Draw player lives
        for (0..player.life) |i| {
            ray.DrawRectangle(@intCast( 20 + 40 * i), @intCast(screenHeight - 30), @intCast(35), @intCast(10), ray.LIGHTGRAY);
        }

        // Draw ball
        ray.DrawCircleV(ball.position, ball.radius, ray.MAROON);

        // Draw bricks
        for (0..LINES_OF_BRICKS) |i|  {
            for (0..BRICKS_PER_LINE) |j| {
                if (brick[i][j].active) {
                    if ((i + j) % 2 == 0) {
                        ray.DrawRectangle(
                            @intFromFloat(brick[i][j].position.x - brickSize.x / 2),
                            @intFromFloat(brick[i][j].position.y - brickSize.y / 2),
                            @intFromFloat(brickSize.x),
                            @intFromFloat(brickSize.y),
                            ray.GRAY
                        );
                    } else {
                        ray.DrawRectangle(
                            @intFromFloat(brick[i][j].position.x - brickSize.x / 2),
                            @intFromFloat(brick[i][j].position.y - brickSize.y / 2),
                            @intFromFloat(brickSize.x),
                            @intFromFloat(brickSize.y),
                            ray.DARKGRAY
                        );
                    }
                }
            }
        }

        if (pause) {
            const text = "GAME PAUSED";
            ray.DrawText(
    text,
    @divTrunc(screenWidth, 2) - @divTrunc(ray.MeasureText(text, 40), 2),
    screenHeight / 1.5,
    40,
    ray.DARKGREEN
);
        }
    } else {
        const text = "PRESS [ENTER] TO PLAY AGAIN";
        
        ray.DrawText(
    text,
    @divTrunc(screenWidth, 2) - @divTrunc(ray.MeasureText(text, 20), 2),
    screenHeight / 2 - 50,
    20,
    ray.GRAY
);
    }
}
// Update and Draw (one frame)

fn UpdateDrawFrame() void {
    UpdateGame();
    DrawGame();
}

fn InitRayWindow() !void {
        ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT | ray.FLAG_VSYNC_HINT);
        ray.SetTargetFPS(60);
        ray.InitWindow(screenWidth, screenHeight, "Arkanoid!");
    }


