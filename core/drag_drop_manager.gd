class_name InventoryDragManager
extends RefCounted

const CELL_SIZE: int = 64
const CLICK_THRESHOLD_MS: int = 200 # Próg czasowy w milisekundach

static var held_item: ItemData = null
static var hovered_grid_ui: Control = null 

static var _drag_ghost: Control = null
static var _ghost_tex_rect: TextureRect = null
static var _root_viewport: Window = null

static var original_db: InventoryData = null
static var original_x: int = -1
static var original_y: int = -1
static var original_rotated: bool = false
static var drag_offset_grid: Vector2i = Vector2i.ZERO

# Zmienne Maszyny Stanu
static var _drag_start_time: int = 0
static var _is_pick_and_place: bool = false
static var _was_lmb_pressed: bool = false

static func start_drag(item: ItemData, source_node: Node, db: InventoryData, x: int, y: int, click_offset: Vector2i) -> void:
	if held_item != null: return
		
	held_item = item
	original_db = db
	original_x = x
	original_y = y
	original_rotated = item.rotated
	drag_offset_grid = click_offset
	_root_viewport = source_node.get_tree().root
	
	# Inicjalizacja zegara (CYA Protocol)
	_drag_start_time = Time.get_ticks_msec()
	_is_pick_and_place = false
	_was_lmb_pressed = true # Podniesienie inicjuje się kliknięciem
	
	_drag_ghost = Control.new()
	_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_ghost_tex_rect = TextureRect.new()
	_ghost_tex_rect.texture = held_item.texture
	_ghost_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ghost_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_ghost_tex_rect.modulate = Color(1, 1, 1, 0.6)
	
	_drag_ghost.add_child(_ghost_tex_rect)
	_root_viewport.add_child(_drag_ghost)
	
	_rebuild_ghost_transform()
	_root_viewport.get_tree().process_frame.connect(_update_ghost_position)

static func _update_ghost_position() -> void:
	if _drag_ghost == null or _root_viewport == null: return
	
	# BRAMKA EWAKUACYJNA: Klawisz ESC przerywa operację w dowolnym momencie
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		revert_drop()
		return
	
	var is_lmb_pressed: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var time_held: int = Time.get_ticks_msec() - _drag_start_time
	
	# 1. Dekoder Zdarzeń (Edge Detection)
	if _was_lmb_pressed and not is_lmb_pressed:
		# PUSZCZENIE przycisku
		if time_held < CLICK_THRESHOLD_MS:
			_is_pick_and_place = true
		else:
			_execute_drop()
			return
			
	elif not _was_lmb_pressed and is_lmb_pressed:
		# PONOWNE KLIKNIĘCIE (dla trybu Pick & Place)
		if _is_pick_and_place:
			_execute_drop()
			return

	_was_lmb_pressed = is_lmb_pressed
	
	# 2. Aktualizacja Wektora Pozycji
	var pixel_offset = Vector2(
		(drag_offset_grid.x * CELL_SIZE) + (CELL_SIZE / 2.0),
		(drag_offset_grid.y * CELL_SIZE) + (CELL_SIZE / 2.0)
	)
	_drag_ghost.global_position = _root_viewport.get_mouse_position() - pixel_offset
	
	if hovered_grid_ui != null:
		update_preview(hovered_grid_ui.get_local_mouse_position())

# Wyizolowany węzeł decyzyjny zrzutu
static func _execute_drop() -> void:
	if hovered_grid_ui != null:
		var success = attempt_drop(hovered_grid_ui.get_local_mouse_position())
		if not success:
			# ROZDZIELENIE UX:
			if _is_pick_and_place:
				# Przedmiot ZOSTAJE na kursorze. 
				# TODO: W przyszłości wywołamy tu sygnał pulsowania siatki na czerwono.
				pass 
			else:
				# Zwykłe przeciągnięcie z puszczeniem - wraca na miejsce
				revert_drop()
	else:
		if not _is_pick_and_place:
			revert_drop()

static func rotate_held_item() -> void:
	if held_item == null or _drag_ghost == null: return
		
	held_item.rotated = !held_item.rotated
	drag_offset_grid = Vector2i(drag_offset_grid.y, drag_offset_grid.x)
	_rebuild_ghost_transform()
	
	if hovered_grid_ui != null:
		update_preview(hovered_grid_ui.get_local_mouse_position())

static func _rebuild_ghost_transform() -> void:
	var dims = held_item.get_current_dimensions()
	_drag_ghost.size = Vector2(dims.x * CELL_SIZE, dims.y * CELL_SIZE)
	
	var base_dims = held_item.get_base_dimensions()
	_ghost_tex_rect.size = Vector2(base_dims.x * CELL_SIZE, base_dims.y * CELL_SIZE)
	
	if held_item.rotated:
		_ghost_tex_rect.rotation = PI / 2.0
		_ghost_tex_rect.position = Vector2(_ghost_tex_rect.size.y, 0)
	else:
		_ghost_tex_rect.rotation = 0.0
		_ghost_tex_rect.position = Vector2.ZERO

static func set_hovered_grid(grid_ui: Control) -> void:
	hovered_grid_ui = grid_ui

static func clear_hovered_grid(grid_ui: Control) -> void:
	if hovered_grid_ui == grid_ui:
		hovered_grid_ui = null
		if grid_ui.has_method("clear_highlight"):
			grid_ui.clear_highlight()

# Weryfikacja wizualna
static func update_preview(local_pos: Vector2) -> void:
	if held_item == null or hovered_grid_ui == null: return
	
	var mouse_grid_x: int = int(floor(local_pos.x / CELL_SIZE))
	var mouse_grid_y: int = int(floor(local_pos.y / CELL_SIZE))
	
	# Odejmujemy offset kursora, aby uzyskać prawdziwy początek przedmiotu
	var start_x: int = mouse_grid_x - drag_offset_grid.x
	var start_y: int = mouse_grid_y - drag_offset_grid.y
	
	var target_db: InventoryData = hovered_grid_ui.get("inventory_data") as InventoryData
	if target_db == null: return
	
	var is_valid: bool = target_db.can_place_item(held_item, start_x, start_y)
	hovered_grid_ui.draw_highlight(start_x, start_y, held_item.get_current_dimensions(), is_valid)

# Operacja zapisu
static func attempt_drop(local_pos: Vector2) -> bool:
	if held_item == null or hovered_grid_ui == null: return false
		
	var mouse_grid_x: int = int(floor(local_pos.x / CELL_SIZE))
	var mouse_grid_y: int = int(floor(local_pos.y / CELL_SIZE))
	
	var start_x: int = mouse_grid_x - drag_offset_grid.x
	var start_y: int = mouse_grid_y - drag_offset_grid.y
	
	var target_db: InventoryData = hovered_grid_ui.get("inventory_data") as InventoryData
	
	# 1. BRAMKA: Sprawdzamy czy coś już tu leży (Próba Merge)
	var index = target_db.get_index(start_x, start_y)
	if index != -1 and target_db.grid[index] != null:
		var target_item = target_db.grid[index]
		
		# Sprawdzamy tożsamość przedmiotu (docelowo po ID, na razie po nazwie)
		if target_item.item_name == held_item.item_name:
			var t_stack = target_item.get_component(StackComponent) as StackComponent
			var h_stack = held_item.get_component(StackComponent) as StackComponent
			
			if t_stack != null and h_stack != null:
				var overflow = t_stack.add_amount(h_stack.current_stack)
				target_db.inventory_updated.emit() # Wymusza przerysowanie Labela
				
				if overflow <= 0:
					# Zmieściło się wszystko - niszczymy ducha i zwalniamy myszkę
					_destroy_ghost()
					held_item = null
					hovered_grid_ui.clear_highlight()
					return true
				else:
					# Została reszta. Aktualizujemy trzymany stos.
					h_stack.current_stack = overflow
					# Odmawiamy udanego dropu, dzięki czemu reszta ZOSTANIE na kursorze
					return false 
		
		# Jeśli nie da się scalić, to jest to próba Swapu (Zamiany)
		printerr("Zamiana (Swap) przedmiotów o różnych kształtach nie jest jeszcze obsługiwana.")
		return false
	
	# 2. BRAMKA: Puste pole (Zwykły zrzut)
	if target_db.place_item(held_item, start_x, start_y):
		_destroy_ghost()
		held_item = null
		hovered_grid_ui.clear_highlight()
		return true
		
	return false

static func revert_drop() -> void:
	if held_item == null or original_db == null: return
	
	held_item.rotated = original_rotated
	
	# 1. Próba włożenia z powrotem (zadziała przy normalnym podniesieniu)
	if not original_db.place_item(held_item, original_x, original_y):
		
		# 2. Protokół Ratunkowy (zadziała przy anulowaniu Podziału/Split)
		var index = original_db.get_index(original_x, original_y)
		var target_item = original_db.grid[index]
		
		if target_item != null and target_item.item_name == held_item.item_name:
			var t_stack = target_item.get_component(StackComponent) as StackComponent
			var h_stack = held_item.get_component(StackComponent) as StackComponent
			
			if t_stack != null and h_stack != null:
				t_stack.add_amount(h_stack.current_stack)
				original_db.inventory_updated.emit()
		else:
			# Gdy na miejsce oryginału gracz zdążył już włożyć coś innego (World Drop trigger)
			printerr("Krytyczny błąd Revert: Miejsce zajęte. Utrata danych (wymagany World Drop).")
			
	_destroy_ghost()
	held_item = null
	original_db = null
	
	if hovered_grid_ui != null:
		hovered_grid_ui.clear_highlight()

static func _destroy_ghost() -> void:
	if _drag_ghost != null:
		_root_viewport.get_tree().process_frame.disconnect(_update_ghost_position)
		_drag_ghost.queue_free()
		_drag_ghost = null
