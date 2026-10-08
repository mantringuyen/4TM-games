class_name RewardedAdInterface
extends RefCounted

## RewardedAdInterface — Full-screen rewarded advertisement lifecycle & session controller.
## Supports:
##   1. Energy +1 rewarded ads ("energy")
##   2. Special item daily +1 rewarded ads ("bomb", "change_block", "extra_life")
##   3. Game Over watch-ad rescue ("revive")
## Enforces:
##   - Reward is granted ONLY when the ad completes successfully.
##   - Skipping or closing the ad before completion grants 0 reward.
##   - One ad session can NEVER grant multiple rewards.

signal ad_loaded()
signal ad_failed_to_load(error_code: int, message: String)
signal ad_opened()
signal ad_closed()
signal ad_skipped(placement: String)
signal user_earned_reward(reward_type: String, amount: int)

var is_loaded: bool = true
var is_showing: bool = false
var is_fullscreen: bool = true
var active_placement: String = ""
var active_session_id: String = ""
var ad_completed: bool = false
var ad_skipped_early: bool = false
var reward_claimed_for_session: bool = false
var _session_counter: int = 0
var _completed_sessions: Dictionary = {}


## Checks if a rewarded advertisement is ready to display
func is_ad_available() -> bool:
	return is_loaded


## Requests loading a rewarded ad unit
func load_rewarded_ad(_ad_unit_id: String = "") -> void:
	is_loaded = true
	ad_loaded.emit()


## Opens a full-screen rewarded ad session without immediately completing it,
## allowing interactive or test-driven completion vs early skip/close.
func open_fullscreen_ad(reward_placement: String = "energy") -> String:
	if not is_loaded:
		load_rewarded_ad(reward_placement)
	_session_counter += 1
	active_placement = reward_placement
	active_session_id = "%s_session_%d" % [reward_placement, _session_counter]
	is_showing = true
	is_fullscreen = true
	ad_completed = false
	ad_skipped_early = false
	reward_claimed_for_session = false
	ad_opened.emit()
	return active_session_id


## Completes the currently open full-screen rewarded ad and emits the reward once.
func complete_fullscreen_ad(expected_session_id: String = "") -> Dictionary:
	var sid: String = expected_session_id if expected_session_id != "" else active_session_id
	if sid == "" or _completed_sessions.has(sid):
		return {
			"completed": false,
			"reward_granted": false,
			"reason": "duplicate_or_invalid_session",
			"session_id": sid
		}
	if not is_showing or ad_skipped_early or reward_claimed_for_session:
		return {
			"completed": false,
			"reward_granted": false,
			"reason": "ad_not_active_or_skipped",
			"session_id": sid
		}
	is_showing = false
	ad_completed = true
	reward_claimed_for_session = true
	_completed_sessions[sid] = true
	var r_type: String = "revive_continue" if active_placement == "revive" else active_placement
	user_earned_reward.emit(r_type, 1)
	ad_closed.emit()
	return {
		"completed": true,
		"reward_granted": true,
		"reward_type": r_type,
		"placement": active_placement,
		"amount": 1,
		"session_id": sid
	}


## Skips or closes the full-screen rewarded ad before completion (grants 0 reward).
func skip_or_close_fullscreen_ad() -> Dictionary:
	if not is_showing:
		return {
			"completed": false,
			"reward_granted": false,
			"skipped": true,
			"session_id": active_session_id
		}
	is_showing = false
	ad_completed = false
	ad_skipped_early = true
	ad_skipped.emit(active_placement)
	ad_closed.emit()
	return {
		"completed": false,
		"reward_granted": false,
		"skipped": true,
		"placement": active_placement,
		"amount": 0,
		"session_id": active_session_id
	}


## Displays and completes the rewarded ad synchronously when auto_complete is true
func show_rewarded_ad(reward_placement: String = "revive", auto_complete: bool = true) -> Dictionary:
	if not is_loaded:
		ad_failed_to_load.emit(404, "Ad not loaded")
		return {"completed": false, "reward_granted": false, "reason": "not_loaded"}
	var sid := open_fullscreen_ad(reward_placement)
	if auto_complete:
		var res := complete_fullscreen_ad(sid)
		if reward_placement == "revive":
			is_loaded = false
		return res
	return {
		"completed": false,
		"reward_granted": false,
		"is_showing": true,
		"placement": reward_placement,
		"session_id": sid
	}

