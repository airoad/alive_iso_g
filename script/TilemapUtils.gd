class_name TilemapUtils
extends RefCounted

# ======================================
# 核心常量（集中管理，避免重复创建）
# ======================================
# 8向邻居偏移（含斜向）
const NEIGHBOR_OFFSET_8DIR: Array[Vector2i] = [
	Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1),
	Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1)
]

const NEIGHBOR_OFFSET_8DIR_MAP: Dictionary[Vector2i,int] = {
	Vector2i(1, -1):0, Vector2i(1, 0):1, Vector2i(1, 1):2, Vector2i(0, 1):3,
	Vector2i(-1, 1):4, Vector2i(-1, 0):5, Vector2i(-1, -1):6, Vector2i(0, -1):7
}

const OFFSET_8DIR_CENTER: Array[Vector2i] = [
	Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1),
	Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1),
	Vector2i(0, 0),
]

# 4向邻居偏移（正向）
const NEIGHBOR_OFFSET_4DIR: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)
]

const CORNER_IDX_DIC:Dictionary ={
	0:[0,1,8,7],
	1:[1,2,3,8],
	2:[8,3,4,5],
	3:[7,8,5,6],
}

const NCC_ARRAY_SIZE: int = 8
const INVALID_WCC: Vector2i = Vector2i(-1, -1)
# VC位置索引映射（0=上，1=右，2=下，3=左）
const VCC_POS_OFFSET_MAP: Dictionary = {
	Vector2i(0, 0): 0,
	Vector2i(0, 1): 1,
	Vector2i(-1, 1): 2,
	Vector2i(-1, 0): 3
}
# VC位置反向映射（index→coord）
const VCC_OFFSET_INDEX_MAP: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0)
]

const STR_AC_DIC:Dictionary = {
 	"0010": 0, "0001": 1, "1000": 2, "0100": 3, 
	"0110": 4, "1001": 5, "0011": 6, "1100": 7, 
	"0111": 8, "1011": 9, "1101": 10,"1110": 11,
	"0101": 12,"1010": 13,"1111": 14, "0000": 15, 
}

const AC_STR_DIC:Dictionary = {
 	0 :"0010", 1 :"0001", 2 :"1000", 3 :"0100", 
	4 :"0110", 5 :"1001", 6 :"0011", 7 :"1100",  
	8 :"0111", 9 :"1011", 10:"1101", 11:"1110",
	12:"0101", 13:"1010", 14:"1111", 15:"0000", 
}


static func get_vcc_idx_dic(wcc:Vector2i)->Dictionary:
	var dic: Dictionary = {}
	for offset in VCC_POS_OFFSET_MAP:
		var vcc = wcc + offset
		dic[vcc] = VCC_POS_OFFSET_MAP[offset]
	return dic

static func get_idx_vcc_dic(wcc:Vector2i)->Dictionary:
	var dic: Dictionary = {}
	for i in VCC_POS_OFFSET_MAP.size():
		var offset = VCC_POS_OFFSET_MAP[i]
		var vcc = wcc + offset
		dic[i] = vcc
	return dic 

# 通过VC坐标获取位置索引（0-3，O(1)查询 -1 不存在）
static func get_vcc_index(vcc: Vector2i, wcc: Vector2i) -> int:
	var coord = vcc - wcc 
	return VCC_POS_OFFSET_MAP.get(coord, -1)

# 通过索引获取VC坐标（O(1)查询）
static func get_vcc_coord(wcc: Vector2i, index: int) -> Vector2i:
	if index < 0 or index >= VCC_OFFSET_INDEX_MAP.size():
		return Vector2i.ZERO
	return wcc + VCC_OFFSET_INDEX_MAP[index]

# 获取WCC对应的所有VC坐标（直接返回列表，避免业务层遍历）
static func get_wcc_vcc_list(wcc: Vector2i) -> Array:
	return get_vcc_idx_dic(wcc).keys()


static func get_direction_mapping() -> Dictionary:
	return {
		Vector2i(-1, 0):  [ [2, 3], [1, 0] ],
		Vector2i(1, 0):   [ [0, 1], [3, 2] ],
		Vector2i(0, -1):  [ [0, 3], [1, 2] ],
		Vector2i(0, 1):   [ [1, 2], [0, 3] ]
	}
	
static func get_all_cc_in_rect(start: Vector2i, end: Vector2i) -> Array:
	var cc = []
	# 计算对角cell的s和t（x-y和x+y）
	var s1 = start.x - start.y
	var t1 = start.x + start.y
	var s2 = end.x - end.y
	var t2 = end.x + end.y
	
	# 严格使用对角cell的s-t范围，不扩展
	var s_min = min(s1, s2)
	var s_max = max(s1, s2)
	var t_min = min(t1, t2)
	var t_max = max(t1, t2)
	
	# 遍历范围内的s和t，只保留整数x,y的cell
	for s in range(s_min, s_max + 1):
		for t in range(t_min, t_max + 1):
			# 确保x和y是整数（s和t同奇偶）
			if (s + t) % 2 != 0:
				continue
			var x = int((s + t) / 2.0)
			var y = int((t - s) / 2.0)
			cc.append(Vector2i(x, y))
	return cc

# isometric 中，get_suround_cells 得到的是4方向邻居故不采用 key:ncc value:ncc pos index (0-7)
static func get_used_neighbors(cc: Vector2i, tml:TileMapLayer,is_used:bool = true) -> Dictionary:
	var out: Dictionary = {}
	for i in NEIGHBOR_OFFSET_8DIR.size():
		var offset = NEIGHBOR_OFFSET_8DIR[i]
		var ncc = cc + offset
		if is_used:
			if tml.get_used_cells().has(ncc):
				out.set(ncc,i)
		else:out.set(ncc,i)
	return out

static func get_used_neighbors_with_sid(cc: Vector2i, tml:TileMapLayer) -> Dictionary:
	var out: Dictionary = {}
	for i in NEIGHBOR_OFFSET_8DIR.size():
		var offset = NEIGHBOR_OFFSET_8DIR[i]
		var ncc = cc + offset
		if tml.get_used_cells().has(ncc):
			var sid = tml.get_cell_source_id(ncc)
			out.set(ncc,sid)
	return out


# get surounding cell 的顺序是下左上右 故不采用
static func get_used_suround_neighbors(cc: Vector2i, tml:TileMapLayer)-> Dictionary:
	var out: Dictionary = {}
	for i in NEIGHBOR_OFFSET_4DIR.size():
		var offset = NEIGHBOR_OFFSET_4DIR[i]
		var ncc = cc + offset
		if tml.get_used_cells().has(ncc):
			out.set(ncc,i)
	return out

static func get_vc_corner_state(
	vcc:Vector2i,wcc:Vector2i,sid:int,wtml:TileMapLayer,use_sid:bool = true
)->int:
	var idx = get_vcc_index(vcc,wcc)
	var corner_idx_arr = CORNER_IDX_DIC[idx]
	var corner_arr =[]
	var corner_offset_arr = []
	for offset_idx in corner_idx_arr: 
		corner_offset_arr.append(OFFSET_8DIR_CENTER[offset_idx])
	for offset in corner_offset_arr:
		corner_arr.append(wcc+offset)
	var state_str = "0000"
	var used_cell_arr = []
	if use_sid:
		used_cell_arr = wtml.get_used_cells_by_id(sid)
	else:
		used_cell_arr = wtml.get_used_cells()
	
	if used_cell_arr.size() > 0:
		for i in 4:
			if used_cell_arr.has(corner_arr[i]) or corner_arr[i] == wcc :
				state_str[i] = "1"
			else : state_str[i] = "0"
		
		return STR_AC_DIC[state_str]
	return idx



# key:changed nvc idx value:changed corner
const NEIGHBOR_CHANGED_CORNER_DIC = {
	0:{2:2}, 1:{2:3, 3:2}, 2:{3:3}, 3:{3:0, 0:3},
	4:{0:0}, 5:{0:1, 1:0}, 6:{1:1}, 7:{1:2, 2:1},
}

const NEIGHBOR_CHANGED_SUROUND_CORNER_DIC = {
	0:{1:2,2:1}, 1:{2:3, 3:2}, 2:{3:0, 0:3}, 3:{0:1, 1:0}
}

static func get_neighbor_vc_changed_corner(nidx:int,ncc:Vector2i,nvcc:Vector2i,)->int:
	var idx = get_vcc_index(nvcc,ncc)
	var changed_corner_dic = NEIGHBOR_CHANGED_CORNER_DIC[nidx]
	if not changed_corner_dic.has(idx): return -1
	
	var changed_corner = changed_corner_dic[idx]
	return changed_corner

static func get_neighbor_changed_corner(ncc:Vector2i,wcc:Vector2i,)->Dictionary:
	var offset = ncc - wcc
	var idx = NEIGHBOR_OFFSET_8DIR_MAP[offset]
	return NEIGHBOR_CHANGED_CORNER_DIC[idx]
	
static func get_neighbor_vc_changed_suround_corner(nidx:int,ncc:Vector2i,nvcc:Vector2i,)->int:
	var idx = get_vcc_index(nvcc,ncc)
	var changed_corner_dic = NEIGHBOR_CHANGED_SUROUND_CORNER_DIC[nidx]
	if not changed_corner_dic.has(idx): return -1
	
	var changed_corner = changed_corner_dic[idx]
	return changed_corner

static func get_all_used_nvcc(used_ncc_dic:Dictionary)->Array:
	var out:Array = []
	for ncc in used_ncc_dic:
		for nvcc in get_wcc_vcc_list(ncc):
			out.append(nvcc)
	return out
