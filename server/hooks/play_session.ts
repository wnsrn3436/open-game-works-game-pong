import type { ApplyHook, PlaySessionRecord, VerifyHook } from '../core/play-session/index.ts';
import type { RequestCtx, StorageContent } from '../core/storage/index.ts';
import * as GameContract from '../generated/contract/game_contract.ts';

/**
 * `verify_play_session`: a finished match has exactly one winner with `[points_to_win]` points, a loser below it, and a
 * longest rally of at most `[rally_max]` paddle hits. The result is not recalculated; it only counts in the record.
 */
export const verify_match_result: VerifyHook = (ctx: RequestCtx, _record: PlaySessionRecord, result: Uint8Array) => {
  const decoded = GameContract.PlaySessionResult.decode(result);
  if (decoded === null) return 'reject';
  const target = ctx.data.GameSetting.points_to_win();
  const player_won = decoded.player_score === target && decoded.cpu_score < target;
  const cpu_won = decoded.cpu_score === target && decoded.player_score < target;
  if (!player_won && !cpu_won) return 'reject';
  if (decoded.longest_rally > ctx.data.GameSetting.rally_max()) return 'reject';
  return 'pass';
};

/**
 * `apply_play_session`: counts the verified match in `MatchRecordUserState`: a win or a loss, the win streak, and the
 * best rally. `FinishPlaySession` runs this once per play session.
 */
export function apply_match_result(storage: StorageContent): ApplyHook {
  return (ctx: RequestCtx, _record: PlaySessionRecord, result: Uint8Array) => {
    const decoded = GameContract.PlaySessionResult.decode(result);
    if (decoded === null) return GameContract.GameError.GAME_ERROR_UNSPECIFIED;
    const stored = storage.get_state(ctx, GameContract.MatchRecordUserState, 0n) as GameContract.MatchRecordUserState | null;
    const next = new GameContract.MatchRecordUserState();
    next.wins = stored?.wins ?? 0;
    next.losses = stored?.losses ?? 0;
    next.best_rally = Math.max(stored?.best_rally ?? 0, decoded.longest_rally);
    if (decoded.player_score > decoded.cpu_score) {
      next.wins += 1;
      next.win_streak = (stored?.win_streak ?? 0) + 1;
    } else {
      next.losses += 1;
      next.win_streak = 0;
    }
    storage.put_state(ctx, next);
    return 'pass';
  };
}
