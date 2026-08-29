# res://addons/tactical_inventory/core/ItemData.gd
extends Resource
class_name ItemData

@export var item_id: String = "base_item"
@export var item_name: String = "Item"
@export var dimensions: Vector2i = Vector2i(1, 1) # (szerokość, wysokość)
@export var texture: Texture2D

var rotated: bool = false

# Oblicza aktualne wymiary z uwzględnieniem rotacji
func get_current_dimensions() -> Vector2i:
	if rotated:
		return Vector2i(dimensions.y, dimensions.x)
	return dimensions
