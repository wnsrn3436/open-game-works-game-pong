import { randomUUID } from 'node:crypto';
import * as Testing from '../core/testing/dev/index.ts';
import * as CoreContract from '../generated/contract/core_contract.ts';
import * as GameContract from '../generated/contract/game_contract.ts';

const LOADED = Testing.load_data();
/** `[points_to_win]`, `[rally_max]` and the `[mode_cpu_match]` row of the data. */
const TARGET = LOADED.data.GameSetting.points_to_win();
const RALLY_MAX = LOADED.data.GameSetting.rally_max();
const MODE = LOADED.dev.find_id_value('[mode_cpu_match]');
const MIN_DURATION = LOADED.data.PlaySessionModeTable.get_row(MODE).min_duration;

function code(envelope: CoreContract.ResponseEnvelope): number {
  return envelope.error?.code ?? 0;
}

function result(player_score: number, cpu_score: number, longest_rally: number): Uint8Array {
  const out = new GameContract.PlaySessionResult();
  out.player_score = player_score;
  out.cpu_score = cpu_score;
  out.longest_rally = longest_rally;
  return out.encode();
}

async function start(session: Testing.TestSession): Promise<string> {
  const request = new CoreContract.StartPlaySessionRequest();
  request.mode_id = MODE;
  request.level_id = 0;
  const sent = await Testing.send(session, 'core/StartPlaySession', request);
  expect(code(sent.envelope)).toBe(0);
  return (sent.response as CoreContract.StartPlaySessionResponse).play_session_id;
}

function finish(session: Testing.TestSession, play_session_id: string, bytes: Uint8Array, request_id?: string): Promise<Testing.SendResult> {
  const request = new CoreContract.FinishPlaySessionRequest();
  request.play_session_id = play_session_id;
  request.result = bytes;
  return Testing.send(session, 'core/FinishPlaySession', request, request_id);
}

async function record(server: Testing.TestServer, user_id: bigint): Promise<GameContract.MatchRecordUserState | null> {
  const item = (await Testing.read_user_state(server, user_id)).find((entry) => entry.kind === 'MatchRecordUserState');
  return item === undefined ? null : (item.value as GameContract.MatchRecordUserState);
}

interface Record4 {
  wins: number;
  losses: number;
  best_rally: number;
  win_streak: number;
}

function plain(value: GameContract.MatchRecordUserState | null): Record4 | null {
  return value === null ? null : { wins: value.wins, losses: value.losses, best_rally: value.best_rally, win_streak: value.win_streak };
}

function delta_record(envelope: CoreContract.ResponseEnvelope): GameContract.MatchRecordUserState | null {
  const entry = envelope.user_state?.entries.find((e) => e.kind === 'MatchRecordUserState');
  return entry === undefined ? null : GameContract.MatchRecordUserState.decode(entry.value);
}

describe('CPU match play session', () => {
  let server: Testing.TestServer;
  let accounts = 0;

  beforeEach(async () => {
    server = await Testing.start_test_server();
  });

  afterEach(async () => {
    await Testing.stop_test_server(server);
  });

  async function player(): Promise<Testing.TestSession> {
    accounts += 1;
    return Testing.login(server, `match_${String(accounts)}`);
  }

  async function played(session: Testing.TestSession, bytes: Uint8Array, request_id?: string): Promise<Testing.SendResult> {
    const id = await start(session);
    Testing.advance_time(server, MIN_DURATION);
    return finish(session, id, bytes, request_id);
  }

  it('counts a won match as a win, starts a streak and keeps the longest rally', async () => {
    const session = await player();
    const sent = await played(session, result(TARGET, 3, 12));
    expect(code(sent.envelope)).toBe(0);
    const expected = { wins: 1, losses: 0, best_rally: 12, win_streak: 1 };
    expect(plain(delta_record(sent.envelope))).toEqual(expected);
    expect(plain(await record(server, session.user_id))).toEqual(expected);
  });

  it('counts a lost match as a loss, ends the streak and keeps the best rally of all matches', async () => {
    const session = await player();
    await played(session, result(TARGET, 0, 20));
    await played(session, result(TARGET, 5, 4));
    const sent = await played(session, result(2, TARGET, 9));
    expect(code(sent.envelope)).toBe(0);
    expect(plain(await record(server, session.user_id))).toEqual({ wins: 2, losses: 1, best_rally: 20, win_streak: 0 });
  });

  it('rejects a result without one winner at the target score and keeps the record', async () => {
    const session = await player();
    await played(session, result(TARGET, 1, 3));
    for (const bad of [result(TARGET, TARGET, 3), result(TARGET - 1, TARGET - 1, 3), result(TARGET + 1, 0, 3), result(0, TARGET + 1, 3)]) {
      const sent = await played(session, bad);
      expect(code(sent.envelope)).toBe(CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_REJECTED);
    }
    expect(plain(await record(server, session.user_id))).toEqual({ wins: 1, losses: 0, best_rally: 3, win_streak: 1 });
  });

  it('rejects a longest rally over the data limit', async () => {
    const session = await player();
    const over = await played(session, result(TARGET, 0, RALLY_MAX + 1));
    expect(code(over.envelope)).toBe(CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_REJECTED);
    expect(await record(server, session.user_id)).toBeNull();
    const at_limit = await played(session, result(TARGET, 0, RALLY_MAX));
    expect(code(at_limit.envelope)).toBe(0);
    expect((await record(server, session.user_id))?.best_rally).toBe(RALLY_MAX);
  });

  it('refuses a match that ends before the minimum duration and keeps the record', async () => {
    const session = await player();
    const id = await start(session);
    Testing.advance_time(server, MIN_DURATION - 1n);
    const sent = await finish(session, id, result(TARGET, 0, 3));
    expect(code(sent.envelope)).toBe(CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_TOO_FAST);
    expect(await record(server, session.user_id)).toBeNull();
  });

  it('refuses scores outside the field range without a hook call', async () => {
    const session = await player();
    const sent = await played(session, result(-1, TARGET, 3));
    expect(code(sent.envelope)).toBe(CoreContract.CoreError.CORE_ERROR_INVALID_REQUEST);
    expect(await record(server, session.user_id)).toBeNull();
  });

  it('answers a resent finish with the stored response and counts the match once', async () => {
    const session = await player();
    const id = await start(session);
    Testing.advance_time(server, MIN_DURATION);
    const request_id = randomUUID();
    const first = await finish(session, id, result(TARGET, 2, 5), request_id);
    const again = await finish(session, id, result(TARGET, 2, 5), request_id);
    expect(code(first.envelope)).toBe(0);
    expect(code(again.envelope)).toBe(0);
    expect(plain(await record(server, session.user_id))).toEqual({ wins: 1, losses: 0, best_rally: 5, win_streak: 1 });
  });

  it('counts one of two concurrent finishes of the same play session', async () => {
    const session = await player();
    const id = await start(session);
    Testing.advance_time(server, MIN_DURATION);
    const results = await Promise.all([finish(session, id, result(TARGET, 2, 5)), finish(session, id, result(TARGET, 2, 5))]);
    expect(results.map((r) => code(r.envelope)).sort()).toEqual([0, CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_NOT_FOUND].sort());
    expect(plain(await record(server, session.user_id))).toEqual({ wins: 1, losses: 0, best_rally: 5, win_streak: 1 });
  });
});
