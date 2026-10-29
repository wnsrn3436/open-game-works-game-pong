# open-game-works-game-pong

[English](README.md)

**패들 듀얼**(`Paddle Duel`, 임시 이름)은 플레이어 한 명이 CPU와 겨루는 macOS용 패들과 공 아케이드 게임으로, AI
에이전트가 [open-game-works](https://github.com/wnsrn3436/open-game-works-core)로 만들었다.

<p align="center"><img src=".github/media/pong.gif" alt="pong gameplay" width="640"></p>

## 직접 플레이하기

하네스 [빠른 시작](https://github.com/wnsrn3436/open-game-works-core/blob/main/README.ko.md#빠른-시작)대로 준비한 open-game-works 작업 공간이 필요하다.

```sh
cd <workspace>
git clone https://github.com/wnsrn3436/open-game-works-game-pong.git games/open-game-works-game-pong
git -C games/open-game-works-game-pong branch id-registry origin/id-registry   # 데이터 도구는 로컬 브랜치를 읽는다

cd open-game-works-core
tools/bin/ogw instance start open-game-works-game-pong   # 인스턴스 id와 주소를 출력
tools/bin/ogw instance stop <id>
```

클론한 뒤 `open-game-works-core/`에서 연 Claude Code나 Codex 세션에서 `update env`를 한 번 실행한다. 이 명령이 이
게임의 core 버전에 맞는 엔진을 설치한다.

## 게임 소개

왼쪽 패들을 움직여 공을 받아친다. 공은 칠 때마다 조금씩 빨라지고, 패들의 어느 지점에 맞느냐에 따라 돌아가는 각도가
정해진다. 가운데에 맞으면 거의 수평으로, 끝에 맞으면 가파르게 돌아간다. CPU는 공이 빠르고 가파를수록 더 자주
놓치므로, 점수는 긴 랠리 끝에 패들 끝으로 각도를 꺾어 보낸 공에서 나온다. 먼저 7점을 낸 쪽이 이기고, `다시 하기`를
누르면 다음 경기가 시작되며, 남는 것은 전적(승, 패, 최장 랠리, 연승)뿐이다. 키보드나 게임패드로 하고, 언어는
한국어(원문)와 영어다.

| 입력 | 동작 |
|---|---|
| `W` / `↑`, 방향 패드 위 또는 왼쪽 스틱 위 | 누르는 동안 패들이 위로 이동 |
| `S` / `↓`, 방향 패드 아래 또는 왼쪽 스틱 아래 | 누르는 동안 패들이 아래로 이동 |
| `P` / `Esc`, 게임패드 `Start` / `B` | 경기 중 일시 정지 (`Esc`와 `B`는 다른 화면에서 뒤로) |
| 마우스 클릭, `Enter` / `Space`, 게임패드 `A` | UI 버튼 누르기 (`Enter`, `Space`, `A`는 포커스된 버튼) |

## 상태

개발하는 동안 macOS에서 플레이하며 확인했다. 출시용 빌드는 아직 없다. `build`를 한 번도 실행하지 않았다.

## AI로 고치기

`open-game-works-core/`에서 연 Claude Code나 Codex 세션에 아래 명령을 준다.

| 명령 | 하는 일 |
|---|---|
| `update game: open-game-works-game-pong <request>` | 사람의 피드백이나 고칠 PROD 문제를 받아 루프로 게임을 고친다 |
| `build: open-game-works-game-pong DEV` | 코드를 하드닝하고, macOS 앱을 `builds/`에 빌드하고, `dev-<version>` 태그를 붙이고, DEV 서버를 배포한다 |

`update game`에는 레퍼런스 플레이 영상이 필요한데, 영상은 저장소에 없다. 먼저 받아 오고(`yt-dlp` 필요), 저장된
`<video id>.mp4`의 이름을 [`reference.md`](records/setup/reference/reference.md)의 `## video`에 적힌 이름으로 바꾼다.

```sh
tools/bin/ogw game reference open-game-works-game-pong <reference.md의 YouTube URL>
```

### 첫 DEV 빌드 전에

- `settings.json`에는 시크릿 이름만 있다. `open-game-works-core/`에서
  `tools/bin/ogw secret generate open-game-works-game-pong DEV`를 실행하고, 배포 SSH 키나 `signing.macos`의 macOS
  서명 자료 같은 나머지는 `tools/bin/ogw secret set open-game-works-game-pong <DEV|signing> <name>`으로
  넣는다(값은 표준 입력).
- 새 호스트에서 `secret generate`는 새 업데이트 서명 공개 키를 `settings.json`의 `updatePublicKeys`에 더한다. 빌드
  전에 이 변경을 커밋한다.
- `settings.json`의 서버 URL, 배포 호스트와 호스트 키, 약관 문서 URL, CDN 값, 공증 ID는 자리 표시용 값(`.invalid`
  호스트, `PLACEHOLDER`)이다. 직접 쓸 값으로 바꾸고, `serverImage.repository`와 `appId`도 직접 관리하는 이미지
  저장소와 앱 ID로 바꾼다.
- macOS 앱은 Xcode 27이 있는 Apple silicon Mac에서 빌드한다.

## 만든 방식

경기는 Godot 클라이언트가 돌린다(공, 패들, CPU, 10ms마다 한 틱). 전적은 TypeScript 서버가 보관한다. 경기가 끝나면
`server/hooks/play_session.ts`가 점수와 최장 랠리를 검사하고 전적을 갱신한다. 게임플레이 값은
`data/system/game_setting.csv`의 행이다. 이 게임은 core `0.1.0`(`settings.json` `coreVersion`)을 고정한다.
`client/core/`와 `server/core/`는 [core 릴리스 v0.1.0](https://github.com/wnsrn3436/open-game-works-core-impl/releases/tag/v0.1.0)의
사본이고, 엔진 버전(Godot 4.7.2)도 그 릴리스가 정한다.

| 경로 | 내용 |
|---|---|
| [`brief.md`](brief.md) | 브리프: 플레이어 판타지, 감정, 레퍼런스 게임, 처음 받은 요청 |
| [`design.md`](design.md) | 디자인 문서: 코어 루프, 조작, 화면, 시스템, 튜닝, 아트와 오디오 |
| [`play-guide.md`](play-guide.md) | 플레이 에이전트와 판정 에이전트가 받는 가이드 |
| [`settings.json`](settings.json) | 게임 설정: core 버전과 모듈, 플랫폼, 언어, 환경별 값 |
| [`contract/`](contract) | protobuf contract: `service.proto`, `user_state.proto` |
| [`data/`](data) | CSV 테이블, `system/game_setting.csv`, 영어 번역, 용어집 |
| [`resource/`](resource) | 리소스 키별 리소스. [`resources.csv`](resource/resources.csv)에 전부 있음 |
| [`client/`](client) | Godot 프로젝트. content code는 `boot/`, `common/`, `features/` |
| [`server/`](server) | TypeScript 서버. 훅은 `hooks/play_session.ts` |
| [`records/`](records) | 작업 기록. 지금은 레퍼런스 게임 기록만 있음 |

[open-game-works](https://github.com/wnsrn3436/open-game-works-core) 하네스로 만들었다.

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
