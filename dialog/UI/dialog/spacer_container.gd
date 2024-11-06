"""
SpacerContainer
An empty container to create vertical space matching another node.
Purpose is to keep space even when other sibling container is hidden within 
another container node, as if the sibling container was still present.
Assumes other node (most likely sibling container node) has size property.

Info:
	Godot Open Dialogue System
	by Tina Qin (QueenChristina)
	https://github.com/QueenChristina/gd_dialog
	License: MIT.
	Please credit me if you use! Thank you! <3
"""

extends MarginContainer
class_name SpacerContainer

@export var node_path: NodePath
var node: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	node = get_node(node_path)
	if node:
		custom_minimum_size.y = node.size.y
	else:
		push_error("SpacerContainer: Node not found at the specified path.")
