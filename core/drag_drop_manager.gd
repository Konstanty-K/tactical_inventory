# res://addons/tactical_inventory/core/drag_drop_manager.gd
extends Node
# Wymaga rejestracji jako AutoLoad o nazwie np. InventoryDragManager

const CELL_SIZE: int = 64

var held_item: ItemData = null
var hovered_grid_ui = null # Typowanie dynamiczne (duck typing) lub sztywne na klasę Widoku

# API wejściowe dla okien interfejsu (CYA: okna same meldują swoją obecność)
func set_hovered_grid(grid_ui) -> void:
	hovered_grid_ui = grid_ui

func clear_hovered_grid(grid_ui) -> void:
	# Usuwamy referencję tylko, jeśli okno, z którego wychodzimy, to okno aktualnie aktywne.
	# Zabezpiecza to przed nadpisaniem w przypadku nakładających się paneli.
	if hovered_grid_ui == grid_ui:
		hovered_grid_ui = null
		grid_ui.clear_highlight() # Wysyłamy rozkaz wyczyszczenia barw siatki

func _process(_delta: float) -> void:
	if held_item == null or hovered_grid_ui == null:
		return
		
	# 1. Kwantyzacja Przestrzeni
	var local_pos: Vector2 = hovered_grid_ui.get_local_mouse_position()
	var grid_x: int = int(floor(local_pos.x / CELL_SIZE))
	var grid_y: int = int(floor(local_pos.y / CELL_SIZE))
	
	# 2. Odpytanie bazy danych zagnieżdżonej w oknie
	var target_db: InventoryData = hovered_grid_ui.inventory_data
	var is_valid: bool = target_db.can_place_item(held_item, grid_x, grid_y)
	
	# 3. Rozkaz dla Widoku: Narysuj stan
	hovered_grid_ui.draw_highlight(grid_x, grid_y, held_item.get_current_dimensions(), is_valid)

# Sprzężenie wejściowe - reakcja na kliknięcia
func _unhandled_input(event: InputEvent) -> void:
	if held_item == null:
		return
		
	# Złapanie puszczenia lewego przycisku myszy
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if hovered_grid_ui != null:
			_attempt_drop()
		else:
			print("Upuszczono przedmiot poza oknami ekwipunku - do implementacji.")

func _attempt_drop() -> void:
	var local_pos: Vector2 = hovered_grid_ui.get_local_mouse_position()
	var grid_x: int = int(floor(local_pos.x / CELL_SIZE))
	var grid_y: int = int(floor(local_pos.y / CELL_SIZE))
	
	var target_db: InventoryData = hovered_grid_ui.inventory_data
	
	# Próba twardego zapisu. Jeśli `place_item` zwróci true, operacja się powiodła.
	if target_db.place_item(held_item, grid_x, grid_y):
		held_item = null
		hovered_grid_ui.clear_highlight()
