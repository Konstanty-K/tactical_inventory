# Tactical Inventory Architecture (Component-Based)

## 1. Scope and Boundaries (Separation of Concerns)
This addon is strictly a **low-level UI API and spatial mathematics engine**.
* **What it does:** Manages 2D grid arrays (Bounding Box collision), Drag & Drop state machines, spatial queries, and data compression (Stack merging).
* **What it DOES NOT do:** It does not define game mechanics (e.g., HP, durability, armor classes, game rules), inputs (like pressing 'I' to open), or item spawning.
The host game uses this addon as modular "Lego bricks" to construct its own specific HUD and logic.

## 2. Data Engineering (Composition over Inheritance)
The system strictly rejects OOP inheritance trees in favor of an Entity-Component-System (ECS) paradigm.
* **`ItemData` (Resource):** A purely "dumb" data bus. It stores only basic metadata (ID, Name, Texture) and an array of `ItemComponent` resources.
* **Components:** Behavior is injected via modular components (e.g., `GridShapeComponent` for dimensions, `StackComponent` for quantities).
* **Agnosticism:** Domain-specific modules (like `HealthComponent`) are created in the host game and injected into `ItemData`. The addon ignores them unless strictly required for uniqueness checks during merging.

## 3. Spatial Topology (Allocation Nodes)
The system defines two mutually exclusive spatial paradigms (XOR):
* **Grid Inventory (2D Space):** Quantized spatial allocation based on X,Y coordinates. Determines geometric collisions using `GridShapeComponent`.
* **Equipment Slot (Dimensionless):** Ignores physical dimensions completely. Accepts an item strictly if its properties match the slot's predefined Bitmask filters (e.g., `WEAPON_PRIMARY`, `HEAD_GEAR`). 

## 4. Recursion & Data Integrity
Items can contain their own `InventoryData` instances via a `ContainerComponent` (e.g., backpacks, tactical vests).
* **The "Bag of Holding" Problem (DAG Validation):** Placing Backpack A inside Backpack A causes a recursive memory crash. The drop sequence implements a Directed Acyclic Graph (DAG) validation algorithm. A drop is strictly rejected if the target base ID exists anywhere in the item's descendant chain.
* **Filter Passing:** Parent containers can enforce strict acceptance filters onto their sub-grids (e.g., a Medkit container only accepting items with a `MEDICAL` bitmask).

## 5. External Data Rendering (Event-Driven IoC)
To maintain the addon's isolation from the host game's logic, it uses the Inversion of Control (IoC) / Pub-Sub pattern for rendering custom data.
* **Signal Broadcast:** Upon generating a graphical `ItemUI` node, the addon emits a global signal: `item_visuals_requested(item_ui_node, item_data)`.
* **Host Injection:** The host game listens to this signal. If it detects game-specific components (e.g., 0 HP in a `HealthComponent`), it dynamically injects its own UI nodes (like red damage overlays or HP bars) as children of the `item_ui_node`.

## 6. Interface Architecture (Window Management)
* **Draggable Panels:** Grid and Slot views are encapsulated in independent `PanelContainer` modules capable of being dragged across the screen.
* **Z-Index Stack:** A global window manager handles panel focus. Pressing `ESC` emits a hard signal to `hide()` or destroy the panel with the highest Z-Index priority.

## 7. Algorithms & Persistence (Serialization)
* **Auto-Sort (Bin Packing):** Inventory sorting uses a heuristic algorithm: sorting the item list by bounding box area descending, then attempting allocation from index `[0,0]` to `[N,M]`.
* **Persistent State:** Recursive JSON serialization of the data layer. Converting `Vector2i` coordinates to flat 1D array indices facilitates deterministic state reconstruction upon loading.
