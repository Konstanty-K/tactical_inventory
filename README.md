# Tactical Inventory System

Skalowalny, deterministyczny system ekwipunku typu grid-based (Tarkov/XCOM) dla silnika Godot 4. Zbudowany w oparciu o ścisły paradygmat MVC i bezstanowe operacje sprzętowe.

## Główne Założenia (Core Tenets)
* **Wzorzec MVC:** Pełna separacja twardych danych (Model), logiki (Kontroler) i renderowania (Widok).
* **Zero Node Overhead:** Główny Menedżer to klasa statyczna, niewymagająca dodawania do drzewa SceneTree (AutoLoad).
* **Hardware Scaling:** Automatyczne rzutowanie wektorowe tekstur komórek przez GPU.
* **Hybrid Input:** Obsługa stanu Pick-and-Place oraz Drag-and-Drop sterowana progiem 200ms.

## Struktura Katalogów
* `core/` - Niezależne od sceny Modele (ItemData, InventoryData) oraz statyczny Kontroler.
* `ui/` - Reaktywne Widoki (Siatka, Podgląd Przedmiotu) oparte na klasie Control.
* `assets/` - Surowe pliki graficzne bazy.
* `docs/` - Rejestr decyzji architektonicznych (ADR) i diagramy przepływu.
