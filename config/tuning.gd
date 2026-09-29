class_name Tuning
extends Resource
## Tum oynanis sayilari burada — kodda sabit sayi yok (DEVIN_PLAN §8.4).
## config/tuning.tres tek instance; degistir, kaydet, hisset.

@export_group("Hareket")
@export var run_speed: float = 110.0          ## px/s
@export var ground_accel: float = 900.0
@export var ground_decel: float = 1200.0
@export var air_accel: float = 550.0
@export var gravity: float = 800.0
@export var max_fall_speed: float = 320.0
@export var jump_velocity: float = 300.0      ## ~56px ziplama (g=800)
@export var jump_cut_multiplier: float = 0.45 ## erken birakmada vy *= bu
@export var coyote_time: float = 0.09         ## 90 ms
@export var jump_buffer_time: float = 0.11    ## 110 ms

@export_group("Dash")
@export var dash_speed: float = 430.0         ## ~64px / 150ms
@export var dash_time: float = 0.15
@export var dash_cooldown: float = 0.35
@export var dash_iframes: bool = false        ## Golge formunda true

@export_group("Saldiri")
@export var attack_duration: float = 0.26     ## tek vurus suresi
@export var attack_active_start: float = 0.35 ## hitbox acilma (oran)
@export var attack_active_end: float = 0.7    ## hitbox kapanma (oran)
@export var combo_window: float = 0.4         ## sonraki kombo icin pencere
@export var air_attack_duration: float = 0.24
@export var down_attack_duration: float = 0.3
@export var player_damage: int = 1
@export var attack_knockback: float = 120.0
@export var pogo_factor: float = 0.85         ## ziplama hizinin %85'i

@export_group("Parry")
@export var parry_window: float = 0.12        ## 120 ms
@export var parry_recovery: float = 0.35      ## iskalama cezasi
@export var parry_stagger: float = 1.2        ## dusman sersemleme suresi

@export_group("Hasar / Can")
@export var max_health: int = 5               ## "5 maske"
@export var hurt_invuln_time: float = 0.8
@export var hurt_knockback: float = 140.0
@export var hurt_stun_time: float = 0.3

@export_group("Prolog / CRT mini-oyun")
@export var crt_obstacle_speed: float = 60.0   ## engel kayma hizi px/s (viewport ici)
@export var crt_jump_velocity: float = 105.0
@export var crt_gravity: float = 380.0
@export var crt_spawn_interval: float = 1.5    ## engel uretim araligi
@export var prolog_min_play_time: float = 7.0  ## glitch'ten onceki min oyun suresi
@export var prolog_min_dodges: int = 3         ## glitch icin gerekli min atlatma

@export_group("Bolum 1 — dusmanlar")
@export var villager_speed: float = 42.0
@export var villager_aggro_range: float = 130.0
@export var guard_lunge_speed: float = 220.0
@export var guard_lunge_time: float = 0.3
@export var guard_telegraph: float = 0.4
@export var knight_speed: float = 26.0
@export var sovalye_duration: float = 25.0    ## gecici sovalye formu suresi

@export_group("Bolum 1 — Lord Cluck")
@export var cluck_speed: float = 30.0
@export var cluck_p2_speed: float = 46.0
@export var cluck_slam_rise: float = 240.0
@export var cluck_slam_fall: float = 560.0
@export var cluck_telegraph: float = 0.45
@export var cluck_attack_gap: float = 0.9
@export var cluck_attack_gap_p2: float = 0.5
@export var egg_fuse: float = 2.4
@export var egg_blast_radius: float = 30.0
@export var egg_reflect_speed: float = 200.0
@export var egg_reflect_damage: int = 2
@export var shockwave_speed: float = 140.0
@export var shockwave_range: float = 70.0

@export_group("Efekt")
@export var hitstop_normal: float = 0.06
@export var hitstop_parry: float = 0.12
@export var shake_light: float = 1.5
@export var shake_heavy: float = 3.5
@export var shake_duration: float = 0.2
