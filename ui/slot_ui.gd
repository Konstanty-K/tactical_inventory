class_name SlotUI
extends Control

@export var slot_data: SlotData
@export var background_texture: Texture2D
@export var item_ui_scene: PackedScene 

var current_item_ui: ItemUI = null
var _show_highlight: bool = false
var _highlight_valid: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(64, 64) 
	size = custom_minimum_size
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	if slot_data != null:
		slot_data.slot_updated.connect(_on_slot_updated)

func _on_mouse_entered() -> void:
	InventoryDragManager.set_hovered_slot(self)

func _on_mouse_exited() -> void:
	InventoryDragManager.clear_hovered_slot(self)

func draw_highlight(is_valid: bool) -> void:
	_show_highlight = true
	_highlight_valid = is_valid
	queue_redraw()

func clear_highlight() -> void:
	if _show_highlight:
		_show_highlight = false
		queue_redraw()

func _on_slot_updated() -> void:
	if current_item_ui != null:
		current_item_ui.queue_free()
		current_item_ui = null
		
	if slot_data.held_item != null and item_ui_scene != null:
		current_item_ui = item_ui_scene.instantiate() as ItemUI
		add_child(current_item_ui)
		current_item_ui.init_item(slot_data.held_item)
		
		# --- ALGORYTM SKALOWANIA W GNIEŹDZIE ---
		var item_size = current_item_ui.size
		# Szukamy najmniejszego współczynnika skali, aby zmieścić X lub Y
		var scale_factor = min(size.x / item_size.x, size.y / item_size.y)
		scale_factor *= 0.9 # Zostawiamy 10% marginesu na krawędziach
		
		current_item_ui.scale = Vector2(scale_factor, scale_factor)
		
		# Wyśrodkowanie uwzględniające nową, przeskalowaną wielkość
		var scaled_size = item_size * scale_factor
		current_item_ui.position = (size - scaled_size) / 2.0

func _draw() -> void:
	if background_texture != null:
		draw_texture_rect(background_texture, Rect2(Vector2.ZERO, size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.1, 0.8))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.3, 0.3, 1.0), false, 2.0)
		
	if _show_highlight:
		var color = Color(0.0, 1.0, 0.0, 0.3) if _highlight_valid else Color(1.0, 0.0, 0.0, 0.3)
		draw_rect(Rect2(Vector2.ZERO, size), color)
