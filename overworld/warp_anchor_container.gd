extends Node

func get_anchor_by_name(anchor_name:String):
	var children = self.get_children()
	for child in children:
		if child is WarpAnchor or child.has_method("get_warp_anchor_name"):
			if str(child.get_warp_anchor_name()).to_lower().strip_edges() \
			== anchor_name.to_lower().strip_edges():
				return child
	
	pass
