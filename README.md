# open-game-works-game-pong

[한국어](README.ko.md)

**Paddle Duel** (`패들 듀얼`, a working title) is a paddle-and-ball arcade game for macOS, one player against the CPU,
made by AI agents with [open-game-works](https://github.com/wnsrn3436/open-game-works-core).

<p align="center"><img src=".github/media/pong.gif" alt="pong gameplay" width="640"></p>

## Play it

You need an open-game-works workspace set up as in the harness [Quick start](https://github.com/wnsrn3436/open-game-works-core#quick-start).

```sh
cd <workspace>
git clone https://github.com/wnsrn3436/open-game-works-game-pong.git games/open-game-works-game-pong
git -C games/open-game-works-game-pong branch id-registry origin/id-registry   # the data tool reads the local branch

cd open-game-works-core
tools/bin/ogw instance start open-game-works-game-pong   # prints the instance id and address
tools/bin/ogw instance stop <id>
```

After cloning, run `update env` once in a Claude Code or Codex session opened in `open-game-works-core/`: it installs
the engine of this game's core version.

## The game

You move the left paddle and return a ball that gets a little faster with each hit. Where the ball meets the paddle
sets the return angle: almost flat from the center, steep from the end. The CPU misses more often as the ball gets
faster and steeper, so points come from a long rally ended by a shot angled off the end of the paddle. The first side
to 7 points wins; `다시 하기` (Play again) starts the next match, and only your record (wins, losses, best rally, win
streak) is kept. Keyboard or gamepad; Korean (source text) or English.

| input | action |
|---|---|
| `W` / `↑`, D-pad up or left stick up | move the paddle up while held |
| `S` / `↓`, D-pad down or left stick down | move the paddle down while held |
| `P` / `Esc`, gamepad `Start` / `B` | pause during a match (`Esc` and `B` go back on other screens) |
| mouse click, `Enter` / `Space`, gamepad `A` | press a UI button (`Enter`, `Space` and `A` press the focused one) |

## Status

Played and checked on macOS during development. Not built for release yet: `build` has not been run on it.

## Change it with AI

Give these commands in a Claude Code or Codex session opened in `open-game-works-core/`:

| command | what it does |
|---|---|
| `update game: open-game-works-game-pong <request>` | changes the game through the loop from your feedback or a PROD problem to fix |
| `build: open-game-works-game-pong DEV` | hardens the code, builds the macOS app into `builds/`, tags `dev-<version>`, deploys the DEV server |

`update game` needs the reference gameplay video, which is not in the repository. Fetch it first (needs `yt-dlp`), then
rename the saved `<video id>.mp4` to the name under `## video` in [`reference.md`](records/setup/reference/reference.md):

```sh
tools/bin/ogw game reference open-game-works-game-pong <the YouTube URL in reference.md>
```

### Before the first DEV build

- `settings.json` holds only secret names. From `open-game-works-core/`, run
  `tools/bin/ogw secret generate open-game-works-game-pong DEV`, then
  `tools/bin/ogw secret set open-game-works-game-pong <DEV|signing> <name>` (value from stdin) for the rest, such as the
  deploy SSH key and the macOS signing material of `signing.macos`.
- On a new host, `secret generate` adds a new update signing public key to `updatePublicKeys` in `settings.json`.
  Commit that change before the build.
- Server URLs, deploy hosts and host keys, terms document URLs, CDN values and notary IDs in `settings.json` are
  placeholders (`.invalid` hosts, `PLACEHOLDER`). Replace them, and set `serverImage.repository` and `appId` to an
  image repository and an app ID that you control.
- The macOS app builds on an Apple silicon Mac with Xcode 27.

## How it is built

The Godot client runs the match (ball, paddles and CPU, one tick every 10 ms). The TypeScript server keeps the record:
at match end, `server/hooks/play_session.ts` checks the score and longest rally and updates the record. Gameplay values
are rows of `data/system/game_setting.csv`. The game pins core `0.1.0` (`settings.json` `coreVersion`): `client/core/`
and `server/core/` are copies of [core release v0.1.0](https://github.com/wnsrn3436/open-game-works-core-impl/releases/tag/v0.1.0),
which sets the engine (Godot 4.7.2).

| path | contents |
|---|---|
| [`brief.md`](brief.md) | the brief: player fantasy, emotion, reference game, the original request |
| [`design.md`](design.md) | the design doc: core loop, controls, screens, systems, tuning, art and audio |
| [`play-guide.md`](play-guide.md) | the guide the play and judge agents receive |
| [`settings.json`](settings.json) | game settings: core version and modules, platforms, languages, environments |
| [`contract/`](contract) | protobuf contract: `service.proto`, `user_state.proto` |
| [`data/`](data) | CSV tables, `system/game_setting.csv`, English translation, glossary |
| [`resource/`](resource) | resources by key; [`resources.csv`](resource/resources.csv) lists each one |
| [`client/`](client) | Godot project; content code in `boot/`, `common/`, `features/` |
| [`server/`](server) | TypeScript server; hooks in `hooks/play_session.ts` |
| [`records/`](records) | process records; now only the reference game record |

Made with the [open-game-works](https://github.com/wnsrn3436/open-game-works-core) harness.

## License

| part | license |
|---|---|
| The content of this repository | [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/) (`LICENSE`) |
| `client/core/`, `server/core/` (copies of an open-game-works core release) | Apache-2.0 (`LICENSES/Apache-2.0.txt`) |
| `resource/font/main.ttf` (Black Han Sans) | SIL Open Font License 1.1 (`LICENSES/OFL-1.1-BlackHanSans.txt`) |

`resource/resources.csv` lists every resource key. For the final resources made by a generation method or taken from a
pinned catalog, it also gives the method and license, and for the font the source and attribution. Those resources
are:

| resources | method | license |
|---|---|---|
| `app_icon/main`, `splash/main` | `flux2-klein` | Apache-2.0 |
| `bgm/menu` | `ace-step` | MIT |
| `sfx/*` | `moss-sfx` | Apache-2.0 |
| `font/main` | `font-catalog` | OFL-1.1 |

The license manifest of the game, `client/generated/licenses.json`, lists the third-party components, such as the
Godot Engine, with their licenses and notices.
