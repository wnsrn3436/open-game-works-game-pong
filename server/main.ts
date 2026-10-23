import type { ApplyHook, VerifyHook } from './core/play-session/index.ts';
import type { StorageContent } from './core/storage/index.ts';
import { apply_match_result, verify_match_result } from './hooks/play_session.ts';

/** The `core` object of `register`: the module objects this content uses. */
export interface RegisterCore {
  readonly routing: {
    register_hook(module: 'play-session', hook: 'verify_play_session', fn: VerifyHook): void;
    register_hook(module: 'play-session', hook: 'apply_play_session', fn: ApplyHook): void;
  };
  readonly storage: StorageContent;
}

/**
 * Registers the play-session hooks of the CPU match. The game has no `service Game` `rpc`: a match starts with the core
 * `StartPlaySession` and ends with the core `FinishPlaySession`, whose hooks check the result and count it in the record.
 */
export function register(core: RegisterCore): void {
  core.routing.register_hook('play-session', 'verify_play_session', verify_match_result);
  core.routing.register_hook('play-session', 'apply_play_session', apply_match_result(core.storage));
}
