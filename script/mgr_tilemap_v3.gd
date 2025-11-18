extends Node2D

@onready var mgr_input = $"../Input"
@onready var mgr_ui = $"../UI"
@onready var wtml: TileMapLayer = $WorldTileMapLayer
@onready var vtml_scene: PackedScene = preload("res://scene/visual_tilemap_layer_single_set.tscn")
@onready var tile_set_main = preload("res://tileset/single_set.tres")
@onready var tile_set_debug = preload("res://tileset/debug.tres")

var curr_sid: int = -1
var vtml: TileMapLayer = null
var area_start_cc
var area_end_cc
const SID_CAPACITY = 100

func _ready() -> void:
	# 连接信号
	mgr_input.connect("sgl_click", on_click)
	mgr_input.connect("sgl_drag", on_mouse_drag)
	mgr_ui.connect("sgl_ui_card_selected", on_ui_card_selected)
	# 创建显示层
	create_visual_tilmap_layer()

func create_visual_tilmap_layer() -> void:	
	if vtml == null:
		vtml = vtml_scene.instantiate()
		vtml.position.y = -8
		vtml.tile_set = tile_set_main
		wtml.add_child(vtml)

func on_ui_card_selected(sid: int, _count: int) -> void:
	curr_sid = sid

func on_click(_wp: Vector2, control: String) -> void:
	handle_tile_data(get_local_mouse_position(), control)

func on_mouse_drag(wp: Vector2, phase: String, control: String, shift: String) -> void:
	if phase == "dragging" and shift == "just_released_shift":
		handle_tile_data(get_local_mouse_position(), control)
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
				var wcc_arr = TilemapUtils.get_all_cc_in_rect(area_start_cc,area_end_cc)
				match control:
					"just_released_left":
						generate_area(wcc_arr)
					"just_released_right":
						remove_area_(wcc_arr)

func handle_tile_data(wp: Vector2, control: String) -> void:
	if curr_sid == -1 || vtml == null:
		return
	if control in ["just_middle", "pressing_middle", "just_released_middle"]:
		return
	var wcc = wtml.local_to_map(wp)
	# 左键：生成VC
	if control in ["just_left", "pressing_left"]:
		generate_visual_cells(wcc,curr_sid)
	# 右键：删除VC
	elif control in ["just_right", "pressing_right"]:
		remove_visual_cell(wcc)

# 生成VC
func generate_visual_cells(wcc: Vector2i, sid:int) -> void:
	var used_ncc_dic = TilemapUtils.get_used_neighbors(wcc,wtml)
	var used_ncc_sid_arr = used_ncc_dic.keys().map(func(ncc: Vector2i) -> int:return wtml.get_cell_source_id(ncc))
	used_ncc_sid_arr = NFunc.array_remove_duplicates_keep_order_first(used_ncc_sid_arr)
	var used_suround_ncc_dic = TilemapUtils.get_used_suround_neighbors(wcc,wtml)
	
	if used_ncc_sid_arr.is_empty():
		if sid == 0: 
			wtml.set_cell(wcc,sid,Vector2i.ZERO,0)
			update_visual_cell(wcc)
			return
		else:
			print("0")
			return
	elif used_ncc_sid_arr.size() == 1:
		var nsid = used_ncc_sid_arr[0]
		if sid == 0: 
			if nsid == sid :
				wtml.set_cell(wcc,sid,Vector2i.ZERO,0)
				update_visual_cell(wcc)
				return
			else:
				print("1")
				return
		else:
			if used_suround_ncc_dic.size() == 4:
				var nsid_str = str(nsid)[0]
				var sid_str = str(sid)[0]
				if int(nsid_str) == int(sid_str) - 1 or nsid == sid:
					wtml.set_cell(wcc,sid,Vector2i.ZERO,0)
					update_visual_cell(wcc)
					return
				else:
					print("2")
					return
	elif used_ncc_sid_arr.size() >= 2:
		for nsid in used_ncc_sid_arr:
			var nsid_str = str(nsid)[0]
			var sid_str = str(sid)[0]
			if nsid > sid or int(sid_str) - int(nsid_str) > 1:
				print("3")
				return
		for nsid in used_ncc_sid_arr:
			if used_suround_ncc_dic.size() == 4:
				if nsid <= sid - SID_CAPACITY:
					wtml.set_cell(wcc,sid,Vector2i.ZERO,0)
					update_visual_cell(wcc)
					return

# 删除VC
func remove_visual_cell(wcc: Vector2i, sid:int = curr_sid) -> void:
	if sid == 0: return
	var used_cell_arr = wtml.get_used_cells()
	if used_cell_arr.is_empty(): return
	var tmp_sid = wtml.get_cell_source_id(wcc)
	if not used_cell_arr.has(wcc): return
	if tmp_sid != sid: return
	var used_ncc_dic = TilemapUtils.get_used_neighbors(wcc,wtml)
	var used_ncc_sid_arr = used_ncc_dic.keys().map(func(ncc: Vector2i) -> int:return wtml.get_cell_source_id(ncc))
	if used_ncc_sid_arr.has(sid+1): return
	
	wtml.erase_cell(wcc)
	update_visual_cell(wcc,sid)

func generate_area(wcc_arr:Array,sid:int = curr_sid)->void:
	for wcc in wcc_arr:
		generate_visual_cells(wcc,sid)
		
func remove_area_(wcc_arr:Array)-> void:
	for wcc in wcc_arr:
		remove_visual_cell(wcc)
	
func update_visual_cell(wcc: Vector2i, sid:int = curr_sid) -> void:
	var is_add = wtml.get_used_cells().has(wcc)
	var vcc_arr = TilemapUtils.get_wcc_vcc_list(wcc)
	var aid = 0
	if is_add:
		var ac = Vector2i.ZERO
		ac.x = randi() % 2
		for vcc in vcc_arr:
			var tmp_sid = sid
			ac.y = TilemapUtils.get_vc_corner_state(vcc,wcc,tmp_sid,wtml)
			vtml.set_cell(vcc,tmp_sid,ac,aid)
		return
	
	var used_ncc_dic = TilemapUtils.get_used_neighbors(wcc,wtml)
	if sid != 0:
		wtml.set_cell(wcc,sid - SID_CAPACITY,Vector2i.ZERO,0)
	var used_nvcc = TilemapUtils.get_all_used_nvcc(used_ncc_dic)
	for vcc in vcc_arr:
		if not used_nvcc.has(vcc):
			vtml.erase_cell(vcc)
	for ncc in used_ncc_dic:
		var changed_ncc_corner_dic = TilemapUtils.get_neighbor_changed_corner(ncc,wcc)
		for idx in changed_ncc_corner_dic:
			var nvcc = TilemapUtils.get_vcc_coord(ncc,idx)
			var nvac = vtml.get_cell_atlas_coords(nvcc)
			var nvac_str = TilemapUtils.AC_STR_DIC[nvac.y]
			nvac_str[changed_ncc_corner_dic[idx]] = "0"
			nvac.y = TilemapUtils.STR_AC_DIC[nvac_str]
			vtml.set_cell(nvcc, sid, nvac, aid)
	for vcc in vtml.get_used_cells_by_id(sid):
		var vac = vtml.get_cell_atlas_coords(vcc)
		if vac.y == 15:
			vac.y = 14
			vtml.set_cell(vcc,sid - SID_CAPACITY,vac,aid)
