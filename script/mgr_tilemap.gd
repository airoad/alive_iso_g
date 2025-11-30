extends Node2D

@onready var mgr_input = $"../Input"
@onready var mgr_ui = $"../UI"
@onready var root = $"."

var cur_layer: int = -1
var layers:Array = []
var wtmls: Dictionary[int,TileMapLayer] = {}
var vtmls: Dictionary[int,TileMapLayer] = {}
var area_start_cc:Vector2i = Vector2i.ZERO
var area_end_cc:Vector2i = Vector2i.ZERO


func _ready() -> void:
	mgr_input.connect("sgl_click", on_click)
	mgr_input.connect("sgl_drag", on_mouse_drag)
	mgr_ui.connect("sgl_ui_card_selected", on_ui_card_selected)
	layers = TMLUtils.prepare_vtmls(root)
	wtmls = layers[0]
	vtmls = layers[1]
	
func on_ui_card_selected(tid: int, _count: int) -> void:
	cur_layer = tid
	
func on_click(_wp: Vector2, control: String) -> void:
	if mgr_ui.mouse_on_ui:return
	if cur_layer == -1: return
	if control in ["just_middle","pressing_middle","just_released_middle"]:return
	var wcc = wtmls[cur_layer].local_to_map(get_local_mouse_position())
	handle_tile_data([wcc], control)

func on_mouse_drag(wp: Vector2, phase: String, control: String, shift: String) -> void:
	if mgr_ui.mouse_on_ui:return
	if cur_layer == -1: return
	if control in ["just_middle","pressing_middle","just_released_middle"]:return
	if phase == "dragging" and shift == "just_released_shift":
		var wcc = wtmls[cur_layer].local_to_map(get_local_mouse_position())
		handle_tile_data([wcc], control)
	if shift == "just_released_shift": return
	match phase:
		"start_dragging":
			if not control == "just_middle": 
				area_start_cc = wtmls[cur_layer].local_to_map(wp)
		"dragging":
			if not control == "pressing_middle": 
				area_end_cc = wtmls[cur_layer].local_to_map(wp)
		"end_dragging":
			if not control == "just_released_middle": 
				area_end_cc = wtmls[cur_layer].local_to_map(wp)
				var wccs:Array[Vector2i] = TMLUtils.get_all_cc_in_world_rect(area_start_cc,area_end_cc)
				handle_tile_data(wccs, control)

func handle_tile_data(wccs: Array[Vector2i], control: String) -> void:
	if wccs.is_empty(): return
	if cur_layer == -1 or not wtmls[cur_layer] or not vtmls[cur_layer] : return 
	if control in ["just_middle", "pressing_middle", "just_released_middle"]: return
	
	# 左键：wtml 刷 type id
	if control in ["pressing_left", "just_released_left"]:
		update_visual_cell(wccs,true)
	# 右键：wtml 刷 type id - 1 or 0
	elif control in ["pressing_right", "just_released_right"]:
		update_visual_cell(wccs,false)

func update_visual_cell(wccs: Array[Vector2i], is_add:bool = false) -> void:
	var nccs_dic = {}
	for wcc in wccs:
		#var ncc_sid_dic = {}
		var nccs = TMLUtils.get_8_neighbors(wcc)
		for ncc in nccs:
			var ncc_sid = wtmls[cur_layer].get_cell_source_id(ncc)
			if ncc_sid != -1:
				nccs_dic[ncc] = true

	for wcc in wccs:
		nccs_dic.erase(wcc)

	for wcc in wccs:
		if is_add:
			var ac = Vector2i.ZERO
			ac.y =  cur_layer
			wtmls[cur_layer].set_cell(wcc,0,ac,0)
		else:
			wtmls[cur_layer].erase_cell(wcc)

	for wcc in wccs:
		var vccs = TMLUtils.get_vcc_list(wcc)
		for vcc in vccs:
			if is_add:
				var ac = Vector2i.ZERO
				#ac.x = randi() % 2
				ac.y = TMLUtils.get_corner_state(vcc,wtmls[cur_layer])
				vtmls[cur_layer].set_cell(vcc,0,ac,0)
			else:
				vtmls[cur_layer].erase_cell(vcc)
	
	for wcc in nccs_dic:
		var vccs = TMLUtils.get_vcc_list(wcc)
		for vcc in vccs:
			var ac = Vector2i.ZERO
			#ac.x = randi() % 2
			ac.y = TMLUtils.get_corner_state(vcc,wtmls[cur_layer])
			vtmls[cur_layer].set_cell(vcc,0,ac,0)
