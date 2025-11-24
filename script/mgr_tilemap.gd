extends Node2D

@onready var mgr_input = $"../Input"
@onready var mgr_ui = $"../UI"
@onready var wtml: TileMapLayer = $WorldTileMapLayer
@onready var vtml: TileMapLayer = $VisualTileMapLayer

var cur_sid: int = -1
var area_start_cc
var area_end_cc

func _ready() -> void:
	# 连接信号
	mgr_input.connect("sgl_click", on_click)
	mgr_input.connect("sgl_drag", on_mouse_drag)
	mgr_ui.connect("sgl_ui_card_selected", on_ui_card_selected)

func on_ui_card_selected(sid: int, _count: int) -> void:
	cur_sid = sid

func on_click(_wp: Vector2, control: String) -> void:
	var wcc = wtml.local_to_map(get_local_mouse_position())
	handle_tile_data([wcc], control)

func on_mouse_drag(wp: Vector2, phase: String, control: String, shift: String) -> void:
	if phase == "dragging" and shift == "just_released_shift":
		var wcc = wtml.local_to_map(get_local_mouse_position())
		handle_tile_data([wcc], control)
	if shift == "just_released_shift": return
	match phase:
		"start_dragging":
			if not control == "just_middle": 
				area_start_cc = wtml.local_to_map(wp)
		"dragging":
			if not control == "pressing_middle": 
				area_end_cc = wtml.local_to_map(wp)
		"end_dragging":
			if not control == "just_released_middle": 
				area_end_cc = wtml.local_to_map(wp)
				var wccs:Array[Vector2i] = TMLUtils.get_all_cc_in_world_rect(area_start_cc,area_end_cc)
				handle_tile_data(wccs, control)

func handle_tile_data(wccs: Array[Vector2i], control: String) -> void:
	if wccs.is_empty(): return
	if cur_sid == -1 or not wtml or not vtml : return 
	if control in ["just_middle", "pressing_middle", "just_released_middle"]: return
	
	# 左键：wtml 刷1
	if control in ["pressing_left", "just_released_left"]:
		update_visual_cell(wccs,1)
	# 右键：wtml 刷0
	elif control in ["pressing_right", "just_released_right"]:
		update_visual_cell(wccs,0)

func update_visual_cell(wccs: Array[Vector2i], cell_type:int = 0) -> void:
	for wcc in wccs:
		wtml.set_cell(wcc,cell_type,Vector2i.ZERO,0)
	
	for wcc in wccs:
		var vccs = TMLUtils.get_vcc_list(wcc)
		for vcc in vccs:
			var ac = Vector2i.ZERO
			#ac.x = randi() % 2
			ac.y = TMLUtils.get_corner_state(vcc,wtml)
			vtml.set_cell(vcc,cur_sid,ac,0)
