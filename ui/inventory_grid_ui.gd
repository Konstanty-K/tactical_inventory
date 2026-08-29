class_name InventoryGridUI
extends Control

const CELL_SIZE: int = 64
@export var inventory_data: InventoryData
@export var item_ui_scene: PackedScene
@export var cell_background: Texture2D

var _show_highlight: bool = false
var _highlight_grid_pos: Vector2i = Vector2i.ZERO
var _highlight_dims: Vector2i = Vector2i.ZERO
var _highlight_valid: bool = false

func _ready() -> void:
	assert(inventory_data != null, "InventoryGridUI musi mieć podpięty InventoryData!")
	custom_minimum_size = Vector2(inventory_data.grid_width * CELL_SIZE, inventory_data.grid_height * CELL_SIZE)
	size = custom_minimum_size
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	inventory_data.inventory_updated.connect(_on_inventory_updated)

func _gui_input(event: InputEvent) -> void:
	# Click-to-place: Reagujemy na WCIŚNIĘCIE (pressed == true)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if InventoryDragManager.held_item != null and InventoryDragManager.hovered_grid_ui == self:
			var success = InventoryDragManager.attempt_drop(get_local_mouse_position())
			if not success:
				InventoryDragManager.revert_drop()

func _on_mouse_entered() -> void:
	InventoryDragManager.set_hovered_grid(self)

func _on_mouse_exited() -> void:
	InventoryDragManager.clear_hovered_grid(self)

func draw_highlight(grid_x: int, grid_y: int, dims: Vector2i, is_valid: bool) -> void:
	_show_highlight = true
	_highlight_grid_pos = Vector2i(grid_x, grid_y)
	_highlight_dims = dims
	_highlight_valid = is_valid
	queue_redraw()

func clear_highlight() -> void:
	if _show_highlight:
		_show_highlight = false
		queue_redraw()

func _on_inventory_updated() -> void:
	_rebuild_items()
	queue_redraw()

func _rebuild_items() -> void:
	for child in get_children():
		if child is ItemUI:
			child.queue_free()
			
	if inventory_data == null: return
	var drawn_items: Array[ItemData] = []
	
	for y in range(inventory_data.grid_height):
		for x in range(inventory_data.grid_width):
			var index: int = inventory_data.get_index(x, y)
			var item: ItemData = inventory_data.grid[index]
			
			if item != null and not drawn_items.has(item):
				_spawn_item_ui(item, x, y)
				drawn_items.append(item)

func _spawn_item_ui(item: ItemData, grid_x: int, grid_y: int) -> void:
	if item_ui_scene == null:
		printerr("Brak przypisanej sceny ItemUI!")
		return
	var item_node: ItemUI = item_ui_scene.instantiate() as ItemUI
	add_child(item_node)
	item_node.init_item(item)
	item_node.position = Vector2(grid_x * CELL_SIZE, grid_y * CELL_SIZE)

func _draw() -> void:
	if cell_background != null:
		# Zamiast ślepego kafelkowania, wymuszamy skalowanie grafiki (np. 100x100) 
		# do sztywnego okna (64x64) dla każdej logicznej komórki.
		for y in range(inventory_data.grid_height):
			for x in range(inventory_data.grid_width):
				var cell_rect = Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
				# draw_texture_rect domyślnie rozciąga teksturę do podanego Rect2
				draw_texture_rect(cell_background, cell_rect, false)
	else:
		var grid_rect = Rect2(Vector2.ZERO, custom_minimum_size)
		draw_rect(grid_rect, Color(0.1, 0.1, 0.1, 0.8))
		
	for x in range(inventory_data.grid_width + 1):
		draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, custom_minimum_size.y), Color.DIM_GRAY)
	for y in range(inventory_data.grid_height + 1):
		draw_line(Vector2(0, y * CELL_SIZE), Vector2(custom_minimum_size.x, y * CELL_SIZE), Color.DIM_GRAY)
		
	if _show_highlight:
		var color = Color(0.0, 1.0, 0.0, 0.3) if _highlight_valid else Color(1.0, 0.0, 0.0, 0.3)
		var highlight_rect = Rect2(Vector2(_highlight_grid_pos) * CELL_SIZE, Vector2(_highlight_dims) * CELL_SIZE)
		draw_rect(highlight_rect, color)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_R and event.pressed and not event.echo:
		if InventoryDragManager.held_item != null:
			InventoryDragManager.rotate_held_item()
		elif InventoryDragManager.hovered_grid_ui == self:
			_attempt_hover_rotation()
			
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if InventoryDragManager.held_item != null and InventoryDragManager.hovered_grid_ui == null:
			InventoryDragManager.revert_drop()

func _attempt_hover_rotation() -> void:
	var local_pos = get_local_mouse_position()
	var grid_x = int(floor(local_pos.x / CELL_SIZE))
	var grid_y = int(floor(local_pos.y / CELL_SIZE))
	
	if not inventory_data.is_in_bounds(grid_x, grid_y): return
	
	var target_item = inventory_data.grid[inventory_data.get_index(grid_x, grid_y)]
	if target_item != null:
		var success = inventory_data.rotate_item_in_place(target_item)
		if not success:
			_flash_item_error(target_item)

func _flash_item_error(item: ItemData) -> void:
	for child in get_children():
		if child is ItemUI and child.item_data == item:
			child.flash_error()
			break
