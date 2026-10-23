extends UnitTestCase
## The finish of a match: a play session the server can no longer count is answered by the match itself (the result
## panel says it was not counted) instead of the core error popup; other failures keep the core handling.


func failure_of(kind: NetworkCore.FailureKind, error_code: int) -> RequestFailure:
	var failure: RequestFailure = RequestFailure.new()
	failure.kind = kind
	failure.error_code = error_code
	failure.request_name = "core/FinishPlaySession"
	return failure


func test_an_expired_or_unknown_play_session_is_answered_by_the_match() -> void:
	var server: NetworkCore.FailureKind = NetworkCore.FailureKind.SERVER_ERROR
	assert_true(MatchScene.is_uncounted(failure_of(server, CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_EXPIRED)), "expired")
	assert_true(MatchScene.is_uncounted(failure_of(server, CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_NOT_FOUND)), "not found")


func test_other_failures_keep_the_core_handling() -> void:
	assert_false(MatchScene.is_uncounted(failure_of(NetworkCore.FailureKind.CONNECTION_FAILED, 0)), "connection failed")
	assert_false(MatchScene.is_uncounted(failure_of(NetworkCore.FailureKind.SERVER_ERROR,
		CoreContract.CoreError.CORE_ERROR_INVALID_REQUEST)), "invalid request")
