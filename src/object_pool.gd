class_name ObjectPool extends Node
## 通用对象池（文档 4 / M6）。减少频繁 instantiate/free 的开销。
## 按 PackedScene 分类维护空闲节点栈；obtain 取出并挂回父节点，release 收回隐藏。
## 调用方需在 obtain 与 release 时传入同一个 scene 作为分类 key。

var _free: Dictionary = {}          ## PackedScene -> Array[Node]
var _root: Node                      ## 空闲节点暂存容器


func _ready() -> void:
	_root = Node.new()
	_root.name = "PoolStash"
	add_child(_root)


## 取出一个节点（无空闲则新建）。parent 为实际使用时的父节点。
func obtain(scene: PackedScene, parent: Node) -> Node:
	if scene == null or parent == null:
		return null
	var stack: Array = _free.get(scene, [])
	var node: Node
	if stack.is_empty():
		node = scene.instantiate()
	else:
		node = stack.pop_back()
		if not is_instance_valid(node):
			node = scene.instantiate()
	if node.get_parent() != parent:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		parent.add_child(node)
	node.visible = true
	node.set_deferred("monitoring", true)
	node.set_deferred("monitorable", true)
	return node


## 回收一个节点（从父节点摘下，藏入池中）。scene 必须与 obtain 时一致。
func release(node: Node, scene: PackedScene) -> void:
	if not is_instance_valid(node) or scene == null:
		return
	node.set_deferred("monitoring", false)
	node.set_deferred("monitorable", false)
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	_root.add_child(node)
	node.visible = false
	if not _free.has(scene):
		_free[scene] = []
	_free[scene].append(node)
