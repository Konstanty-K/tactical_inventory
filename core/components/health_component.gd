class_name HealthComponent 
extends ItemComponent
## Hermetyzuje podatność na obrażenia (od pożaru w plecaku po postrzał).

# Wartości bazowe przeskalowane x10 (1000 = 100.0 HP)
@export var max_hp_quantized: int = 1000
@export var damage_threshold_quantized: int = 0 
var current_hp_quantized: int = 1000

func apply_damage(amount_quantized: int) -> void:
	# Deterministyczna matematyka na typach całkowitych
	var effective_damage: int = max(0, amount_quantized - damage_threshold_quantized)
	current_hp_quantized -= effective_damage
	
	# Zabezpieczenie przed przepełnieniem w dół
	if current_hp_quantized <= 0:
		current_hp_quantized = 0
		# TODO: Emisja sygnału zniszczenia obiektu

# Interfejs (Getter) wyłącznie dla warstwy Widoku
func get_ui_hp() -> float:
	return float(current_hp_quantized) / 10.0
