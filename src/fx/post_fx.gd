class_name PostFX
extends CanvasLayer
## CRT/glitch/RGB post-process katmani. Tam ekran ColorRect +
## screen-texture okuyan shader. Normal oynanista master her zaman 0 —
## efekt yalnizca senaryo anlarinda glitch_pulse ile kisaca acilir.
## Settings.fx_intensity puls gucluluk carpani olarak kullanilir
## (0 = sinematik glitch'ler de kapali).

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
	apply_intensity(0.0)
	EventBus.glitch_requested.connect(glitch_pulse)


## Glitch kanalini gecici olarak yukseltip geri indirir (cutscene darbesi).
## master ayari da kisa sureligine yukselir — shader etkileri master'a bagli.
## Taban her zaman 0: oyun sirasinda asla ortam glitch'i olmaz.
func glitch_pulse(strength: float, duration: float = 0.6) -> void:
	if material == null or Settings.fx_intensity <= 0.0:
		return
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	material.set_shader_parameter("master", 1.0)
	material.set_shader_parameter("glitch", strength * Settings.fx_intensity)
	tw.parallel().tween_property(material, "shader_parameter/glitch", 0.12, duration)
	tw.parallel().tween_property(material, "shader_parameter/master", 0.0, duration)


func apply_intensity(v: float) -> void:
	if material != null:
		material.set_shader_parameter("master", v)
