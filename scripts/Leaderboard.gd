## Leaderboard.gd
## 世界排行榜系统 - 本地存储排行榜数据
extends Node

#region 信号
signal leaderboard_updated
#endregion

#region 配置
const SAVE_PATH := "user://leaderboard.save"
const MAX_ENTRIES := 10  # 最多保存10条记录
#endregion

#region 数据结构
## 排行榜条目
class Entry:
	var player_name: String
	var completion_time: float  # 完成时间（秒）
	var score: int
	var date: String  # 记录日期
	
	func _init(name: String, time: float, score_val: int, date_str: String = "") -> void:
		player_name = name
		completion_time = time
		score = score_val
		date = date_str if date_str != "" else _get_current_date()
	
	func _get_current_date() -> String:
		var datetime := Time.get_datetime_dict_from_system()
		return "%04d-%02d-%02d" % [datetime.year, datetime.month, datetime.day]
	
	func to_dict() -> Dictionary:
		return {
			"player_name": player_name,
			"completion_time": completion_time,
			"score": score,
			"date": date
		}
	
	static func from_dict(data: Dictionary) -> Entry:
		return Entry.new(
			data.get("player_name", "Unknown"),
			data.get("completion_time", 999.0),
			data.get("score", 0),
			data.get("date", "")
		)
#endregion

#region 单例访问
static var _instance: Node
static var _entries: Array[Entry] = []


func _ready() -> void:
	_instance = self
	_load_leaderboard()
#endregion


#region 公共方法
## 添加新记录，返回排名（1-based），0 表示未上榜
static func add_entry(player_name: String, completion_time: float, score: int) -> int:
	var new_entry := Entry.new(player_name, completion_time, score)
	
	# 找到插入位置（按时间升序排列）
	var insert_index := 0
	for i in _entries.size():
		if completion_time < _entries[i].completion_time:
			insert_index = i
			break
		else:
			insert_index = i + 1
	
	# 检查是否上榜
	if insert_index >= MAX_ENTRIES:
		return 0
	
	# 插入记录
	_entries.insert(insert_index, new_entry)
	
	# 保持最多10条
	while _entries.size() > MAX_ENTRIES:
		_entries.remove_at(_entries.size() - 1)
	
	# 保存
	_save_leaderboard()
	
	# 发送更新信号
	if _instance:
		_instance.leaderboard_updated.emit()
	
	return insert_index + 1  # 返回排名（1-based）


## 获取排行榜数据
static func get_entries() -> Array[Entry]:
	return _entries


## 获取指定排名的记录（1-based）
static func get_entry(rank: int) -> Entry:
	if rank < 1 or rank > _entries.size():
		return null
	return _entries[rank - 1]


## 清空排行榜
static func clear_leaderboard() -> void:
	_entries.clear()
	_save_leaderboard()
	if _instance:
		_instance.leaderboard_updated.emit()


## 格式化时间为 mm:ss
static func format_time(seconds: float) -> String:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	return "%d:%02d" % [mins, secs]
#endregion


#region 私有方法
static func _load_leaderboard() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	
	var data: Variant
	data = file.get_var()
	file.close()
	
	if typeof(data) != TYPE_ARRAY:
		return
	
	_entries.clear()
	for entry_data: Variant in data:
		if typeof(entry_data) == TYPE_DICTIONARY:
			_entries.append(Entry.from_dict(entry_data))


static func _save_leaderboard() -> void:
	var data := []
	for entry: Entry in _entries:
		data.append(entry.to_dict())
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save leaderboard: " + str(FileAccess.get_open_error()))
		return
	
	file.store_var(data)
	file.close()
#endregion