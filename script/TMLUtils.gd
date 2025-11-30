class_name TMLUtils
extends RefCounted

enum SID_Type {
	WATER,
	SAND,
	DIRT,
	GRASS
}

const SID_DIC:Dictionary = {
	"0_1":0,"1_2":1,"2_3":2,"3_4":3,
}

const AC_DIC:Dictionary = {
	[true ,false,false,false]:0 ,
	[false,true ,false,false]:1 ,
	[false,false,true ,false]:2 ,
	[false,false,false,true ]:3 ,
	[true ,false,false,true ]:4 ,
	[false,true ,true ,false]:5 ,
	[true ,true ,false,false]:6 ,
	[false,false,true ,true ]:7 ,
	[true ,true ,false,true ]:8 ,
	[true ,true ,true ,false]:9 ,
	[false,true ,true ,true ]:10,
	[true ,false,true ,true ]:11,
	[false,true ,false,true ]:12,
	[true ,false,true ,false]:13,
	[true ,true ,true ,true ]:14,
	[false,false,false,false]:15,
}

# 确保 w v (0,0)位置一致
const CORNER_4DIR_MAP: Array[Vector2i] = [
	Vector2i(0, 0),Vector2i(1, 0),Vector2i(1, 1),Vector2i(0, 1),
]

const NEIGHBOR_8DIR_MAP: Array[Vector2i] = [
	Vector2i(-1, -1),Vector2i( 0, -1),Vector2i( 1, -1),Vector2i( 1,  0),
	Vector2i( 1,  1),Vector2i( 0,  1),Vector2i(-1,  1),Vector2i(-1,  0),
]

static func get_8_neighbors(cc:Vector2i)->Array:
	var arr = []
	for i in 8:
		var nc = cc + NEIGHBOR_8DIR_MAP[i]
		arr.append(nc) 
	return arr

# wcc -> 4 vcc 左上开始 isometric: 左开始
static func get_vcc_list(wcc:Vector2i)->Array[Vector2i]:
	var vccs:Array[Vector2i] = []
	for i in 4:
		var vcc = wcc+CORNER_4DIR_MAP[i]
		vccs.append(vcc)
	return vccs

# 获取区域内所有cell coord。考虑的是世界空间矩形区域
static func get_all_cc_in_world_rect(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var ccs:Array[Vector2i] = []
	var step = (end - start).sign()
	step.x = 1 if step.x == 0 else step.x
	step.y = 1 if step.y == 0 else step.y
	for y in range(start.y,end.y+step.y,step.y):
		for x in range(start.x,end.x+step.x,step.x):
			var cc = Vector2i(x,y)
			ccs.append(cc)
	return ccs

# vcc -> neighbor wcc 右上开始 isometric: 右开始
static func get_corner_state(vcc:Vector2i,wtml:TileMapLayer)->Dictionary:
	var ac_y_arr:Array[int] = [0,0,0,0]
	for i in 4:
		var corner = vcc-CORNER_4DIR_MAP[i]
		var corner_ac_y = wtml.get_cell_atlas_coords(corner).y
		ac_y_arr[i] = 0 if corner_ac_y == -1 else corner_ac_y
	return get_transition_data(ac_y_arr)

# 这是一个需要你根据实际限制（水上只能是沙等）实现的复杂函数
static func get_transition_data(sids: Array[int]) -> Dictionary:
	# 水(0)>沙(1)>土(2)>草(3)
	# 找到最高和次高优先级的 sid
	var unique_sids = sids.duplicate()
	unique_sids = NFunc.remove_duplicates_keep_order(unique_sids)
	unique_sids.sort() # 升序排序
	var base_sid = unique_sids[0] # 最高优先级，将覆盖其他一切（例如：一片草地）
	var blend_sid = unique_sids[1] if unique_sids.size() > 1 else -1 # 次高优先级，用于过渡
	print(base_sid," ",blend_sid)
	# 执行你的限制检查：
	if base_sid == 0 and blend_sid == 1: # 沙和水
		pass # 允许
	#blend_sid = -1 if blend_sid - base_sid != 1 or unique_sids.size() > 2 else blend_sid
	
	if blend_sid == -1: # 只有一种类型，使用纯色基底瓦片 (atlas_id_y:15)
		var sid = base_sid - 1 if base_sid - 1 >= 0 else 0
		var acy = 15 if base_sid == 0 else 14 
		return {"sid": sid, "acy": acy}
	# 生成有序键 e.g., "1_2"
	var sorted_sids = [base_sid, blend_sid]
	sorted_sids.sort()
	var ssid = str(sorted_sids[0]) + "_" + str(sorted_sids[1])
	# 生成布尔掩码：判断哪个角是 blend_sid 的
	var mask = [
		sids[0] == blend_sid, # TL
		sids[1] == blend_sid, # TR
		sids[2] == blend_sid, # BR
		sids[3] == blend_sid, # BL
	]
	#print("%s,%s,%s" % [sids,SID_DIC.get(ssid,0),AC_DIC.get(mask,15)])
	return {"sid":SID_DIC.get(ssid,0), "acy": AC_DIC.get(mask,14)}
