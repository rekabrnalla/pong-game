# Pong Game

This is a tiny Godot 4 project for learning how Pong works.

## How To Open It

1. Open Godot.
2. Click **Import**.
3. Choose this folder:
   `C:\Users\baker\OneDrive\Documents\Pong Game`
4. Open the project.
5. Press the play button in the top-right corner, or press **F5**.

## Controls

- Left paddle: **W** and **S**
- Right paddle: **Up Arrow** and **Down Arrow**
- Mobile left paddle: drag on the left half of the screen
- Mobile right paddle: drag on the right half of the screen
- Left sprint: double-tap **W** or **S**
- Right sprint: double-tap **Up Arrow** or **Down Arrow**
- Mobile sprint: double-tap your side of the screen
- Restart: **R**

## What The Code Is Doing

Think of the game as three toys on a table:

- The left paddle is a rectangle.
- The right paddle is a rectangle.
- The ball is a little circle that can spin.
- It has an outline and tennis-ball lines so it is easy to see while moving.

Every frame, Godot asks: "What changed since the last frame?"

The script answers:

1. Did a player press a key? Move that paddle.
2. Move the ball in the direction it is already going.
3. Did the ball hit the top or bottom wall? Bounce it.
4. Did the ball hit a paddle? Bounce it back.
5. Did the ball go past a paddle? Give the other player a point.

## How To Share With Friends

The project folder is the editable version. Friends need an exported version if they do not have Godot.

Good sharing choices:

- **Windows export:** makes an `.exe` your Windows friends can run.
- **Web export:** makes an HTML version you can upload to a website or a game site.

In Godot:

1. Click **Project**.
2. Click **Export**.
3. Add a preset like **Windows Desktop** or **Web**.
4. Godot may ask you to download export templates. Let it do that.
5. Click **Export Project**.

For learning together, the easiest path is sharing the whole project folder with another person who has Godot installed.

## New Tennis Racket Feeling

The paddles now act a little like tennis rackets.

If your paddle is standing still, the ball bounces back normally.
If your paddle is moving when it hits the ball, the paddle gives the ball extra power.

That means:

- A moving paddle makes the ball speed up more.
- Hitting the ball while moving up pushes the ball upward.
- Hitting the ball while moving down pushes the ball downward.

The code remembers each paddle's speed with:

- `left_paddle_velocity`
- `right_paddle_velocity`

Then `bounce_from_paddle()` uses that speed to change the ball.

## Sprint

Each player can sprint for 2 seconds.

- Left player: double-tap **W** or **S**
- Right player: double-tap **Up Arrow** or **Down Arrow**
- Mobile: double-tap your half of the screen

After sprinting, that player has to wait 5 seconds before sprinting again.

The code uses:

- `DOUBLE_TAP_WINDOW`
- `SPRINT_MULTIPLIER`
- `SPRINT_SECONDS`
- `SPRINT_COOLDOWN_SECONDS`

## Motion Blur

The ball now leaves a short fading trail behind it.

The code saves a few old ball positions in `ball_trail`, then draws smaller, see-through circles there. This makes the ball look faster without changing the physics.

The code uses:

- `MOTION_BLUR_POINTS`
- `MOTION_BLUR_ALPHA`

## Mobile Touch Controls

The same web game can work on a phone or tablet.

- Drag on the left half of the screen to move the left paddle.
- Drag on the right half of the screen to move the right paddle.
- Double-tap your half of the screen to sprint.

The keyboard controls still work on computer.

## Spin

The ball now has spin, kind of like a tennis ball.

If you hit the ball while your paddle is moving, the paddle brushes the side of the ball and adds spin.

Spin does three things:

- The ball graphic rotates so you can see it spinning.
- The ball curves a little while flying.
- Wall and paddle bounces are changed a little by the spin.

The important spin variables are:

- `ball_spin`: how fast the ball is spinning.
- `ball_rotation`: how the ball looks on screen.
- `SPIN_CURVE_FORCE`: how much spin bends the flight path.
- `MAX_SPIN`: how much spin is allowed.

## Round Ball Bounces

The ball is drawn as a circle, and the code now checks collisions like a circle too.

That means the ball behaves differently depending on where it hits the paddle:

- Center hits are straighter and easier to predict.
- Edge hits kick the ball at sharper angles.
- A tiny bit of bounce wobble keeps the game from feeling robotic.

The wobble is small on purpose. It makes the game exciting, but players can still learn and aim.

Look for:

- `circle_hits_rect()`
- `ROUND_BALL_EDGE_LIFT`
- `CONTROLLED_BOUNCE_WOBBLE`

## Sounds

The sounds are made by code, not by sound files.

The game creates tiny beep sounds for:

- Paddle hit
- Wall hit
- Score
- Win

Look for `create_sound_players()` and `make_tone()` in `scripts/main.gd`.

## Good Things To Try Changing

- In `scripts/main.gd`, change `PADDLE_SPEED` to make paddles faster or slower.
- Change `START_BALL_SPEED` to make the game easier or harder.
- Change `MAX_BALL_SPEED` to choose how fast the ball is allowed to get.
- Change `RACKET_POWER` to make moving paddles hit softer or harder.
- Change `SPRINT_MULTIPLIER` to make sprint faster or slower.
- Change `SPRINT_SECONDS` to change how long sprint lasts.
- Change `SPRINT_COOLDOWN_SECONDS` to change how long players must wait.
- Change `MOTION_BLUR_POINTS` to make the ball trail longer or shorter.
- Change `MOTION_BLUR_ALPHA` to make the trail stronger or lighter.
- Change `SPIN_CURVE_FORCE` to make spin curve the ball more or less.
- Change `MAX_SPIN` to make the ball spin faster or slower.
- Change `CONTROLLED_BOUNCE_WOBBLE` to make bounces more or less surprising.
- Change `WINNING_SCORE` to decide how many points wins the game.
- Change the colors in `create_game_objects()`.
