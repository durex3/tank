extends Resource
class_name SkillFlipbookStyle

@export var frame_ticks: int = 3
@export var max_clips: int = 40
@export var trail_interval: int = 5
@export var reload_interval: int = 16
@export var lightning_width: float = 1.3
@export var armor_width: float = 0.8
@export var dust_width: float = 1.1
@export var reload_width: float = 0.65

@export var energy_hit_width: float = 1.7
@export var energy_hit_tint: Color = Color(0.68,0.20,0.23,0.95)
@export var hit_flash_ticks: int = 8
@export var hit_flash_color: Color = Color(0.55,0.035,0.06,0.55)
@export var hit_camera_offset: float = 0.35

@export var storm_hit_width: float = 0.75
@export var storm_hit_interval: int = 6
@export var storm_flash_ticks: int = 3
@export var storm_flash_color: Color = Color(0.8,0.23,0.045,0.35)
