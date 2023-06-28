extends RefCounted

class BinarySearchNode:
	
	var key : int
	var element
	var left_child : BinarySearchNode
	var right_child : BinarySearchNode
	
	pass

class BinarySearchTree:
	
	var root : BinarySearchNode


	func get_root():
		return root

	# Insert, Remove, Update, Top, TopKey

	func pop_root():
		if root != null:
			if root.right_child != null:
				var output = root
				root = get_min(root.right_child)
				return output
		return root
		pass


	func get_min( node:BinarySearchNode ):
		var left_child = node.left_child
		
		if left_child == null:
			return node
		
		while left_child.left_child != null:
			left_child = left_child.left_child
	pass


	func insert( node:BinarySearchNode ):
		var branch = root
		while 1==1:
			if branch.key > node.key:
				if branch.left_child == null:
					branch.left_child = node; return
				elif branch.left_child.key > node.key:
					node.insert( branch.left_child )
					branch.left_child = node; return
				else:
					branch = branch.left_child
			else: #branch.key <= node:
				if branch.right_child == null:
					branch.right_child = node; return
				elif branch.right_child.key < node.key:
					node.insert( branch.right_child )
					branch.right_child = node; return
				else:
					branch = branch.right_child
	
	# Does not return, use the 'list' as a 'return'
	func in_order(node:BinarySearchNode, list:Array, index:int):
		if(node == null):
			return;
		in_order(node.left_child, list, index);   # first do every left child tree
		list.append( node.getData() )
		index += 1
		in_order(node.right_child, list, index);  # do the same with the right child
	
	
	func blind_delete( element ):
		var list := []
		in_order( root, list, 0 )
		
		for node in list:
			if node.element == element:
				delete( node )
		
		pass
	
	func delete( node : BinarySearchNode ):
		pass
