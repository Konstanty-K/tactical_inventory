class_name EquipmentTypeComponent
extends ItemComponent

# Używamy flag bitowych (Bitmask), aby jeden przedmiot mógł pasować do wielu typów slotów
# Godot automatycznie wygeneruje wygodne checkboxy w Inspektorze
@export_flags("Headgear", "Body_Armor", "Weapon_Primary", "Weapon_Secondary", "Consumable", "Container") 
var category_flags: int = 0
