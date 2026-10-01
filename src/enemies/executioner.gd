class_name Executioner
extends Villager
## Undead Executioner (DarkPixel-Kronovi) — undead mini-boss: kripta
## bolgesinin agir elit gozcusu. Yavas ama cok sert; icadi agir, temasi
## 2 hasar, sendeleme direncli. Cani yaridan azalinca arada golemcik
## cagirir (en fazla 2 canli).

const SUMMON_CD := 7.0
const SUMMON_CAP := 2

var _summon_t := 5.0   # ilk cagri biraz gecikmeli


func _init() -> void:
	super._init()
	max_hp = 12
	body_size = Vector2(30, 42)
	asset_key = &"executioner"
	speed_override = 20.0
	knockback_resist = 0.7
	aggro_sfx = &"sfx/parry"
	aggro_db = -6.0
	aggro_pitch = 0.85


func _ready() -> void:
	super._ready()
	contact_hitbox.activate(DamageInfo.make(2, self, Vector2.ZERO, true, true))


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not health.is_alive() or is_staggered():
		return
	if health.current > max_hp / 2:
		return
	_summon_t -= delta
	if _summon_t > 0.0:
		return
	_summon_t = SUMMON_CD
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player")
	if _player == null:
		return
	if absf(_player.global_position.x - global_position.x) > 140.0:
		return
	if get_tree().get_nodes_in_group(&"summonling").size() >= SUMMON_CAP:
		return
	_summon()


func _summon() -> void:
	stagger_timer = 1.1
	play_anim(&"summon", 0.4)
	await get_tree().create_timer(0.55).timeout
	if not health.is_alive():
		return
	for dx in [-22.0, 22.0]:
		if get_tree().get_nodes_in_group(&"summonling").size() >= SUMMON_CAP:
			break
		var s := Summonling.new()
		s.global_position = global_position + Vector2(dx, 8.0)
		get_parent().add_child(s)
