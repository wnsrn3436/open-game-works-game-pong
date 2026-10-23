## overview

- genre: arcade table tennis (Pong-like), single player against the CPU
- one-line pitch: a duel of returning a ball that gets faster with each hit and angling it off the end of the paddle to take 7 points from the CPU first
- target platform: macOS (game settings `buildPlatforms`). Keyboard and gamepad
- screen orientation: landscape
- base resolution: 1920x1080. The court is the 1800x920 area at the center of the base resolution

## core loop

1. Serve wait (`[first_serve_delay]` for the first serve of a match, `[serve_delay]` after a point): a dimmed ball stays still at the center of the court, and three dots and an arrowhead show from the ball in the direction the serve will go. `준비` (Ready) shows right above the ball. The paddles can move
2. Serve: the ball starts toward the side that conceded the point, in the direction shown during the wait, slower than the rally start speed. The first serve goes to the player's side
3. Rally: both paddles return the ball. With each hit the ball speed rises by `[ball_speed_step]` up to `[ball_speed_max]`, and the farther from the paddle center the ball hits, the steeper the angle. The HUD shows the rally count (the sum of both paddles' hits after the serve). The longest-rally line on the result screen writes the hits of each side in that rally as `(플레이어 N + CPU M)` (Player N + CPU M) to show what the count means
4. Score: when the ball passes one end, the opponent gets 1 point. Screen flash, shake, score sound. Back to 1
5. Match end: when one side reaches `[points_to_win]` points, after `[match_end_delay]` the result is saved on the server and the result screen opens. One rematch input goes back to 1

- Target duration of one rally cycle (from serve to point): 3000ms~15000ms
- Target duration of one match: 60000ms~240000ms

## controls

| input | action | result |
|---|---|---|
| `W`, `↑`, gamepad D-pad up, left stick up | `move_up` | While held, the player paddle moves up (starts slowly from a stop and speeds up) |
| `S`, `↓`, gamepad D-pad down, left stick down | `move_down` | While held, the player paddle moves down |
| `Esc`, gamepad `B` | `back` | During a match, opens the pause popup. In a popup and on the result screen, the back behavior of that screen |
| `P`, gamepad `Start` | `pause` | During a match, opens the pause popup. A press shorter than one frame also opens it |
| mouse click, `Enter`/`Space` (focus), gamepad `A` (focus) | UI button | Buttons on the menu, result, pause and options screens |

- Holding both directions at once stops the paddle
- Per-platform differences: none (macOS is the only target)

## screens

| scene | contents | next |
|---|---|---|
| `scene/title/title` | Game name and tagline during boot. Terms popup `prefab/common/terms_popup` for a new user | After login, `scene/match/match` for a user with no finished match (wins + losses of `MatchRecordUserState` is 0), `scene/menu/menu` otherwise |
| `scene/menu/menu` | Root panel `prefab/menu/menu_panel`: game name, one-line rules, record, start match button, options button. Options panel `prefab/menu/option_panel` | Start match → `scene/match/match` |
| `scene/match/match` | Court, two paddles, ball. Root panel `prefab/match/hud_panel`: score (at the top inside the court, spaced so the digits do not touch the court's top line), rally count (outside the court's top line, top center of the screen), match point, status (`경기 준비 중` (Getting the match ready), `준비` (Ready); right above the center ball), control hint (below the court's bottom line; written as the input prompt of the move keys, and the touch prompt is also `W` `S`, the same as the keyboard's first keys, so the letters stay the same when the input device changes). Result panel `prefab/match/result_panel`. Pause popup `prefab/match/pause_popup` | `메뉴로` (To menu) on the result panel or on the pause popup → `scene/menu/menu` |

- Terms popup: pressing the `모두 동의합니다` (I agree to all) checkbox at the top turns both consent checkboxes on or off together, and it shows as on only when both boxes are on. So a new user starts with two inputs, `모두 동의합니다` and confirm. Until both consent checkboxes are on, the confirm button is disabled and the hint line above it, `두 항목에 모두 동의하면 시작할 수 있어요` (You can start when you agree to both items), is yellow. When both are on, confirm is enabled and the hint line turns the secondary text color
- Menu: pressing start match twice still changes the scene once. The options panel closes with the back input. The back input on the root panel opens the quit confirmation
- While the match is starting: until the server answers `StartPlaySession`, the HUD shows `경기 준비 중` (Getting the match ready) and no ball appears. On failure, core shows an error and returns to the menu
- During a match: the back input and `pause` open the pause popup. The HUD (UI) receives `pause`, so it is also received in frames where the match world is stopped (between steps of DEV step mode). The HUD receives it with `InputCore.is_just_pressed(pause)`, so a short press whose press and release both happen within one frame is also received. While paused, game time (`TimeCore.set_paused`) and the match (ball, both paddles, CPU, serve wait, match-end wait) stop. The back input in the popup is continue. The pause popup does not open while the match is starting, during the match-end effect or on the result screen
- Match end: when `FinishPlaySession` succeeds, the result screen opens with the record updated. When the play session has expired (`play_session_mode.max_duration` after the start, e.g. a long pause) or the server does not know that play session, there is no core error popup and the record line on the result screen becomes `이번 경기는 전적에 넣지 못했어요 (전적 W승 L패)` (This match could not be added to your record (record W wins L losses)). For any other rejection, core shows an error and the record line on the result screen is the same text. A result that was not saved has no new-best line and no win-streak line
- Result screen: rematch has the first focus. Rematch closes the panel and then starts a new match once; a second press is ignored. The back input goes to the menu
- Input during effects: the paddles also move during the score effect and the serve wait. Screen flash and shake do not block input
- Player paddle display: the CPU paddle and the ball are drawn between the last two ticks, but the player paddle is drawn ahead of the last tick in the held direction, so it answers input without a one-tick lag. When half a tick or more has passed since the last tick in the frame where the direction input changes, one more tick runs in the previous direction, so after release the paddle stops within half a tick (about 5px) of where it was drawn

## systems

### ball and paddle

- Position and velocity are integers in court units (1/100 pixel) and advance every `[sim_tick]` (`client/features/match/sim/match_sim.gd`). Coefficients: `[court_width]`, `[court_height]`, `[paddle_height]`, `[paddle_width]`, `[paddle_inset]`, `[paddle_speed]`, `[paddle_speed_start]`, `[paddle_ramp]`, `[paddle_carry]`, `[ball_size]` of `game_setting`
- Player paddle speed: on the tick a stopped paddle starts moving, its speed is `[paddle_speed_start]`, and while it moves the speed rises evenly over `[paddle_ramp]` up to `[paddle_speed]`. Changing direction, or stopping for `[paddle_carry]` or less and pressing again, keeps the built-up speed; stopping longer starts again from `[paddle_speed_start]`. So short presses (50ms about 41px, 100ms about 91px) make fine adjustments, the last correction that changes direction just before the ball is made at top speed (50ms about 55px), and a long hold crosses the court height in about 0.72 seconds. The CPU paddle stays at `[cpu_speed]`
- Serve wait: `[first_serve_delay]` before the first serve of a match (a little longer than after a point), `[serve_delay]` after a point. The serve's vertical velocity is decided when the wait starts, and the screen shows that direction during the wait
- Serve speed: horizontal `[serve_speed]` (about 2/3 of `[ball_speed_start]`. It takes about 1.4 seconds from the court center to the paddle, so the player who conceded gets in front of the ball within about 2.4 seconds including the serve wait), vertical random in −v..v, v = `[serve_speed]` × `[serve_vy_max_permille]` ÷ 1000
- Contact mark: on each hit, a bright bar a little wider than the paddle briefly shows at the spot on that paddle where the ball hit (offset from the paddle center, clamped to the paddle) and then disappears (`tween/match/contact_mark`, game time). So the player can read where the ball hit to make that angle
- Hit: the paddle returns the ball when the y at which the ball center reaches the paddle face is within paddle center ± (paddle half-height + ball half-size). Horizontal velocity = min(max(previous, `[ball_speed_start]`) + `[ball_speed_step]`, `[ball_speed_max]`). So a returned slow serve travels at one step above the rally start speed. Vertical velocity = horizontal velocity × offset ÷ (paddle half-height + ball half-size) × `[bounce_vy_max_permille]` ÷ 1000. offset is the distance from the paddle center to the hit point
- Angle: a hit about halfway from the paddle center to its end gives a vertical velocity of 0.7 times the horizontal velocity or more (about 37°), and a hit at the paddle end gives more than the horizontal velocity (steeper than 45°). So the angle difference of end hits can be read on screen
- Wall: the sign of the vertical velocity flips at the top and bottom walls
- Score: when the ball fully passes an end of the court, the opponent scores. The next serve heads toward the side that conceded and goes after `[serve_delay]`

### CPU

- When the ball sets off toward the CPU side (serve, player hit), the CPU calculates the arrival y including wall bounces and targets that y plus an error e (random in −E..E, E = `[cpu_error_base]` + |vertical velocity| × `[cpu_error_vy_permille]` ÷ 1000 + (ball speed − `[ball_speed_start]`) × `[cpu_error_speed_permille]` ÷ 1000) and an aim offset (random in −`[cpu_aim_offset]`..`[cpu_aim_offset]`)
- After waiting for `[cpu_reaction]`, it moves toward the target by up to `[cpu_speed]` per tick. While the ball moves away, it returns toward the center by `[cpu_speed]` × `[cpu_drift_permille]` ÷ 1000 at a time
- So the faster and steeper the ball, the more the CPU misses. A ball returned with the end of the paddle is the way to win. When a long rally makes the ball fast, the CPU sometimes also misses a flat ball returned with the paddle center (about 1 in 5 at top speed). It almost never misses a flat ball right after a slow serve
- Difficulty targets (simulation imitating a human player, reaction 200~270ms and prediction error): match win rate of an average player about 1/2~2/3, first point within about 15s, median rally cycle about 9s

### match and record

- A match is one play session of `play-session`. The mode is reserved ID `[match_mode]` → `[mode_cpu_match]` of `play_session_mode`, `level_id` 0. There is no choice before the play session starts and no continue (`max_continue_count` 0)
- Result `PlaySessionResult`: `player_score`, `cpu_score`, `longest_rally`. Upper bounds of result values: `game_setting.points_to_win` for the scores, `game_setting.rally_max` for the longest rally
- `verify_play_session`: checks that only one side has exactly `[points_to_win]` points, the other side has fewer, and `longest_rally` ≤ `[rally_max]`. It does not recalculate the result to verify it. There is no ranking board that takes a result value as its score
- `apply_play_session`: adds 1 win or 1 loss to `MatchRecordUserState`; win streak +1 on a win, win streak 0 on a loss; keeps the larger value for the longest rally
- shared formula: none

## progression

none

## economy

none

## new user

- Initial state: no `MatchRecordUserState` (the record shows as 0 wins 0 losses). There is no initial state created by a server request
- First run: after the terms popup (`모두 동의합니다`, confirm), when login finishes the match screen opens right away without the menu. Until the user finishes one match (reaches the result screen), running the game again also opens the match screen first
- When there is no finished match, the menu shows `첫 경기를 시작해 보세요` (Try starting your first match). In the first match, the control hint shows below the HUD until the player first moves the paddle

## feel targets

| metric | min | max | data |
|---|---|---|---|
| `input_latency_ms` | 0 | 100 | |
| `no_response_permille` | 0 | 150 | |
| `restart_delay_ms` | 800 | 1200 | `game_setting.serve_delay` |
| `scene_load_ms` | 0 | 2000 | |

## tuning targets

| metric | min | max | data |
|---|---|---|---|
| `goal_interval_ms` | 60000 | 360000 | `game_setting.points_to_win` |

## art direction

- style: bright solid-color shapes on a dark navy court. Follows the original's black-and-white base, but splits the player as cyan and the CPU as coral, and also tells them apart by position (left/right) and name text
- hex palette: background `#0B0F1A`, court `#111726`, lines `#E8ECF4`, player `#4DD2FF`, CPU `#FF5C7A`, accent (ball top speed, match point, focus) `#FFD34D`, secondary text `#9EA8BF`
- outline: none. Buttons have a 2px cyan border, focus has a yellow border
- proportions: paddle 24x150, ball 24x24, court 1800x920 (base resolution pixels)
- screen density: only the score and status text are on the court. The rally count sits outside the court's top line so it does not cover the ball
- representative resource keys: `app_icon/main`, `splash/main`, `font/main`

## audio direction

- mood: short, crisp synth blips. Keeps the feel of the original's beeps and uses chords only for scores and match wins and losses
- BGM per scene: menu `bgm/menu` (calm synth loop). There is no BGM during a match; the hit sounds make the rhythm
- events that play a sound: UI button press `sfx/ui_click`, paddle hit `sfx/paddle_hit`, wall bounce `sfx/wall_bounce`, serve `sfx/serve`, player point `sfx/score_player`, CPU point `sfx/score_cpu`, match win `sfx/match_win`, match loss `sfx/match_lose`

## terms

- words used: `패들` (paddle), `공` (ball), `랠리` (rally), `서브` (serve), `매치 포인트` (match point), `전적` (record), CPU, `플레이어` (player)
- words not used: Pong (trademark), `라켓` (racket), `탁구` (table tennis)
- glossary terms: `패들 듀얼` (Paddle Duel), `패들` (paddle), `랠리` (rally), `매치 포인트` (match point), CPU

## core usage

- client hook: none. `ContentBoot` uses the core default behavior
- server hook: `play-session` hooks `verify_play_session` (`server/hooks/play_session.ts` `verify_match_result`) and `apply_play_session` (`apply_match_result`)
