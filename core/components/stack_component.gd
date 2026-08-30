class_name StackComponent
extends ItemComponent
## Obsługuje amunicję, monety i stosy. Jeśli przedmiot go nie posiada, 
## system uznaje go za unikalny (1/1).

@export var max_stack: int = 100
var current_stack: int = 1

# Zwraca resztę (ile nie zmieściło się w docelowym stosie)
func add_amount(amount: int) -> int:
	var space_left = max_stack - current_stack
	var transfer = min(space_left, amount)
	current_stack += transfer
	return amount - transfer
	
