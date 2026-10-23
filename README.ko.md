# open-game-works-game-pong

[English](README.md)

**패들 듀얼**(`Paddle Duel`, 임시 이름)은 패들로 공을 받아치는 macOS용 아케이드 게임으로, 플레이어 한 명이 CPU와
겨룬다. AI 에이전트가 [open-game-works](https://github.com/wnsrn3436/open-game-works-core)로 만들었다.

<p align="center"><img src=".github/media/pong.gif" alt="pong gameplay" width="640"></p>

## 현재 상태

이 게임은 open-game-works로 만들었고, 개발하는 동안 macOS에서 플레이하며 확인했다. 출시용 빌드는 아직 없다.
`build` 명령을 한 번도 실행하지 않았다.

## 어떤 게임인가

왼쪽 패들을 움직여 공을 받아친다. 공은 칠 때마다 조금씩 빨라지고, 패들의 어느 지점에 맞느냐에 따라 돌아가는 각도가
정해진다. 가운데에 맞으면 거의 수평으로, 끝에 맞으면 가파르게 돌아간다. CPU는 공이 빠르고 가파를수록 더 자주
놓친다. 그래서 점수는 긴 랠리 끝에 패들 끝으로 각도를 꺾어 보낸 공에서 나온다. 먼저 7점을 낸 쪽이 경기에서
이긴다.

이 게임은 간단한 패들과 공 게임을 만들어 달라고 하네스에 준 한 줄짜리 요청에서 시작했다. `brief.md`의
`## request`에 그 요청과, 요청에 없어서 콘텐츠 에이전트가 정한 항목이 있다. 레퍼런스 게임은 `setup game`에서 사람이
골랐다.

| | |
|---|---|
| 플레이어 | 한 명, CPU와 대결 |
| 플랫폼 | macOS (`settings.json` `buildPlatforms`) |
| 입력 | 키보드, 게임패드 |
| 화면 | 가로, 기준 해상도 1920x1080 |
| 언어 | 한국어(원문), 영어 |
| 클라이언트 / 서버 | Godot / TypeScript |
| core 버전 | `0.1.0` (`settings.json` `coreVersion`) |

### 경기 흐름

1. 서브 대기: 흐리게 표시된 공이 코트 가운데에서 기다리고, 점과 화살촉이 서브 방향을 보여 준다. 이때도 패들은
   움직일 수 있다. 대기 시간은 첫 서브 전 1.2초, 득점 뒤 1초다.
2. 서브: 공은 직전 점수를 내준 쪽으로, 랠리 공보다 느리게 출발한다. 첫 서브는 플레이어 쪽으로 간다.
3. 랠리: 공은 패들에 맞을 때마다 최고 속도에 이를 때까지 빨라진다. 화면 위쪽에 랠리 수가 나오고, 어느 쪽이든
   1점만 남으면 매치 포인트가 표시된다.
4. 득점: 공이 코트 한쪽 끝을 지나가면 상대편이 1점을 얻는다. 화면 번쩍임, 흔들림, 소리가 함께 나고, 다음 서브는
   입력 없이 이어진다.
5. 경기 종료: 한쪽이 7점에 이르면 결과가 서버에 저장되고, 결과 화면에 점수, 최장 랠리, 전적이 나온다.
   `다시 하기`를 한 번 누르면 다음 경기가 시작된다.

처음 하는 플레이어는 약관 팝업을 한 번 보고 바로 첫 경기에 들어간다. 경기를 하나 끝내기 전까지는 게임을 켜면 경기
화면이 열리고, 그 뒤로는 메뉴(전적, 경기 시작, 설정)가 열린다. 경기 사이에 남는 것은 전적(승, 패, 최장 랠리,
연승)뿐이다. 파워업, 아이템, 재화, 상점, 광고, 결제는 없고, 한 화면에서 두 사람이 하는 모드도 없다.

### 조작

| 입력 | 동작 |
|---|---|
| `W` 또는 `↑`, 게임패드 방향 패드 위 또는 왼쪽 스틱 위 | 누르는 동안 패들이 위로 이동 |
| `S` 또는 `↓`, 게임패드 방향 패드 아래 또는 왼쪽 스틱 아래 | 누르는 동안 패들이 아래로 이동 |
| `P`, 게임패드 `Start` | 경기 중 일시 정지 |
| `Esc`, 게임패드 `B` | 경기 중 일시 정지, 다른 화면에서는 뒤로 |
| 마우스 클릭, `Enter` 또는 `Space`, 게임패드 `A` | UI 버튼 누르기 (`Enter`, `Space`, `A`는 포커스된 버튼) |

두 방향을 동시에 누르고 있으면 패들이 멈춘다.

### 그래픽과 소리

어두운 남색 코트 위에 밝은 단색 도형을 쓴다. 플레이어 패들은 청록(`#4DD2FF`), CPU 패들은 코랄(`#FF5C7A`)이고,
노랑(`#FFD34D`)은 공의 최고 속도, 매치 포인트, 포커스를 표시한다. 공이 패들에 맞으면 화면이 흔들리고, 패들이
눌리고, 맞은 자리가 표시되고, 짧은 신스 효과음이 난다. 득점하면 화면이 흔들리고 코트가 번쩍이며 득점 효과음이 난다.
공은 잔상을 남기고, 벽에 튈 때도 따로 소리가 난다. 메뉴에서는 잔잔한 신스 루프가 흐르고, 경기 중에는 음악이 없다.

## 동작 방식

경기는 클라이언트가 돌리고, 전적은 서버가 보관한다.

```
client/ (Godot)                               server/ (TypeScript)
features/match/sim/match_sim.gd               server core module play-session
  ball, paddles and CPU in integer
  court units, one tick every 10 ms

match start --- StartPlaySession -----------> opens a play session
match end   --- FinishPlaySession ----------> hooks/play_session.ts
                PlaySessionResult               verify_match_result
                (player_score, cpu_score,       apply_match_result
                 longest_rally)
            <-- updated MatchRecordUserState -- wins, losses, best_rally, win_streak
```

- `verify_match_result`는 정확히 한쪽만 7점이고 다른 쪽은 그보다 적으며 최장 랠리가 `rally_max` 이내일 때만 결과를
  받아들인다. `apply_match_result`는 승이나 패를 하나 더하고, 연승을 갱신하고, 최장 랠리를 더 큰 값으로 남긴다.
- CPU는 공이 도착할 위치를 예측하고, 반응 시간만큼 기다린 뒤, 그 위치에 오차를 더한 곳으로 제한된 속도로 움직인다.
  오차는 공이 빠르고 가파를수록 커진다(`design.md` `### CPU`).
- 게임플레이 값(승리 점수, 틱, 패들과 공의 속도, 서브 대기 시간, CPU 반응과 오차)은 코드 속 상수가 아니라
  `data/system/game_setting.csv`의 행이다.
- 게임이 따로 정의한 요청은 없다. `contract/service.proto`에는 `PlaySessionResult`만 있고,
  `contract/user_state.proto`에는 `MatchRecordUserState`가 있다.
- 게임이 고른 core 모듈(`settings.json` `coreModules`): 클라이언트 `NativeUiCore`, `TweenCore`, `ScreenEffectCore`,
  `CameraCore`, 서버 `play-session`.

## open-game-works로 제작

[open-game-works](https://github.com/wnsrn3436/open-game-works-core)는 AI 에이전트가 서버-클라이언트 게임을 만드는
하네스다. 여러 게임이 되풀이하는 기능은 core로 미리 만들어 두고, 에이전트는 게임플레이만 content code로 쓴다. 게임은
루프를 돌며 만든다. 콘텐츠 에이전트가 고치고, 플레이 에이전트가 인스턴스를 실제 입력으로 플레이하고, 판정 에이전트가
그 인스턴스를 기준 게임과 비교하고 레퍼런스 게임의 플레이 영상과도 비교하며, 하네스 도구가 저지 결과와 자동 검사로
성공을 판정한다. 최종 리소스는 리소스 서브 에이전트가, 번역은 번역 서브 에이전트가 만든다.

`client/core/`와 `server/core/`는
[core 릴리스 v0.1.0](https://github.com/wnsrn3436/open-game-works-core-impl/releases/tag/v0.1.0)의 사본이고, 엔진
버전도 그 릴리스가 정한다(Godot 4.7.2). `update game`은 시작할 때 `coreVersion`을 이 게임이 쓸 수 있는 가장 새로운
core 릴리스로 올린다.

| 저장소 | 내용 |
|---|---|
| [open-game-works-core](https://github.com/wnsrn3436/open-game-works-core) | 하네스: 에이전트 규칙, 스킬, 모듈 스펙, CLI `ogw` |
| [open-game-works-core-impl](https://github.com/wnsrn3436/open-game-works-core-impl) | core 구현. core 릴리스는 이 저장소의 GitHub Releases |
| [open-game-works-game-mana-clash](https://github.com/wnsrn3436/open-game-works-game-mana-clash) | 같은 하네스로 만든 다른 게임: 1대1 카드 배틀 게임 |
| open-game-works-game-pong | 이 게임 |

## 저장소 구성

| 경로 | 내용 |
|---|---|
| `brief.md` | 브리프: 플레이어 판타지, 감정, 기억에 남을 순간, 장르 관습, 금지 사항, 실패 페널티, 예측, 레퍼런스 게임, 요청과 콘텐츠 에이전트가 정한 항목 |
| `design.md` | 디자인 문서: 코어 루프, 조작, 화면, 시스템(공과 패들, CPU, 경기와 전적), 감각과 튜닝 목표, 아트와 오디오 방향, 용어, core 사용 |
| `play-guide.md` | 플레이 에이전트와 판정 에이전트가 받는 플레이 가이드: 목표, 조작, 게임 흐름, 입력 잠금 구간, 가장 빠른 시작 경로, 장면별 플레이 모드 |
| `settings.json` | 게임 설정: core 버전, 엔진, core 모듈, 빌드 플랫폼, 언어, 해상도, 환경별 값(시크릿은 이름만), 서명, 약관 문서 |
| `contract/` | contract(protobuf): `service.proto`, `user_state.proto` |
| `data/` | CSV 테이블(`tables/`), 시스템 테이블(`system/`, `game_setting.csv` 포함), 번역(`translations/`), 용어집(`glossary.csv`), enum과 invariant |
| `resource/` | 리소스 키별 리소스: 앱 아이콘, 스플래시, 폰트, BGM, 효과음, 장면, 프리팹, 트윈 프리셋. `resources.csv`에 모든 리소스 키와, 생성하거나 카탈로그에서 가져온 리소스의 제작 방법과 라이선스(폰트는 출처도)가 있음 |
| `client/` | Godot 프로젝트. content code는 `boot/`, `common/`, `features/`(`title`, `menu`, `match`), 회귀 테스트는 `tests/`, DEV 코드는 `dev/`(봇 플레이테스트 시나리오 `dev/bot/scenario.json`). `core/`와 `generated/`는 하네스 도구가 씀. `resource`는 `../resource`로의 링크 |
| `server/` | TypeScript 서버. `main.ts`가 `hooks/play_session.ts`의 훅을 등록, 회귀 테스트는 `tests/`, DEV 코드는 `dev/`. `core/`와 `generated/`는 하네스 도구가 씀 |
| `records/` | 에이전트와 도구가 쓰는 작업 기록(루프 반복 기록, 루프 종료 기록, 하드닝 기록, core 제안). 지금 저장소에는 `records/setup/reference/reference.md`만 있음 |
| `LICENSE`, `LICENSES/` | 라이선스 전문 |

`id-registry` 브랜치에는 ID 레지스트리(`id_registry.json`)만 있다. 이 브랜치에는 데이터 도구만 쓰고, 다른 브랜치와
병합하지 않는다. 빌드 결과물(`builds/`), 데이터 바이너리(`client/build/`, `server/build/`), 캡처, 루프 증거 자료는
커밋하지 않는다.

### 언어

원문은 한국어다. `settings.json`에 `sourceLanguage`가 없으므로 기본값 `ko`가 적용되고, `supportedLanguages`는 `ko`와
`en`이다. 영어 텍스트는 `data/translations/en.csv`에 있고, 게임 제목 같은 이름의 번역은 `data/glossary.csv`가
고정한다. 문서(`brief.md`, `design.md`, `play-guide.md`, `reference.md`)는 영어로 썼고, 게임 속 한국어 텍스트는 코드
스팬으로 남겼다.

## 요구 사항

- 하네스 [README](https://github.com/wnsrn3436/open-game-works-core)대로 하네스를 준비한 open-game-works 작업 공간
  (Node 24 이상, Git, GitHub CLI, buildx가 있는 Docker, uv와 Python, Claude Code 또는 Codex)
- Godot 4.7.2. 이 게임이 고정한 core 릴리스가 정한 엔진 버전이고, `update env`가 `<workspace>/.ogw/`에 설치한다
- macOS 앱을 빌드하려면 Xcode 27(core 릴리스 0.1.0의 `engine.json`이 지정)이 있는 Apple silicon Mac이 필요하다.
  macOS는 이 게임의 유일한 빌드 플랫폼이다
- Windows: `client/resource`는 심볼릭 링크다. 클론하기 전에 개발자 모드를 켜고
  `git config --global core.symlinks true`를 실행해야 한다. 그러지 않으면 링크가 일반 텍스트 파일로 체크아웃된다.
  플레이 에이전트와 판정 에이전트는 macOS와 Linux에서만 실행되므로, Windows에서는 루프와 빌드를 돌릴 수 없다

## 설치

작업 공간의 `games/` 아래에 저장소를 클론하고, 원격 브랜치에서 로컬 `id-registry` 브랜치를 만든다. 클론하면 로컬
브랜치는 `main`만 생기는데, 데이터 도구는 로컬 `id-registry` 브랜치에서 ID 레지스트리를 읽는다.

```
<workspace>/
  open-game-works-core/
  open-game-works-core-impl/
  games/open-game-works-game-pong/
```

```sh
cd <workspace>
git clone https://github.com/wnsrn3436/open-game-works-game-pong.git games/open-game-works-game-pong
git -C games/open-game-works-game-pong branch id-registry origin/id-registry
```

폴더 이름이 명령에서 쓰는 게임 이름이다. 그다음 `open-game-works-core/`에서 Claude Code나 Codex를 열고
`update env`를 실행한다. 이 명령은 이 게임의 빌드 도구를 확인하고 core 버전에 맞는 엔진을 설치한다.

### 레퍼런스 게임 영상

`records/setup/reference/reference.md`에는 `setup game`에서 사람이 고른 레퍼런스 게임, 그 플레이 영상의 출처 URL,
판정 에이전트가 비교하는 영상 속 순간이 기록되어 있다. 영상 파일은 저장소에 없지만(`.gitignore`가
`records/setup/reference/`에서 `reference.md`를 뺀 모든 파일을 제외) `update game`의 판정 에이전트에게 필요하다. 루프를 돌리기 전에
`open-game-works-core/`에서 다음 명령을 실행해 받아 온다(`yt-dlp` 필요).

```sh
tools/bin/ogw game reference open-game-works-game-pong <reference.md의 YouTube URL>
```

영상은 `records/setup/reference/`에 `<video id>.mp4`로 저장된다. 이 파일 이름을 `reference.md`의 `## video`에 적힌
이름으로 바꾼다.

## 사용법

`open-game-works-core/`에서 연 Claude Code나 Codex 세션에 아래 명령을 준다. 명령을 받은 에이전트가 끝까지 진행하고
결과를 보고한다.

| 명령 | 하는 일 |
|---|---|
| `update game: open-game-works-game-pong <request>` | 루프로 게임을 고친다. 요청은 사람의 피드백이나 고칠 PROD 문제다. 루프가 멈추면, 그사이 main이 바뀌지 않았을 때 도구가 고른 커밋을 main에 병합하고 루프 종료 기록으로 보고한다 |
| `build: open-game-works-game-pong DEV` | 서버와 클라이언트 content code를 하드닝하고, PostgreSQL로 검사를 다시 돌리고, macOS 앱을 `builds/`에 빌드하고, 커밋에 `dev-<version>` 태그를 붙이고, DEV 서버를 배포한다. `--version`이 없으면 첫 빌드는 `0.1.0`이다 |

STG와 PROD 빌드는 서명된 결과물까지 만든다. STG는 서버도 배포하고, PROD 배포는 사람이 한다.

### 인스턴스 실행

인스턴스는 게임을 개발용으로 실행한 것으로, 자기 DB를 가진 로컬 서버 하나와 화면을 그리는 클라이언트로 이루어진다.
`ogw`는 하네스 저장소의 `tools/bin/ogw`이고, `open-game-works-core/`에서 실행한다.

```sh
tools/bin/ogw instance start open-game-works-game-pong   # 인스턴스 id와 주소를 출력
tools/bin/ogw instance stop <id>
```

클라이언트는 개발용 계정으로 로그인하고 약관 팝업 없이 시작한다. `--db postgresql`을 주지 않으면 DB는 SQLite이고,
`--commit <sha>`를 주면 다른 커밋으로 인스턴스를 시작한다. `ogw capture <id>`는 화면을 캡처하고, `ogw log <id>`는
오류 로그를 보여 주고, `ogw command <id> list_commands`는 게임의 content command 목록을 보여 준다.

### 첫 DEV 빌드 전에

아래 명령은 `open-game-works-core/`에서 실행한다.

- `settings.json`에는 시크릿 이름만 있다. 값은 호스트의 시크릿 저장소에 넣는다. 생성할 수 있는 값은
  `tools/bin/ogw secret generate open-game-works-game-pong DEV`로, 배포 SSH 키나 `signing.macos`의 macOS 서명 자료
  같은 나머지는 `tools/bin/ogw secret set open-game-works-game-pong <DEV|signing> <name>`으로 넣는다. `secret set`은
  값을 표준 입력으로 받는다.
- 새 호스트에서 `secret generate`는 새 업데이트 서명 키를 만들고 그 공개 키를 `settings.json`의 `updatePublicKeys`에
  더한다. 빌드 전에 이 변경을 커밋한다.
- `settings.json`의 서버 URL, 배포 호스트와 호스트 키, 약관 문서 URL, CDN 값, 공증 ID는 자리 표시용 값(`.invalid`
  호스트, `PLACEHOLDER`)이다. 직접 쓸 값으로 바꾸고, `serverImage.repository`와 `appId`도 직접 관리하는 이미지
  저장소와 앱 ID로 바꾼다.

## 라이선스

| 대상 | 라이선스 |
|---|---|
| 이 저장소의 콘텐츠 | [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/) (`LICENSE`) |
| `client/core/`, `server/core/` (open-game-works core 릴리스의 사본) | Apache-2.0 (`LICENSES/Apache-2.0.txt`) |
| `resource/font/main.ttf` (Black Han Sans) | SIL Open Font License 1.1 (`LICENSES/OFL-1.1-BlackHanSans.txt`) |

`resource/resources.csv`에는 모든 리소스 키가 있다. 생성 방법으로 만들었거나 고정된 카탈로그에서 가져온 최종
리소스에는 제작 방법과 라이선스도 적혀 있고, 폰트에는 출처와 저작권 표시도 적혀 있다. 그 리소스는 다음과 같다.

| 리소스 | 방법 | 라이선스 |
|---|---|---|
| `app_icon/main`, `splash/main` | `flux2-klein` | Apache-2.0 |
| `bgm/menu` | `ace-step` | MIT |
| `sfx/*` | `moss-sfx` | Apache-2.0 |
| `font/main` | `font-catalog` | OFL-1.1 |

게임의 라이선스 매니페스트 `client/generated/licenses.json`에 Godot Engine 같은 서드파티 구성 요소와 그 라이선스,
고지문이 있다.
