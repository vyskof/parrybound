class_name ParryResolver extends Node

enum Result {
	NONE,      ## Žádný aktivní parry pokus (výchozí stav)
	DEFLECT,   ## Perfect timing = Sekiro "deflect" (dřív PERFECT)
	BLOCK,     ## Držíš blok nebo pozdní timing
}

@export var deflect_window: float  = 0.18
@export var spam_decay_time: float  = 2.0
@export var spam_max_count: int   = 3

var _is_deflect_active: bool = false
var _is_blocking: bool = false
var _deflect_timer: float = 0.0
var _spam_count: int   = 0
var _spam_decay_timer: float = 0.0


var base_deflect_window: float:
	get: return deflect_window

func try_start_deflect() -> void:
	_is_deflect_active = true
	_is_blocking = true
	_deflect_timer = 0.0
	_spam_decay_timer = 0.0

func start_block() -> void:
	_is_blocking = true

func stop_block() -> void:
	_is_deflect_active = false
	_is_blocking       = false
	_deflect_timer     = 0.0

func tick(delta: float) -> void:
	if not _is_blocking and _spam_count > 0:
		_spam_decay_timer += delta
		if _spam_decay_timer >= spam_decay_time:
			_spam_count       = 0
			_spam_decay_timer = 0.0
	if not _is_deflect_active:
		return
	_deflect_timer += delta
	if _deflect_timer >= _current_deflect_window:
		_is_deflect_active = false

var _current_deflect_window: float:
	get:
		match _spam_count:
			0, 1: return deflect_window
			2:    return deflect_window * 0.6
			_:    return deflect_window * 0.3


func evaluate(combat_data: CombatData) -> Result:
	if _is_deflect_active:
		_spam_count       = 0  
		_spam_decay_timer = 0.0
		_is_deflect_active = false
		return Result.DEFLECT

	if _is_blocking:
		_spam_count = mini(_spam_count + 1, spam_max_count)
		return Result.BLOCK
	return Result.NONE

func is_blocking() -> bool:
	return _is_blocking

func is_deflect_active() -> bool:
	return _is_deflect_active

func get_spam_count() -> int:
	return _spam_count
