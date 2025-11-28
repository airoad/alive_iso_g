class_name NFunc  # 类名，全局可引用
extends RefCounted  # 继承RefCounted，支持字典存储，避免内存泄漏

static func scan_directory(dir_path: String, ex: String) -> Dictionary:
	var dic : Dictionary = {}
	var dir = DirAccess.open(dir_path)
	if not dir:
		printerr("目录不存在或无法访问：", dir_path)
		return dic
	# 关键：开启递归扫描（必须传true，否则不扫描子目录）
	dir.list_dir_begin() 
	var current_entry = dir.get_next()
	while current_entry != "":
		var full_path = dir.get_current_dir() + "/" + current_entry
		# 筛选.tres文件并尝试加载为TileSet
		if dir.file_exists(full_path) and current_entry.ends_with(ex):
			var loaded_tileset = load(full_path)
			if loaded_tileset:
				dic[full_path] = loaded_tileset
				#print("加载成功：", full_path)  # 调试用
				
		current_entry = dir.get_next()
	dir.list_dir_end()
	return dic

static func get_vcc_dic(wcc:Vector2i)->Dictionary[int,Vector2i]:
	var out:Dictionary[int,Vector2i] = {
		0:wcc+Vector2i(0,0), 
		1:wcc+Vector2i(0,1), 
		2:wcc+Vector2i(-1,1), 
		3:wcc+Vector2i(-1,0)
	}
	return out

static func get_wc_nc_arr(wcc:Vector2i)->Array[Vector2i]:
	return [
		wcc+Vector2i(1,-1),wcc+Vector2i(1,0),wcc+Vector2i(1,1),wcc+Vector2i(0,1),
		wcc+Vector2i(-1,1),wcc+Vector2i(-1,0),wcc+Vector2i(-1,-1),wcc+Vector2i(0,-1)
	]

static func get_vc_corner_coord(wcc:Vector2i)->Array[Array]:
	var wc_nc_arr = get_wc_nc_arr(wcc)
	return [
		[wc_nc_arr[0], wc_nc_arr[1], wcc, wc_nc_arr[7]],
		[wc_nc_arr[1], wc_nc_arr[2], wc_nc_arr[3], wcc],
		[wcc, wc_nc_arr[3], wc_nc_arr[4], wc_nc_arr[5]],
		[wc_nc_arr[7], wcc, wc_nc_arr[5], wc_nc_arr[6]]
	]

static func get_ncc_dic(wcc:Vector2i)->Dictionary[Vector2i,Array]:
	var vcc_dic = get_vcc_dic(wcc)
	var out:Dictionary[Vector2i,Array] = {}
	for i in 4:
		var vcc = vcc_dic[i]
		var ncc_arr:Array[Vector2i] = [
			vcc+Vector2i(1,0),
			vcc+Vector2i(0,1),
			vcc+Vector2i(-1,0),
			vcc+Vector2i(0,-1)
		]
		out.set(vcc, ncc_arr)
	return out



static func keep_by_index_arr(origin:Array,arr:Array)->Array[int]:
	var temp:Array[int] = []
	for i in arr:
		var v:int = origin[i]
		temp.append(v)
	return temp
	
static func str_set_at(original: String, index: int, new_char: String) -> String:
	if index < 0 or index >= original.length():
		return original
	var arr = []
	for i in original.length():
		arr.append(original[i])
	arr[index] = new_char
	var s = ""
	for a in arr:
		s += a
	return s

static func array_remove_duplicates_keep_order_first(arr: Array) -> Array:
	if arr.is_empty(): return []
	var fst = arr[0]
	var unique_arr: Array = []
	for elem in arr:
		# 只添加临时数组中没有的元素
		if not unique_arr.has(elem):
			unique_arr.append(elem)
	unique_arr.set(0,fst)
	return unique_arr

static func format_sid_arr(arr:Array)->Array:
	var out = array_remove_duplicates_keep_order_first(arr)
	out.sort()
	out.reverse()
	return out

static func array_to_str(arr:Array, spl:String)->String:
	var out_str:String =""
	if arr.size() == 0: return out_str
	else:
		for i in arr.size():
			if i != arr.size()-1:
				out_str += str(arr[i])+spl
			else:out_str += str(arr[i])
	return out_str

# 保存json到硬盘（处理Vector2i序列化）
static func save_json(data, path:String) -> void:	
	var file = FileAccess.open(path, FileAccess.WRITE)
	var json_string = JSON.stringify(data)
	file.store_line(json_string)
	print("✅ 已保存到：", path)

# 从硬盘加载json
static func load_json(path:String):
	if not FileAccess.file_exists:
		print("ℹ️ 未找到文件")
		return
	
	var file = FileAccess.open(path,FileAccess.READ)
	var json_string = file.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return
	var data = json.data
	print("✅ 加载成功\n")
	return data

static func save_dic_vec(dic:Dictionary, path:String):
	# 序列化：将Vector2i转为数组，方便JSON保存
	var serial_dict: Dictionary = {}
	for key in dic:
		var vec = dic[key]
		serial_dict[key] = [vec.x, vec.y]  # Vector2i → [x,y]
	save_json(serial_dict,path)

static func load_dic_vec(path):
	var data = load_json(path)
	var dic:Dictionary[String,Array] = {}
	for k in data:
		var v = data[k]
		var vec:Vector2i = Vector2i.ZERO
		vec.x = v[0]
		vec.y = v[1]
		dic.set(k,vec)
	return dic	
	
	
static func remove_duplicates_keep_order(array: Array) -> Array:
	var unique_array: Array = []
	for e in array:
		if not unique_array.has(e):
			unique_array.append(e)
	return unique_array
	
	

# ----------------------------------------------------------------------
# 静态函数：搜索给定路径下的子目录，并收集指定类型的文件
# ----------------------------------------------------------------------
# 参数:
#   path: 根目录路径 (例如："res://assets")
#   ex:   要搜索的文件后缀 (例如：".png", ".tscn", ".gd")
#
# 返回:
#   Dictionary: { 
#       子目录路径: [该子目录下的文件路径数组],
#       ...
#   }
# ----------------------------------------------------------------------
static func search_files_in_subdirectories(path: String, ex: String) -> Dictionary:
	# 确保路径以斜杠结尾，方便后续拼接
	if not path.ends_with("/"):
		path += "/"
		
	# 存储结果的字典
	var result_dict: Dictionary = {}
	
	# 确保后缀以点开头
	var extension_to_search = ex.to_lower()
	if not extension_to_search.begins_with("."):
		extension_to_search = "." + extension_to_search

	# 1. 初始化 Directory 访问对象
	var dir = DirAccess.open(path)
	
	# 检查目录是否成功打开
	if dir == null:
		# 打印错误并返回空字典
		printerr("FileUtils: 无法打开目录: " + path)
		return result_dict

	# 2. 遍历当前目录下的所有条目
	dir.list_dir_begin()
	var item_name = dir.get_next()
	
	while item_name != "":
		# 排除特殊目录 "." (当前目录) 和 ".." (上级目录)
		if item_name != "." and item_name != "..":
			
			# 3. 检查条目是否为目录 (子目录)
			if dir.current_is_dir():
				var subdirectory_path = path + item_name
				
				# 递归调用自身，获取子目录下的文件
				var sub_result = search_files_in_subdirectories(subdirectory_path, ex)
				
				# 合并递归结果
				for key in sub_result.keys():
					result_dict[key] = sub_result[key]
				
			# 4. 检查条目是否为文件
			else:
				# 检查文件后缀是否匹配
				if item_name.to_lower().ends_with(extension_to_search):
					var file_path = path + item_name
					
					# 5. 将文件路径添加到当前目录（path）对应的数组中
					# 如果字典中还没有当前目录的键，则初始化一个空数组
					if not result_dict.has(path):
						result_dict[path] = []
						
					# 添加文件路径
					result_dict[path].append(file_path)

		# 移动到下一个条目
		item_name = dir.get_next()
		
	# 3. 结束遍历
	dir.list_dir_end()
	
	return result_dict

static func get_path_name(path:String)->String:
	if path.ends_with("/"):
		path = path.trim_suffix("/")
	return path.get_file()
