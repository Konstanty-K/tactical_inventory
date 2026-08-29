# res://addons/tactical_inventory/core/InventoryData.gd
extends Resource
class_name InventoryData

signal inventory_updated # UI nasłuchuje tego sygnału, by się przerysować

@export var grid_width: int = 10
@export var grid_height: int = 10

# Tablica przetrzymująca stan siatki. Rozmiar: grid_width * grid_height
# Puste pole = null. Zajęte pole = referencja do obiektu ItemData.
var grid: Array[ItemData] = []

func _init() -> void:
	# Wypełniamy siatkę wartościami null (pusta siatka)
	grid.resize(grid_width * grid_height)
	grid.fill(null)

# Mapuje współrzędne X,Y na indeks tablicy 1D
func get_index(x: int, y: int) -> int:
	return y * grid_width + x

# Sprawdza granice (Out of Bounds)
func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height


# Odpowiada na pytanie: "Czy przedmiot Zmieści się na współrzędnych bazowych X, Y?"
# Nie modyfikuje stanu!
func can_place_item(item: ItemData, start_x: int, start_y: int, ignore_item: ItemData = null) -> bool:
	var dims: Vector2i = item.get_current_dimensions()
	
	# Pętla po objętości Bounding Boxa przedmiotu
	for y in range(start_y, start_y + dims.y):
		for x in range(start_x, start_x + dims.x):
			
			# WARUNEK 1: Wyjście poza planszę
			if not is_in_bounds(x, y):
				return false
				
			var current_occupant = grid[get_index(x, y)]
			
			# WARUNEK 2: Kolizja z innym przedmiotem.
			# 'ignore_item' pozwala przedmiotowi "zignorować samego siebie" podczas sprawdzania,
			# co jest kluczowe, gdy przesuwasz przedmiot w obrębie tego samego plecaka (przesuwanie o 1 pole).
			if current_occupant != null and current_occupant != ignore_item:
				return false
				
	return true


# Twardy zapis (Setter)
func place_item(item: ItemData, start_x: int, start_y: int) -> bool:
	# Zawsze weryfikuj przed mutacją (CYA protocol)
	if not can_place_item(item, start_x, start_y):
		return false
		
	var dims: Vector2i = item.get_current_dimensions()
	
	for y in range(start_y, start_y + dims.y):
		for x in range(start_x, start_x + dims.x):
			grid[get_index(x, y)] = item
			
	inventory_updated.emit() # Sygnał dla "głupiego" widoku, aby narysował zawartość
	return true

# Twarde czyszczenie
func remove_item(item: ItemData) -> void:
	for i in range(grid.size()):
		if grid[i] == item:
			grid[i] = null
			
	inventory_updated.emit()
