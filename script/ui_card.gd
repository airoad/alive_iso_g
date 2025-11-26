extends Control

@export var tid: int = 0
@export var icon_texture: Texture2D = null

signal sgl_card_selected(tid: int, card:Control)
signal sgl_mouse_on_card(on_card:bool)
var is_selected: bool = false  # 是否选中
var mouse_on_card : bool = false # 鼠标在上

@onready var icon: TextureRect = $icon
@onready var label: Label = $label
@onready var marker : NinePatchRect = $marker


func _ready() -> void:
	label.text = str(tid)
	set_icon_texture(icon_texture)
	connect("mouse_entered", on_mouse_entered)
	connect("mouse_exited", on_mouse_exited)

func on_mouse_entered() -> void:
	mouse_on_card = true
	sgl_mouse_on_card.emit(mouse_on_card)

func on_mouse_exited() -> void:
	mouse_on_card = false
	sgl_mouse_on_card.emit(mouse_on_card)

# 设置预览图
func set_icon_texture(texture: Texture2D) -> void:
	icon.texture = texture
	# 若没有预览图，用默认图标
	if not texture:
		icon.texture = preload("res://image//icon.svg")  # 替换为你的默认图标路径

# 鼠标点击事件（选中卡片）
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if mouse_on_card :
			select_card()

# 选中卡片（切换状态+发射信号）
func select_card() -> void:
	is_selected = true
	marker.visible = true
	sgl_card_selected.emit(tid, self)

# 取消选中（上层UI控制，用于切换选中时取消其他卡片）
func deselect_card() -> void:
	mouse_on_card = false
	is_selected = false

func hide_marker()->void:
	marker.visible = false
