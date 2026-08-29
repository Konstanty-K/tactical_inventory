class_name StackComponent
extends ItemComponent

@export var max_stack: int = 100
var current_stack: int = 1

## Obsługuje amunicję, monety i stosy. Jeśli przedmiot go nie posiada, 
## system uznaje go za unikalny (1/1).
