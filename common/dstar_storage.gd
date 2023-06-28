extends RefCounted
class_name DStarStorage
# provides an interface for the DStarLite implementation specs
# has functions: Insert, Remove, Update, Top, TopKey

const INTEGER_INF = pow(2,30)

var storage := []
var is_sorted := true

#func reset():
#	storage = []
#	# is_sorted doesn't matter when only 1 member big, right?

func insert(element:Vector2i, key):
	# change to also replace node using update()
	var index_check = has(element)
	if index_check == -1:
		storage.append( DStarStorageNode.new(key,element) )
	else:
		update(element, key, index_check) # I sure hope this doesn't become an infinite loop!
	is_sorted = false
	pass



func has(element:Vector2i) -> int:
	var i := 0
	while(i < storage.size()):
		if storage[i].element == element:
			return i
		i += 1;
	return -1;


func get_key(element):
	var index = has(element)
	if index > -1:
		return storage[index].key
	else:
		return INTEGER_INF


func update(element, key, index=-1):
	if index == -1:
		index = has(element)
		if index == -1:
			insert(element, key) # I sure hope this doesn't become an infinite loop!
	
	storage[index].key = key
	storage[index].element = element 
	# ^not necessary, because uhrm... the element is what's being compared?
	# Keeping just in case.
	# I sure hope this doesn't become an exploit!
	is_sorted = false
	pass

func remove(element:Vector2i):
	var i := 0
	while(i < storage.size()):
		if storage[i].element == element:
			storage.remove_at(i)
		else:
			i += 1;
	pass

# returns something... but what?
# Vector2i?
func top():
	return get_top().element

func top_key():
	if storage.size() < 1:
		return INTEGER_INF
	return get_top().key

func get_top():
	if !is_sorted: 
		storage.sort_custom( compare )
		is_sorted = true
	return storage[0]

func compare( a, b ):
	if a.key < b.key:
		return true
	return false

func size():
	return storage.size()

class DStarStorageNode:

	var key : int
	var element : Vector2i
	
	func _init(key_, element_):
		self.key = key_
		self.element = element_
