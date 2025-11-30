extends Node2D

signal sgl_ui_card_selected(tid:int, card_count:int)

@onready var layer_container: GridContainer = $"../../CanvasLayer/Panel/ScrollContainer/GridContainer"
@onready var utml : TileMapLayer = $"../Tilemap/UITileMapLayer"
@onready var panel = $"../../CanvasLayer/Panel"
@onready var screen_area_frame = $"../../CanvasLayer/ScreenAreaFrame"
@onready var mgr_input = $"../Input"
@onready var camera = $"../Camera/Camera2D"

const cursor_normal: Texture2D = preload("res://image/cursor_normal.png")
const cursor_pan: Texture2D = preload("res://image/cursor_pan.png")
const card_scene: PackedScene = preload("res://scene/card.tscn")
const layer_scene: PackedScene = preload("uid://dri2pl81kls8a")

var icon_dic : Dictionary = {}
var selected_id : int = -1
var all_card : Array[Control] = []
var selected_card: Control = null 
var area_start_cc : Vector2i = Vector2i.ZERO
var area_start_wcc : Vector2i = Vector2i.ZERO
var area_end_wcc: Vector2i = Vector2i.ZERO
var mouse_on_ui:bool = false
var last_area_wcc_arr:Array[Vector2i] = []
var is_shift_dragging:bool = false
var cursor_texture = null 
var cursor_hotspot = 0
var icon_asset_dic = {}
var cur_layer = 0

func _ready() -> void:
	handle_icon_dic()
	panel.connect("mouse_in_out", on_mouse_in_out_panel)
	#mgr_input.connect("sgl_drag_screen", on_shift_drag_screen)
	mgr_input.connect("sgl_drag_screen", on_shift_drag_screen_world)

	
func _process(_delta: float) -> void:
	change_cursor(mgr_input.is_dragging)
	if not is_shift_dragging:
		update_cursor_pos()

func change_cursor(dragging:bool) -> void:
	match dragging:
		true:
			if cursor_pan:
				cursor_texture = cursor_pan 
				cursor_hotspot = Vector2(cursor_texture.get_size() / 2)
				Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW, cursor_hotspot)
		false:
			if cursor_normal:
				cursor_texture = cursor_normal 
				cursor_hotspot = Vector2(cursor_texture.get_size() / 2)
				Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW, cursor_hotspot)
				
func update_cursor_pos() -> void:
	var cc = utml.local_to_map(get_global_mouse_position())
	if mouse_on_ui or mgr_input.is_dragging or is_shift_dragging:
		utml.clear()
		return
	else :
		utml.clear()
		utml.set_cell(cc,0,Vector2i.ZERO,0)

func on_mouse_on_card(phase:bool)->void:
	mouse_on_ui = phase
	
func on_mouse_in_out_panel(phase:bool)->void:
	mouse_on_ui = phase

func handle_icon_dic() -> void:
	icon_dic = NFunc.scan_directory("res://tileset/visual_terrain/icon/", "png")
	if icon_dic.is_empty(): return
	clear_chiildren(layer_container)
	all_card.clear()
	
	for path in icon_dic:
		var tid:int = int(path.get_file().get_basename())
		var icon_instance:Texture2D = icon_dic[path]
		var card = card_scene.instantiate()
		card.tid = tid
		card.icon_texture = icon_instance
		
		## 连接卡片的选中信号
		card.connect("sgl_card_selected", on_card_selected)
		card.connect("sgl_mouse_on_card", on_mouse_on_card)
		layer_container.add_child(card)
		all_card.append(card)

# 卡片被点击选中时触发
func on_card_selected(tid:int, card:Control) -> void:
	selected_id = tid
	selected_card = card
	
	# 1. 取消所有卡片的选中状态
	for c in all_card:
		c.deselect_card()
		if c != card: 
			c.hide_marker()
	sgl_ui_card_selected.emit(selected_id, all_card.size())

func clear_chiildren(node : Node) -> void:
	for i in node.get_child_count():
		var c = node.get_child(0)
		node.remove_child(c)
		node.queue_free()

func on_shift_drag_screen(coord: Vector2i, phase : String, control: String, shift: String) -> void:
	if shift == "just_released_shift":
		screen_area_frame.visible = false
		screen_area_frame.size = Vector2.ZERO
		return
	match phase:
		"start_dragging":
			if not control == "just_middle": 
				area_start_cc = coord
				screen_area_frame.position = area_start_cc
				screen_area_frame.size = Vector2.ZERO
		"dragging":
			if not control == "pressing_middle": 
				screen_area_frame.visible = true
				var fsize = coord - area_start_cc
				var fscale = Vector2.ONE
				if fsize.x > 0 : fscale.x = 1
				else :
					fscale.x = -1
					fsize.x = abs(fsize.x) 
				if fsize.y > 0 : fscale.y = 1
				else : 
					fscale.y = -1
					fsize.y = abs(fsize.y)
				screen_area_frame.size = fsize
				screen_area_frame.scale = fscale
		"end_dragging":
			if not control == "just_released_middle": 
				screen_area_frame.visible = false
				screen_area_frame.size = Vector2.ZERO

func on_shift_drag_screen_world(_coord: Vector2i, phase : String, control: String, shift: String) -> void:
	if shift == "just_released_shift": 
		is_shift_dragging = false
		return
	var wcc = utml.local_to_map(get_global_mouse_position())
	match phase:
		"start_dragging":
			if not control == "just_middle": 
				area_start_wcc = wcc
		"dragging":
			if not control == "pressing_middle":
				area_end_wcc = wcc
				var temp_wcc_arr:Array[Vector2i] = TMLUtils.get_all_cc_in_world_rect(area_start_wcc,area_end_wcc)
				if temp_wcc_arr.size() != last_area_wcc_arr.size():
					last_area_wcc_arr = temp_wcc_arr
					utml.clear()
					var aid:int = 0
					if control in ["pressing_right","just_right"]: aid = 1
					for area_cc in last_area_wcc_arr:
						utml.set_cell(area_cc,0,Vector2i.ZERO,aid)
				is_shift_dragging = true
		"end_dragging":
			if not control == "just_released_middle": 
				area_end_wcc = wcc
				utml.clear()
				is_shift_dragging = false
