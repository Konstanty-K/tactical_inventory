# res://addons/tactical_inventory/core/InventoryData.gd
extends Resource
class_name InventoryData

signal inventory_updated # UI nasłuchuje tego sygnału, by się przerysować

@export var grid_width: int = 10:
	set(value):
		grid_width = max(1, value)
		_rebuild_grid()

@export var grid_height: int = 10:
	set(value):
		grid_height = max(1, value)
		_rebuild_grid()

# Tablica przetrzymująca stan siatki. Rozmiar: grid_width * grid_height
# Puste pole = null. Zajęte pole = referencja do obiektu ItemData.
var grid: Array[ItemData] = []

func _init() -> void:
	_rebuild_grid()

# Hard reset tablicy przy każdej zmianie rozmiaru
func _rebuild_grid() -> void:
	var expected_size = grid_width * grid_height
	if grid.size() != expected_size:
		grid.resize(expected_size)
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


func get_item_position(item: ItemData) -> Vector2i:
	for y in range(grid_height):
		for x in range(grid_width):
			if grid[get_index(x, y)] == item:
				return Vector2i(x, y) #top left
	return Vector2i(-1, -1)


func rotate_item_in_place(item: ItemData) -> bool:
	var pos = get_item_position(item)
	if pos.x == -1: return false
	
	# 1. Usunięcie (zwolnienie blokad)
	remove_item(item)
	
	# 2. Mutacja stanu
	item.rotated = !item.rotated
	
	# 3. Weryfikacja
	if can_place_item(item, pos.x, pos.y):
		place_item(item, pos.x, pos.y)
		return true
		
	# 4. Rollback (brak miejsca)
	item.rotated = !item.rotated
	place_item(item, pos.x, pos.y)
	return false

##==============================================================================
# Heurystyczny algorytm Auto-Sort (wymagany m.in. dla botów i optymalizacji gracza)
func sort_inventory() -> void:
	# 1. Zbieramy unikalne obiekty z przestrzeni
	var items: Array[ItemData] = []
	for item in grid:
		if item != null and not items.has(item):
			items.append(item)
			
	# 2. Twardy reset matrycy (zwalniamy pamięć alokacji)
	grid.fill(null)
	
	# 3. Sortowanie: Najcięższe przestrzennie (pole powierzchni) na początek
	items.sort_custom(func(a: ItemData, b: ItemData):
		var area_a = a.get_base_dimensions().x * a.get_base_dimensions().y
		var area_b = b.get_base_dimensions().x * b.get_base_dimensions().y
		return area_a > area_b
	)
	
	# 4. Kaskadowa alokacja
	for item in items:
		item.rotated = false # Resetujemy rotację dla czystego wyniku
		var success = add_item_auto(item)
		if not success:
			# Tu w przyszłości wywołasz sygnał "World Drop" jeśli kompresja wyrzuci błąd
			printerr("Krytyczny błąd alokacji: Brak miejsca na " + item.item_name)
			
	inventory_updated.emit()

# Funkcja bezpiecznego "Zrzutu" w dowolne wolne miejsce
func add_item_auto(item: ItemData) -> bool:
	var pos = _find_first_free_spot(item)
	if pos.x != -1:
		return place_item(item, pos.x, pos.y)
		
	# Protokół awaryjny: Próba obrotu o 90 stopni, jeśli natywny kształt nie wchodzi
	item.rotated = not item.rotated
	pos = _find_first_free_spot(item)
	if pos.x != -1:
		return place_item(item, pos.x, pos.y)
		
	# Rollback rotacji w przypadku absolutnego braku miejsca
	item.rotated = not item.rotated
	return false

# Ślepe skanowanie siatki (O(N))
func _find_first_free_spot(item: ItemData) -> Vector2i:
	var dims = item.get_current_dimensions()
	# Optymalizacja wektora Y/X: Pętla nie skanuje krawędzi, gdzie bryła od razu by wystawała
	for y in range(grid_height - dims.y + 1):
		for x in range(grid_width - dims.x + 1):
			if can_place_item(item, x, y):
				return Vector2i(x, y)
	return Vector2i(-1, -1)
