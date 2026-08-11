# Spin Pong

This is a tiny Godot 4 project for learning how Pong works.

## Play Online

Play Spin Pong on itch.io:

[https://rekabrnalla.itch.io/spin-pong](https://rekabrnalla.itch.io/spin-pong)

Itch.io embed code for pages that support iframes:

```html
<iframe frameborder="0" src="https://itch.io/embed/4786597?linkback=true" width="552" height="167"><a href="https://rekabrnalla.itch.io/spin-pong">Spin Pong by rekabrnalla</a></iframe>
```

Note: GitHub README files do not render iframe embeds, so the playable link above is the GitHub-friendly version.

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
- Mobile left paddle: drag, tap, or double-tap on the left half of the screen
- Mobile right paddle: drag, tap, or double-tap on the right half of the screen
- Mobile slam: tap two fingers together on your half of the screen
- Left sprint: double-tap **W** or **S**
- Right sprint: double-tap **Up Arrow** or **Down Arrow**
- Left slam or held-ball serve: press **W** and **S** together
- Right slam or held-ball serve: press **Up Arrow** and **Down Arrow** together
- Restart: **R**, or click/tap the score after the game ends

## What The Code Is Doing

Think of the game as several toys on a table:

- The left and right paddles are rounded capsules.
- Each ball is a little circle with rotating markings that show spin.
- A robot octopus occasionally flies across the court.
- The score and timers belong to the whole match.
- Speed, spin, and motion trails belong to each individual ball.

Every frame, Godot asks: "What changed since the last frame?"

The script answers:

1. Did a player press a key? Move that paddle.
2. Is one ball playing? Count down toward the next alien visit.
3. Move every active ball in the direction it is already going.
4. Did a ball hit a wall, paddle, or alien? Handle that collision.
5. Did a ball go past a paddle? Score and remove only that ball.
6. Are no balls left? Start the next rally.

## Code Map

- `scripts/main.gd`: match rules, controls, physics, scoring, alien timing, and sounds.
- `scripts/ball_state_data.gd`: the values owned by one ball.
- `scripts/spinning_ball.gd`: procedural ball drawing.
- `scripts/robot_octopus.gd`: procedural alien drawing and tentacle animation.
- `scripts/startup_splash.gd`: animated opening title, robot, and incoming ball.

The scripts include section headings and teaching comments. Start with `_process()` in `main.gd` to see the order of one game frame.

## Opening Splash

Spin Pong begins with a short animated title screen. It reuses the game's
procedural robot octopus and spinning ball, then automatically starts the match
after five seconds. The scene moves in slow motion: the ball reaches only the
halfway point while its long yellow trail suggests the speed of the full-power
shot. A click, tap, key, or controller button can continue early.

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
- Mobile: double-tap your side of the screen

After sprinting, that player has to wait 5 seconds before sprinting again.

The code uses:

- `DOUBLE_TAP_WINDOW`
- `SPRINT_MULTIPLIER`
- `SPRINT_SECONDS`
- `SPRINT_COOLDOWN_SECONDS`

## Slam And Held-Ball Serve

Press both of your movement keys together during normal play to slam.
The paddle lunges inward, gives the ball a stronger hit, plays a deep boom, and shudders as it returns.

If the ball loses its sideways motion, it begins to dribble against the bottom wall. It eventually changes to small hops back toward the player who last hit it. The ball keeps gently hopping near that player until their paddle collects it, so they can choose where the ball touches the paddle.

After the ball sticks to the paddle:

- Left player: press **W** and **S** together to serve.
- Right player: press **Up Arrow** and **Down Arrow** together to serve.
- Mobile player: tap the side holding the ball to serve.

Move the paddle as you press the second serve key to aim the ball and add spin. A faster release motion creates a steeper, faster serve with more spin.

## Motion Blur

The ball now leaves a short fading trail behind it.

Each ball saves a few old positions in its own `trail`, then the main game draws smaller, see-through circles there. Separate trails prevent two balls from being connected by one incorrect streak.

The code uses:

- `MOTION_BLUR_POINTS`
- `MOTION_BLUR_ALPHA`

## Mobile Touch Controls

The same web game can work on a phone or tablet.

- Drag on the left half of the screen to move the left paddle.
- Drag on the right half of the screen to move the right paddle.
- Tap your side of the screen to send your paddle toward that spot at normal speed.
- Double-tap your side to sprint toward that spot.
- Tap two fingers together on your side to slam.

The keyboard controls still work on computer.

## Restarting

The first player to reach 7 points wins.

When the game is over, a pop-up says to click or tap the score to restart.
If someone clicks the score during the game, the game asks "Are you sure?" first so an accidental tap does not reset the match.
On mobile, only the small area immediately around the visible score numbers responds as the restart target. The surrounding top-center court remains available for paddle movement.

## Robot Octopus And Multiball

When exactly one ball is playing, a random countdown moves toward zero. When it reaches zero, a robot octopus enters at a slower speed and bounces around the middle third of the court for about 20 seconds. Keeping its entire collision circle in the center third prevents unfair surprise hits close to either paddle. The timer pauses during recovery and multiball.

A gold fuse above the score shows that hidden countdown. It begins as a full line, then burns inward from both ends. When the two bright ends meet in the center, the alien appears. A dim fuse means the countdown is paused. Scoring does not restart the fuse, so several short rallies cannot postpone the alien forever.

When the ball gets close, the alien turns very slightly toward a point ahead of the moving ball. Its turn rate is deliberately small, so it can drift into the ball's path without acting like a heat-seeking missile. After 20 seconds, the alien takes the nearer top or bottom exit, flying vertically so it never enters a paddle zone. Its departure never scores a point, resets the round, or serves a new ball.

Scoring a point does not remove the alien or restart its timer. It keeps roaming through the next serve until its 20 seconds end or a ball hits it. Even after the winning point, an existing alien finishes its timer and flies away behind the game-over screen. Starting a completely new match still clears the court.

The octopus is drawn from circles, lines, and polygons. Each mechanical tentacle uses a sine wave with a different starting phase, so the arms wiggle together without moving identically.

If a ball hits the alien:

- The original ball generally keeps going forward. If it was moving almost vertically, the explosion tilts it sideways enough to keep the rally playable.
- A second ball ricochets backward at a small angle toward the opposite side.
- Each ball receives 40% of the incoming ball's momentum, plus a small fixed push from the robot's explosion. Because the balls have equal mass, the code can use speed as its momentum measurement. The horizontal part is stronger than the vertical part, reducing immediate up-and-down traps.
- The robot flashes apart, loses several tentacles and pieces, spins under gravity, and crashes against the bottom of the court.
- Both balls use the same spin, wall, paddle, trail, and scoring rules.
- Losing one ball does not reset the remaining ball.
- The next rally begins only after every active ball has left the court.

Each multiball keeps its own recovery timer. If either ball loses nearly all of its horizontal speed for more than a moment, that ball starts dribbling along the bottom, changes to small hops toward the player who hit it last, and waits for their paddle to collect it. The other ball can keep playing during the entire recovery.

Wall impacts still remove energy. A normal one-ball rally keeps 99.5% of its speed after a top or bottom wall bounce. While two balls are active, each keeps 98.5%, making the extra explosion energy drain noticeably faster. Paddle hits can still add energy again.

Momentum and kinetic energy are different. The two balls carry part of the original momentum, while the crashing robot and debris carry the rest. Some mechanical energy becomes robot motion, deformation, sound, and heat, so the two new balls should contain less kinetic energy than the incoming ball plus the explosion supplied.

## Spin

The ball now has spin, kind of like a tennis ball.

If you hit the ball while your paddle is moving, the paddle brushes the side of the ball and adds spin.

Spin does three things:

- The ball graphic rotates so you can see it spinning.
- The ball curves a little while flying.
- Wall and paddle bounces are changed a little by the spin.

Paddle hits use a "brush" idea:

- If the paddle moves with the ball's spin, it can add spin.
- If the paddle moves against the ball's spin, it can reduce or reverse spin.
- The left and right sides of a spinning ball move opposite ways, so the code checks which paddle side was hit.
- That brushing also changes the bounce angle a little.

Wall hits use spin too. The code checks how fast the part of the ball touching the wall is sliding. During impact, the wall tries to make that contact patch stick for a moment. Squishiness controls how hard it tries to stick, and friction caps how much sideways impulse the wall can actually apply. That sideways friction creates torque, which adds clockwise or counter-clockwise spin. The top and bottom of the ball move opposite ways, so they create opposite spin.

The important spin values are:

- `ball_state.spin`: how fast one ball is spinning.
- `ball_state.visual_rotation`: how that ball looks on screen.
- `SPIN_CURVE_FORCE`: how much spin bends the flight path.
- `PADDLE_BRUSH_TO_SPIN`: how much paddle brushing changes spin.
- `PADDLE_BRUSH_TO_ANGLE`: how much paddle brushing changes the bounce angle.
- `WALL_SQUISHINESS`: how much wall impact tries to make the contact patch stick.
- `WALL_SURFACE_FRICTION`: how much wall friction changes the ball's sideways speed.
- `WALL_FRICTION_TO_SPIN`: how much wall friction changes spin.
- `MAX_SPIN`: how much spin is allowed.

## Round Ball Bounces

The ball is drawn as a circle, and the code now checks collisions like a circle too.

That means the ball behaves differently depending on where it hits the paddle:

- Center hits are straighter and easier to predict.
- Edge hits kick the ball at sharper angles.
- A tiny bit of bounce wobble keeps the game from feeling robotic.

The wobble is small on purpose. It makes the game exciting, but players can still learn and aim.

Look for:

- `circle_paddle_contact()`
- `ROUND_BALL_EDGE_LIFT`
- `CONTROLLED_BOUNCE_WOBBLE`

## Sounds

The sounds are made by code, not by sound files.

The game creates sounds for:

- Paddle hit
- Wall hit
- Score
- Win
- Slam
- Robot-octopus flight
- Robot-octopus impact

Look for `create_sound_players()`, `make_tone()`, and the other `make_...()` sound functions in `scripts/main.gd`.

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
- Change `PADDLE_BRUSH_TO_SPIN` to make paddle movement affect spin more or less.
- Change `WALL_SQUISHINESS` to make wall impacts trade more or less sliding for spin.
- Change `WALL_SURFACE_FRICTION` to make wall bounces grip or slide more.
- Change `WALL_FRICTION_TO_SPIN` to make wall friction create more or less visible rotation.
- Change `MAX_SPIN` to make the ball spin faster or slower.
- Change `CONTROLLED_BOUNCE_WOBBLE` to make bounces more or less surprising.
- Change `ALIEN_MIN_DELAY` and `ALIEN_MAX_DELAY` to change how often aliens appear.
- Change `ALIEN_SPEED` to make the robot octopus roam faster or slower.
- Change `ALIEN_ROAM_SECONDS` to change how long it bounces around.
- Change `ALIEN_WOBBLE_TURN_RATE` to adjust its side-to-side wandering.
- Change `ALIEN_STEER_RADIUS` and `ALIEN_STEER_RATE` to adjust how gently it follows a nearby ball.
- Change `ALIEN_MOMENTUM_SHARE`, `ALIEN_EXPLOSION_SPEED_BOOST`, and `ALIEN_EXPLOSION_HORIZONTAL_SHARE` to tune the split launch.
- Change `MIN_MULTIBALL_RALLY_SPEED` to decide when the slower split balls begin recovery.
- Change `MULTIBALL_WALL_SPEED_RETENTION` to tune how quickly wall impacts drain multiball energy.
- Change `WINNING_SCORE` to decide how many points wins the game.
- Change the colors in `create_game_objects()`.

## License

Spin Pong is released under the [MIT License](LICENSE). Copyright (c) 2026 Allan Baker.

This game uses the [Godot Engine](https://godotengine.org/license), which is also
available under the MIT License. Exported Godot builds include additional
third-party components described in Godot's license notices.
