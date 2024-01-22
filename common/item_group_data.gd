extends Resource
class_name ItemGroupData
# based on https://www.youtube.com/watch?v=V79YabQZC1s

const STACK_MAX = 99

@export var item_data:ItemData
@export_range(1, STACK_MAX) var quantity := 0
