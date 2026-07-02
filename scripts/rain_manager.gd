extends Node

var _zones: Dictionary = {}


func register_zone(zone: Node) -> void:
	if zone == null or not zone.has_method("get_zone_id"):
		return
	var zone_id: String = zone.get_zone_id()
	if zone_id.is_empty():
		return
	_zones[zone_id] = zone


func unregister_zone(zone: Node) -> void:
	if zone == null or not zone.has_method("get_zone_id"):
		return
	_zones.erase(zone.get_zone_id())


func stop_rain(zone_id: String) -> void:
	var zone = _zones.get(zone_id)
	if zone and zone.has_method("stop_rain"):
		zone.stop_rain()


func is_raining_at(col: int, row: int) -> bool:
	for zone in _zones.values():
		if zone.has_method("is_active") and zone.is_active():
			if zone.has_method("contains_cell") and zone.contains_cell(col, row):
				return true
	return false
