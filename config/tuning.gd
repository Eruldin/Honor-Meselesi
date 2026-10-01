class_name Tuning
extends Resource
## Tum oynanis sayilari burada — kodda sabit sayi yok (DEVIN_PLAN §8.4).
## config/tuning.tres tek instance; degistir, kaydet, hisset.

@export_group("Hareket")
@export var run_speed: float = 88.0          ## px/s
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
@export var dash_speed: float = 390.0         ## ~64px / 150ms
@export var dash_time: float = 0.15
@export var dash_cooldown: float = 0.35
@export var dash_iframes: bool = false        ## Golge formunda true

@export_group("Saldiri")
@export var attack_duration: float = 0.3     ## tek vurus suresi
@export var attack_active_start: float = 0.35 ## hitbox acilma (oran)
@export var attack_active_end: float = 0.7    ## hitbox kapanma (oran)
@export var combo_window: float = 0.4         ## sonraki kombo icin pencere
@export var air_attack_duration: float = 0.24
@export var down_attack_duration: float = 0.3
@export var player_damage: int = 1
@export var attack_knockback: float = 120.0
@export var attack_lunge: float = 38.0         ## vurusta ileri ivme px/s
@export var pogo_factor: float = 0.85         ## ziplama hizinin %85'i

@export_group("Parry")
@export var parry_window: float = 0.15        ## 150 ms — ogretilen mekanik, tolerans
@export var parry_recovery: float = 0.35      ## iskalama cezasi
@export var parry_stagger: float = 1.2        ## dusman sersemleme suresi

@export_group("Hasar / Can")
@export var hit_stagger: float = 0.22         ## vurusta dusman kesintisi (knockback_resist ile olceklenir)
@export var max_health: int = 5               ## "5 maske"
@export var hurt_invuln_time: float = 0.8
@export var hurt_knockback: float = 140.0
@export var hurt_stun_time: float = 0.3

@export_group("Prolog / CRT mini-oyun")
@export var crt_obstacle_speed: float = 52.0   ## engel kayma hizi px/s (viewport ici)
@export var crt_jump_velocity: float = 105.0
@export var crt_gravity: float = 380.0
@export var crt_spawn_interval: float = 1.5    ## engel uretim araligi
@export var prolog_min_play_time: float = 7.0  ## glitch'ten onceki min oyun suresi
@export var prolog_min_dodges: int = 3         ## glitch icin gerekli min atlatma

@export_group("Bolum 1 — dusmanlar")
@export var villager_speed: float = 30.0
@export var villager_aggro_range: float = 130.0
@export var guard_lunge_speed: float = 185.0
@export var guard_lunge_time: float = 0.3
@export var guard_telegraph: float = 0.4
@export var knight_speed: float = 21.0

@export_group("Bolum 1 — Lord Cluck")
@export var cluck_speed: float = 26.0
@export var cluck_p2_speed: float = 38.0
@export var cluck_slam_rise: float = 240.0
@export var cluck_slam_fall: float = 560.0
@export var cluck_telegraph: float = 0.45
@export var cluck_attack_gap: float = 0.9
@export var cluck_attack_gap_p2: float = 0.5
@export var egg_fuse: float = 2.4
@export var egg_blast_radius: float = 30.0
@export var egg_reflect_speed: float = 170.0
@export var egg_reflect_damage: int = 2
@export var shockwave_speed: float = 115.0
@export var shockwave_range: float = 70.0

@export_group("Bolum 2 — dusmanlar")
@export var ninja_speed: float = 75.0
@export var ninja_blink_dist: float = 46.0
@export var drone_fire_interval: float = 2.8
@export var guardian_speed: float = 15.0
@export var terminal_hack_time: float = 1.2   ## drone hack suresi

@export_group("Bolum 2 — Unit-0")
@export var unit0_hp_p1_speed: float = 28.0
@export var unit0_p2_speed: float = 42.0
@export var unit0_punch_speed: float = 320.0
@export var unit0_telegraph: float = 0.5
@export var unit0_attack_gap: float = 1.0
@export var unit0_attack_gap_p2: float = 0.6
@export var unit0_armor_break_time: float = 3.0  ## parry sonrasi acik pencere
@export var missile_speed: float = 105.0
@export var missile_turn: float = 2.2           ## rad/s hedefe donus

@export_group("Bolum 3 — dusmanlar")
@export var ghost_speed: float = 18.0
@export var ghost_reveal_time: float = 3.0    ## kivilcimla gorunur kalma
@export var ghost_reveal_radius: float = 70.0
@export var vampire_blink_cd: float = 2.0
@export var vampire_bleed_ticks: int = 3      ## DoT
@export var vampire_bleed_interval: float = 1.2
@export var werewolf_jump_speed: float = 215.0
@export var werewolf_telegraph: float = 0.5   ## kirmizi goz uyarisi

@export_group("Bolum 3 — Kont Vlad")
@export var vlad_speed: float = 32.0
@export var vlad_p2_speed: float = 46.0
@export var vlad_telegraph: float = 0.45
@export var vlad_attack_gap: float = 0.9
@export var vlad_attack_gap_p2: float = 0.55
@export var vlad_lunge_speed: float = 270.0
@export var blood_spike_delay: float = 0.7    ## zeminde belirme uyarisi

@export_group("Bolum 4 — dusmanlar/dekor")
@export var mushroom_speed: float = 24.0
@export var shell_speed: float = 200.0
@export var shell_life: float = 6.0
@export var flower_interval: float = 3.2
@export var cloud_tip_interval: float = 9.0

@export_group("Bolum 4 — Kizil Tulumlu Tiran")
@export var tyrant_speed: float = 34.0
@export var tyrant_p2_speed: float = 48.0
@export var tyrant_telegraph: float = 0.5
@export var tyrant_attack_gap: float = 1.0
@export var tyrant_attack_gap_p2: float = 0.6
@export var tyrant_pound_rise: float = 300.0
@export var pixel_rain_interval: float = 0.85
@export var gravity_flip_time: float = 4.0    ## yer cekimi ters kalma suresi

@export_group("Bolum 5 — Kul Diyari")
@export var husk_speed: float = 20.0
@export var husk_attack_range: float = 22.0
@export var husk_telegraph: float = 0.5
@export var ash_bat_speed: float = 26.0
@export var ash_bat_dive_speed: float = 95.0
@export var ash_geyser_delay: float = 0.9
@export_group("Bolum 5 — Kul Muhafizi")
@export var guardian5_speed: float = 16.0
@export var guardian5_p2_speed: float = 24.0
@export var guardian5_telegraph: float = 0.6
@export var guardian5_attack_gap: float = 1.4
@export var guardian5_attack_gap_p2: float = 0.9

@export_group("Efekt")
@export var hitstop_normal: float = 0.06
@export var hitstop_parry: float = 0.12
@export var shake_light: float = 1.5
@export var shake_heavy: float = 3.5
@export var shake_duration: float = 0.2
