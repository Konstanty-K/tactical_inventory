# ADR 0002: Item Database Architecture, CSV Pipeline, and Façade Pattern

## 1. Context and Problem Statement
The game requires a highly scalable, isolated system to store, query, and manage item definitions (blueprints). We need a single source of truth for balancing (game design) and a highly optimized runtime format. The database module must be 100% decoupled from the inventory UI and spatial logic, enabling parallel development by independent teams (or independent AI sessions).

## 2. Decision: Data Pipeline (CSV -> SQLite/JSON)
We will implement a unidirectional Data Pipeline and a decoupled Façade pattern.

*   **Design Layer (Source of Truth):** `.csv` files. Game designers edit item stats, dimensions, and bitmasks in spreadsheets.
*   **Build Layer:** A dedicated script (`csv_to_db_compiler.py` or `.gd`) that parses `.csv` files and compiles them into a runtime-optimized format (SQLite `.db` file or static `.json` dictionaries).
*   **Runtime Layer:** A read-only SQLite database or in-memory Dictionary graph.

## 3. The Contract (API Façade)
The Database Module will expose a strict API (Façade). It will have zero dependencies on Godot UI nodes or the `tactical_inventory` addon. It operates exclusively on primitive data types (Strings, Ints, Arrays, Dictionaries).

### Interface Prototype: `ItemDatabaseFacade`
```gdscript
# This is the ONLY script the host game or inventory addon interacts with.
class_name ItemDatabaseFacade

# Queries the DB and returns a raw, agnostic Dictionary of properties.
# Returns empty Dictionary {} if item_id is invalid.
func get_item_blueprint(item_id: String) -> Dictionary:
	pass

# Returns an array of item IDs that match a specific type (e.g., for loot tables).
func get_items_by_type(bitmask_flag: int) -> Array[String]:
	pass
Agnostic Output Format (Contract Example)
When get_item_blueprint("wpn_ak47") is called, the database module MUST return a pure dictionary exactly like this:

JSON
{
  "id": "wpn_ak47",
  "name": "AK-47 Assault Rifle",
  "grid_width": 6,
  "grid_height": 2,
  "type_bitmask": 4,
  "max_stack": 1,
  "texture_path": "res://assets/items/ak47.png",
  "components": {
	"health": { "max_hp": 1000 },
	"weapon": { "damage": 45, "rpm": 600 }
  }
}
4. Architectural Boundaries (XOR Rule)
The Database Module: Knows HOW to read SQLite/JSON and HOW to parse CSV. It does NOT know what an ItemData resource or GridShapeComponent is.

The Game Core (Factory): Queries the ItemDatabaseFacade. It takes the raw Dictionary output and translates it into Godot Resources (ItemData and components) to feed into the tactical_inventory.

5. Consequences
Pros: Total isolation. The database module can be unit-tested entirely in the terminal without booting the Godot renderer. Can be outsourced to another developer/AI without sharing the main repository.

Cons: Requires maintaining the converter script (CSV to DB) whenever a new data column is added to the game design.
