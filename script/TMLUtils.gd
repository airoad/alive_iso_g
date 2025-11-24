class_name TMLUtils
extends RefCounted


const AC_DIC:Dictionary = {
 	[1,0,0,0]:0, [0,1,0,0]:1, [0,0,1,0]:2, [0,0,0,1]:3, 
	[1,0,0,1]:4, [0,1,1,0]:5, [1,1,0,0]:6, [0,0,1,1]:7, 
	[1,1,0,1]:8, [1,1,1,0]:9, [0,1,1,1]:10,[1,0,1,1]:11,
	[0,1,0,1]:12,[1,0,1,0]:13,[1,1,1,1]:14,[0,0,0,0]:15,
}

# 确保 w v (0,0)位置一致
const CORNER_4DIR_MAP: Array[Vector2i] = [
	Vector2i(0, 0),Vector2i(1, 0),Vector2i(1, 1),Vector2i(0, 1)
]

# wcc -> 4 vcc 左上开始 isometric: 左开始
static func get_vcc_list(wcc:Vector2i)->Array[Vector2i]:
	var vccs:Array[Vector2i] = []
	for i in 4:
		var vcc = wcc+CORNER_4DIR_MAP[i]
		vccs.append(vcc)
	return vccs

# vcc -> neighbor wcc 右上开始 isometric: 右开始
static func get_corner_state(vcc:Vector2i,wtml:TileMapLayer)->int:
	var ac_y = -1
	var ac_y_arr = [0,0,0,0]
	for i in 4:
		var corner = vcc-CORNER_4DIR_MAP[i]
		var corner_sid = wtml.get_cell_source_id(corner)
		ac_y_arr[i] = 0 if corner_sid == -1 else corner_sid
	ac_y = AC_DIC.get(ac_y_arr,-1)
	return ac_y

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
