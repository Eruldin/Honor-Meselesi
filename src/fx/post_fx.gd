class_name PostFX
extends CanvasLayer
## CRT/glitch/RGB post-process katmani. Tam ekran ColorRect +
## screen-texture okuyan shader. Yogunluk Settings.fx_intensity ile
## oynanir; bolum bazli profil icin apply_profile() kullanilacak (M3+).

const SHADER_PATH := "res://src/fx/shaders/crt_glitch.gdshader"

var rect: ColorRect
var material: ShaderMaterial


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = ShaderMaterial.new()
	material.shader = load(SHADER_PATH)
	rect.material = material
	add_child(rect)
	apply_intensity(Settings.fx_intensity)
	Settings.changed.connect(func() -> void: apply_intensity(Settings.fx_intensity))
	EventBus.glitch_requested.connect(glitch_pulse)


## Glitch kanalini gecici olarak yukseltip geri indirir (cutscene darbesi).
func glitch_pulse(strength: float, duration: float = 0.6) -> void:
	if material == null:
		return
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	material.set_shader_parameter("glitch", strength)
	tw.tween_property(material, "shader_parameter/glitch", 0.12, duration)


func apply_intensity(v: float) -> void:
	if material != null:
		material.set_shader_parameter("master", v)
