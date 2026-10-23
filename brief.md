## player fantasy

The player becomes a reflex duelist who keeps returning a ball that keeps getting faster to the very end, then breaks through the opponent's defense with one shot angled off the end of the paddle.

## emotion

Core emotion: tension.

Curve of one match:

1. Right after the serve: the ball is slow, so there is room to breathe. Low tension
2. While the rally goes on: the ball gets faster with each hit and the rally count on screen goes up. Tension keeps rising
3. Scoring or conceding a point: screen flash, shake and sound release the tension at once. A short breather until the next serve
4. Match point (either side has only 1 point left to win): match point shows on screen and tension is at its highest
5. Match end: release on a win, the regret of "just one more match" on a loss

## memorable moment

The moment when, in a long rally with the ball near top speed, the player catches it with the end of the paddle and angles it steeply past the CPU paddle for the winning point.

## genre conventions

| convention | decision | reason |
|---|---|---|
| Two paddles, one on each side, and one ball; bounces off the top and bottom walls; the opponent of the side that misses scores | accept | It is the identity of the genre |
| The bounce angle changes with where the ball hits the paddle | accept | The depth of control comes from this. It is the basis of the memorable moment |
| Ball acceleration during a rally | twist | The original speeds up in steps per hit-count range. This game speeds up a little with each hit and shows the rally count on screen, so the player sees the tension rise |
| First to 11 points | twist | First to 7 points keeps a match short. A short match makes "just one more match" easy |
| Two people play each other on the same machine | reject | One player plays the CPU. The target platform is a personal Mac, and starting alone right away is the center of this game |
| Black-and-white screen and simple beeps | twist | Keeps the bright solid colors on a dark background, and adds screen shake, flash, ball afterimage and sound to hits and scores to make the feedback stronger |
| Arcade with no progression outside the score | accept | No currency, growth or unlocks. Only the win/loss record is kept |

## prohibitions

- No same-screen 2-player match (drops a genre-standard feature)
- No power-ups, items, currency, shop, ads or payments
- The CPU does not get a perfect defense that returns every ball with no reaction delay and no speed limit. The player must be able to win with angles
- After conceding a point, the player does not have to go through a menu to restart. The next serve follows without input

## failure penalty

- Share of progress lost per mistake (conceded point): 0‰. The player's score does not go down. Instead, the opponent gains 1/7 (142‰) of the way to winning the match
- Duration limit of the loss state: 1200ms. It is the sum of the conceded-point effect and the wait for the next serve
- Delay limit from the end of the loss until the player can control again: 0ms. The paddle can move during the conceded-point effect and the serve wait
- Match loss: one input on the result screen restarts right away. 1000ms or less from the result screen appearing until the rematch button can be pressed

## prediction

If it works, on the result screen after the first match the player will press the rematch button to start a second match instead of going to the menu.

## reference game

Pong (Atari, 1972, arcade)

records/setup/reference/reference.md

How this game differs from the reference game:

- One player plays the CPU instead of two people playing each other
- First to 7 points instead of 11
- The ball gets faster with each hit, and the screen shows the current rally count and match point
- Hits, wall bounces and scores get screen shake, flash, ball afterimage and sound
- The win/loss record is saved on the server and shown on the menu

## request

`간단하게 pong게임 만들어줘` (Make a simple pong game)

Items the content agent decided:

- Single player against the CPU. The left paddle is the player
- A match ends when one side reaches 7 points first
- The target platform is macOS in game settings `buildPlatforms`. Controls are keyboard and gamepad
- The screen is landscape, base resolution 1920x1080
- Supported languages are Korean and English
- The game name is `Paddle Duel` (`패들 듀얼`) for now. `Pong` is not used because it is another company's trademark
