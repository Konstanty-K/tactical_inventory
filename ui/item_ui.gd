class_name ItemUI
extends Control

const CELL_SIZE: int = 64
var item_data: ItemData = null
var _tex_rect: TextureRect = null

# Zmieniamy zmienną na publiczną, by Główna Gra mogła ją nadpisać
var status_label: Label = null

func init_item(data: ItemData) -> void:
	item_data = data
	
	# Wymiary nadrzędne - to do nich kotwiczy się Label
	var dims = item_data.get_current_dimensions()
	custom_minimum_size = Vector2(dims.x * CELL_SIZE, dims.y * CELL_SIZE)
	size = custom_minimum_size
	
	_tex_rect = TextureRect.new()
	_tex_rect.texture = item_data.texture
	_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Wymiary bazowe tylko dla tekstury (rotacja wizualna)
	var base_dims = item_data.get_base_dimensions()
	_tex_rect.size = Vector2(base_dims.x * CELL_SIZE, base_dims.y * CELL_SIZE)
	
	if item_data.rotated:
		_tex_rect.rotation = PI / 2.0
		_tex_rect.position = Vector2(_tex_rect.size.y, 0) 
		
	add_child(_tex_rect)
	
	# Inicjalizacja etykiety po dodaniu tekstury (żeby była na wierzchu)
	_build_status_label()
	
	# Wtyczka obsługuje wyłącznie Stack
	var stack_comp = item_data.get_component(StackComponent) as StackComponent
	if stack_comp != null and stack_comp.current_stack > 1:
		status_label.text = str(stack_comp.current_stack)
		status_label.show()
		
	mouse_filter = Control.MOUSE_FILTER_PASS

func _build_status_label() -> void:
	status_label = Label.new()
	status_label.hide() # Ukrywamy jeśli pusty
	
	status_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Anchor Bottom-Right gwarantuje przyklejenie do krawędzi bez względu na obrót
	status_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color.WHITE) # Domyślny kolor
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 4)
	# Odsunięcie od samego marginesu, by nie przylegał do ramki
	status_label.position -= Vector2(4, 2)
	add_child(status_label)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if InventoryDragManager.held_item == null:
			accept_event()
			
			# Odczytujemy stan klawisza CTRL
			var is_split = Input.is_physical_key_pressed(KEY_CTRL)
			
			var local_pos = get_local_mouse_position()
			var click_offset_x = int(local_pos.x / CELL_SIZE)
			var click_offset_y = int(local_pos.y / CELL_SIZE)
			_pick_up(Vector2i(click_offset_x, click_offset_y), is_split)

func _pick_up(offset: Vector2i, is_split: bool = false) -> void:
	var parent_grid = get_parent() as InventoryGridUI
	if not parent_grid: return
	
	var grid_x = int(position.x / CELL_SIZE)
	var grid_y = int(position.y / CELL_SIZE)
	
	var stack_comp = item_data.get_component(StackComponent) as StackComponent
	
	# BRAMKA: Operacja podziału (Split)
	if is_split and stack_comp != null and stack_comp.current_stack > 1:
		var split_amount = int(stack_comp.current_stack / 2.0)
		stack_comp.current_stack -= split_amount # Odejmujemy połowę z oryginału
		
		# Głębokie klonowanie obiektu (duplikuje ItemData oraz wszystkie Komponenty wewnątrz)
		var cloned_item = item_data.duplicate(true) as ItemData
		var cloned_stack = cloned_item.get_component(StackComponent) as StackComponent
		cloned_stack.current_stack = split_amount # Klon dostaje odciętą połowę
		
		# Wymuszamy aktualizację etykiety wizualnej oryginału (który ZOSTANIE na siatce)
		status_label.text = str(stack_comp.current_stack)
		
		# Klon trafia do Menedżera, oryginał nie jest usuwany (brak queue_free)
		InventoryDragManager.start_drag(cloned_item, self, parent_grid.inventory_data, grid_x, grid_y, offset)
		
	# BRAMKA: Standardowe podniesienie
	else:
		InventoryDragManager.start_drag(item_data, self, parent_grid.inventory_data, grid_x, grid_y, offset)
		parent_grid.inventory_data.remove_item(item_data)
		queue_free()

func flash_error() -> void:
	var tween = create_tween()
	_tex_rect.modulate = Color(1.0, 0.1, 0.1, 1.0)
	tween.tween_property(_tex_rect, "modulate", Color.WHITE, 0.3)
