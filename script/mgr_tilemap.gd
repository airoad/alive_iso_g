extends Node2D

@onready var mgr_input = $"../Input"
@onready var mgr_ui = $"../UI"
@onready var wtml: TileMapLayer = $WTML
@onready var vtml: TileMapLayer = $VTML_Ground

var layer: int = -1
var tile: int = -1
var area_start_cc
var area_end_cc

func _ready() -> void:
	# 连接信号
	mgr_input.connect("sgl_click", on_click)
	mgr_input.connect("sgl_drag", on_mouse_drag)
	mgr_ui.connect("sgl_ui_card_selected", on_ui_card_selected)

func on_ui_card_selected(tid: int, _count: int) -> void:
	layer = tid
	print(layer)

func on_click(_wp: Vector2, control: String) -> void:
	if mgr_ui.mouse_on_ui:return
	var wcc = wtml.local_to_map(get_local_mouse_position())
	handle_tile_data([wcc], control)

func on_mouse_drag(wp: Vector2, phase: String, control: String, shift: String) -> void:
	if mgr_ui.mouse_on_ui:return
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
	layer = mgr_ui.cur_layer
	tile = mgr_ui.cur_tile

	if wccs.is_empty(): return
	if layer == -1 or tile == -1 or not wtml or not vtml : return 
	if control in ["just_middle", "pressing_middle", "just_released_middle"]: return
	
	# 左键：wtml 刷 type id
	if control in ["pressing_left", "just_released_left"]:
		update_visual_cell(wccs,0 if layer < 0 else layer, tile)
	# 右键：wtml 刷 type id - 1 or 0
	elif control in ["pressing_right", "just_released_right"]:
		update_visual_cell(wccs,layer - 1 if layer - 1 >= 0 else 0, tile)

func update_visual_cell(wccs: Array[Vector2i], layer_type:int = 0, tile_type:int = 0) -> void:
	var wcc_nccs_dic ={}
	for wcc in wccs:
		var ncc_sid_dic = {}
		var nccs = TMLUtils.get_8_neighbors(wcc)
		for ncc in nccs:
			var ncc_sid = wtml.get_cell_source_id(ncc)
			if ncc_sid != -1:
				ncc_sid_dic[ncc] = ncc_sid
		wcc_nccs_dic[wcc] = ncc_sid_dic
	print("0 ",wcc_nccs_dic.size())
	#for wcc in wcc_nccs_dic:
		#var ncc_dic = wcc_nccs_dic[wcc]
		#if ncc_dic.size() != 8 and layer != 0:wcc_nccs_dic.erase(wcc)
		#var ncc_sids = ncc_dic.values()
		#ncc_sids = NFunc.remove_duplicates_keep_order(ncc_sids)
		#if ncc_sids.size()>2:wcc_nccs_dic.erase(wcc)
		#for ncc_sid in ncc_sids:
			#if layer - ncc_sid > 1: wcc_nccs_dic.erase(wcc)
		#wtml.set_cell(wcc,layer_type,Vector2i.ZERO,0)
	
	for wcc in wcc_nccs_dic:
		wtml.set_cell(wcc,layer_type,Vector2i.ZERO,0)
		
	for wcc in wcc_nccs_dic:
		var vccs = TMLUtils.get_vcc_list(wcc)
		for vcc in vccs:
			var sid_ac_dic = TMLUtils.get_corner_state(vcc,wtml)
			var ac = Vector2i(tile_type,0)
			#ac.x = randi() % 2
			ac.y = sid_ac_dic["acy"]
			var sid = sid_ac_dic["sid"]
			vtml.set_cell(vcc,sid,ac,0)
		var nccs = wcc_nccs_dic[wcc]
		for ncc in nccs:
			var nvccs = TMLUtils.get_vcc_list(ncc)
			for nvcc in nvccs:
				var sid_ac_dic = TMLUtils.get_corner_state(nvcc,wtml)
				var ac = vtml.get_cell_atlas_coords(nvcc)
				#ac.x = randi() % 2
				ac.y = sid_ac_dic["acy"]
				var sid = sid_ac_dic["sid"]
				vtml.set_cell(nvcc,sid,ac,0)
