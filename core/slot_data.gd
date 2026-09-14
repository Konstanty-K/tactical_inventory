class_name SlotData
extends Resource

signal slot_updated

# Jakich typów przedmiotów oczekuje to gniazdo?
@export_flags("Headgear", "Body_Armor", "Weapon_Primary", "Weapon_Secondary", "Consumable", "Container") 
var accepted_categories: int = 0

var held_item: ItemData = null

# Weryfikacja typu metodą koniunkcji logicznej (AND)
func can_accept_item(item: ItemData) -> bool:
	if held_item != null:
		return false # Slot jest zajęty
		
	var type_comp = item.get_component(EquipmentTypeComponent) as EquipmentTypeComponent
	if type_comp == null:
		return false # Przedmiot bez zdefiniowanego typu nie wejdzie do rygorystycznego slotu
		
	# Operacja bitowa: Czy przynajmniej jedna z flag przedmiotu pokrywa się z flagami slota?
	return (type_comp.category_flags & accepted_categories) != 0

func place_item(item: ItemData) -> bool:
	if can_accept_item(item):
		held_item = item
		slot_updated.emit()
		return true
	return false

func remove_item() -> ItemData:
	var item = held_item
	held_item = null
	slot_updated.emit()
	return item
