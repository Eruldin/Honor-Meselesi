class_name FormData
extends Resource
## Bir formun tanimi (DEVIN_PLAN §4.2): form degisimi durumu degil
## VERI SETINI degistirir. Carpalar tuning.tres uzerinden uygulanir.

@export var id: StringName = &""
@export var display_name: String = ""
@export var sprite_asset: StringName = &""      ## gercek sprite id (orn. enemy/rooster); bos: player/<id>/idle
@export var sprite_color := Color.WHITE        ## sprite uzerine tint (golge icin koyu)
@export var body_size := Vector2(12, 18)       ## collision + sprite
@export var damage_mult := 1.0                 ## sovalye: agir kilic
@export var duration := 0.0                    ## >0: gecici form (sn); dolunca samuraya doner

@export_group("Hareket")
@export var run_speed_mult := 1.0
@export var jump_velocity_mult := 1.0
@export var gravity_mult := 1.0
@export var dash_iframes := false              ## golge/yarasa
@export var max_air_jumps := 0                 ## piksel sicramasi: 1

@export_group("Tavuk")
@export var can_glide := false                 ## kanat cirparak suzulme
@export var glide_gravity_mult := 0.22
@export var glide_fall_speed := 42.0

@export_group("Robot")
@export var can_break_ground := false          ## catlak zemin kirma
@export var knockback_resist := 0.0            ## 0..1

@export_group("Drone")
@export var can_hack := false                  ## guvenlik terminali hackleme
@export var hover_gravity_mult := 1.0          ## <1: yumusak dusus
