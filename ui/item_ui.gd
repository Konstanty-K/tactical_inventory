class_name ItemUI
extends Control

const CELL_SIZE: int = 64
var item_data: ItemData = null
var _tex_rect: TextureRect = null

func init_item(data: ItemData) -> void:
	item_data = data
	
	var dims = item_data.get_current_dimensions()
	custom_minimum_size = Vector2(dims.x * CELL_SIZE, dims.y * CELL_SIZE)
	size = custom_minimum_size
	
	_tex_rect = TextureRect.new()
	_tex_rect.texture = item_data.texture
	_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var base_dims = item_data.get_base_dimensions()
	
	_tex_rect.size = Vector2(base_dims.x * CELL_SIZE, base_dims.y * CELL_SIZE)
	
	# Transformacja wektorowa dla obróconych obiektów
	if item_data.rotated:
		_tex_rect.rotation = PI / 2.0
		# Przesunięcie o wysokość, aby zrekompensować wyjście macierzy poza krawędź
		_tex_rect.position = Vector2(_tex_rect.size.y, 0) 
		
	add_child(_tex_rect)
	mouse_filter = Control.MOUSE_FILTER_PASS

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if InventoryDragManager.held_item == null:
			accept_event()
			var local_pos = get_local_mouse_position()
			var click_offset_x = int(local_pos.x / CELL_SIZE)
			var click_offset_y = int(local_pos.y / CELL_SIZE)
			_pick_up(Vector2i(click_offset_x, click_offset_y))

func _pick_up(offset: Vector2i) -> void:
	var parent_grid = get_parent() as InventoryGridUI
	if parent_grid:
		var grid_x = int(position.x / CELL_SIZE)
		var grid_y = int(position.y / CELL_SIZE)
		InventoryDragManager.start_drag(item_data, self, parent_grid.inventory_data, grid_x, grid_y, offset)
		parent_grid.inventory_data.remove_item(item_data)
		queue_free()

func flash_error() -> void:
	var tween = create_tween()
	_tex_rect.modulate = Color(1.0, 0.1, 0.1, 1.0) # Czerwień
	tween.tween_property(_tex_rect, "modulate", Color.WHITE, 0.3)
