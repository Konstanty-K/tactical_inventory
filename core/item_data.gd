class_name ItemData
extends Resource

@export var item_id: String = ""
@export var item_name: String = "Nieznany Przedmiot"
@export var texture: Texture2D
# Wstrzykiwanie komponentów z poziomu Inspektora Godot
@export var components: Array[ItemComponent] = []

var rotated: bool = false

# Wyszukiwanie komponentu w locie
func get_component(component_class: Script) -> ItemComponent:
	for comp in components:
		if comp.get_script() == component_class:
			return comp
	return null

# Zaktualizowana funkcja pobierająca wymiary z komponentu, wliczająca rotację
func get_current_dimensions() -> Vector2i:
	var shape = get_component(GridShapeComponent) as GridShapeComponent
	var dims = shape.dimensions if shape != null else Vector2i(1, 1) # Minimalny wymiar to 1x1
	
	if rotated:
		return Vector2i(dims.y, dims.x)
	return dims

# Pobiera surowe wymiary z komponentu (niezbędne do renderowania Wrappera)
func get_base_dimensions() -> Vector2i:
	var shape = get_component(GridShapeComponent) as GridShapeComponent
	return shape.dimensions if shape != null else Vector2i(1, 1)
