## goal

The player moves the left cyan paddle to return the ball and scores 7 points before the CPU on the right. When the ball passes the right end it is the player's point; when it passes the left end it is the CPU's point.

## controls

- While `W` or `↑` (key names `W`, `Up`) is held: the player's paddle moves up
- While `S` or `↓` (key names `S`, `Down`) is held: the player's paddle moves down
- When a press starts, a stopped paddle starts a little slowly and speeds up to top speed over about 0.1 seconds. A short tap moves it only a little (about 41px in 50ms, about 91px in 100ms), and holding moves it end to end between the court's top and bottom in about 0.7 seconds. Changing direction while moving, or pressing again within 0.05 seconds, keeps that speed (about 55px in 50ms at top speed)
- Holding both directions at once stops the paddle
- gamepad: D-pad up/down or the left stick works the same as above
- `Esc` (key name `Escape`) or `P`, gamepad `B` or `Start`: opens the pause popup during a match. A very short press (`key P`, 0ms) also opens it
- The farther from the paddle center (toward the end) the ball hits, the steeper the angle it goes back at. A hit at the center sends it back almost horizontally. A short white bar across the paddle shows at the spot where the ball hit for about 0.4 seconds
- The ball gets faster each time it hits a paddle. The current rally count shows at the top center of the screen, outside the court's top line (from 2 hits). The rally count is the total number of times both paddles hit the ball after the serve (2 when the player hits once and the CPU hits once)
- Buttons on screen are pressed by click (tap)

## game flow

1. Terms consent popup (new user only): pressing the `모두 동의합니다` (I agree to all) checkbox at the top (anchor `terms_agree_all`) turns on the two consent checkboxes below it together (the squares at the left of the lines, filled yellow when on). Pressing the two boxes one by one also works. Then the player presses the confirm button (anchor `terms_confirm`). Until both are on, the confirm button is disabled and cannot be pressed, and the hint line above it shows yellow. The `보기` (View) button at the right of a line opens the document
2. For a user with no finished match, the match screen of step 3 opens right after login without the menu. For a user who has finished one match or more, the menu opens. Menu: pressing the `경기 시작` (Start match) button (anchor `menu_play`) goes to the match screen. The `설정` (Options) button (anchor `menu_options`) opens the options screen. Pressing `메뉴로` (To menu) during a match or on the result screen goes to the menu
3. Match screen: after `경기 준비 중` (Getting the match ready) shows briefly, a dimmed ball stays still at the center of the screen, three dots and an arrowhead show from the ball in the direction the serve will go, and `준비` (Ready) shows right above the ball. After 1.2 seconds the ball starts in that direction toward the player's side. The serve is slower than a rally ball and speeds up on the first return. `플레이어` (Player) shows under the player's score and `CPU` under the CPU's score. In the first match, the control hint shows below the court's bottom line. After a point, the next serve direction shows the same way for 1 second, then the ball is served again toward the side that conceded
4. When one side reaches 7 points, the result screen opens shortly after: win/loss, score, the longest rally of this match and the number of hits by each side in that rally (`(플레이어 N + CPU M)` (Player N + CPU M)), record. When the record was not saved (e.g. the play session expired because 1 hour passed after the match started), the record line is `이번 경기는 전적에 넣지 못했어요 (전적 W승 L패)` (This match could not be added to your record (record W wins L losses)). `다시 하기` (Rematch, anchor `result_rematch`) starts a new match right away, and `메뉴로` (To menu, anchor `result_menu`) goes to the menu
5. Pause popup: `계속하기` (Continue, anchor `pause_resume`) continues the match, and `메뉴로` (To menu, anchor `pause_quit`) abandons the match and goes to the menu

## failure

- Conceded point: when the ball passes the player's paddle and crosses the left end, the CPU gets 1 point. After 1 second the ball is served again toward the player's side. There is no restart input. The paddle also moves while the point is conceded
- Match loss: when the CPU scores 7 points first, the result screen opens. Pressing `다시 하기` (Rematch) starts a new match

## input lock window

- boot and title: input is not accepted until login finishes (about 1000ms~3000ms)
- scene change (menu ↔ match): input is not accepted during the loading screen (about 300ms~1000ms)
- match start: no ball appears until the server responds (about 100ms~500ms). The paddles do not move either
- serve wait: the ball stays still at the center for 1200ms after the match starts and for 1000ms after a point (dimmed, with the serve direction display). The paddles move
- match end: the result screen does not open for about 900ms after the last point and until the record save responds
- pause popup: while it is open, game time and the match (ball, paddles, CPU, serve wait) stop. In step mode during this time, `ogw step` fails right away with `game time is paused` and no time accumulates. The popup is closed with `tap_anchor pause_resume`, without a step. `P` and `Escape` also open the popup between steps of step mode
- paddle movement in step mode: the ms of `ogw input <id> key W <ms>` is real time, and game time does not pass during it, so the paddle does not move. The paddle moves with `key_down W` → `ogw step <id> <ms>` → `key_up W` (the same for `S`)

## fastest start path

1. (new user) terms popup `tap_anchor terms_agree_all` → `tap_anchor terms_confirm`
2. With no finished match, the match screen opens right after login. If the menu opened, `tap_anchor menu_play`
3. About 1200ms after the match screen opens, the ball is served

## play mode

| scene | mode | step ms |
|---|---|---|
| `scene/title/title` | `free` | |
| `scene/menu/menu` | `free` | |
| `scene/match/match` | `step` | 50 |
