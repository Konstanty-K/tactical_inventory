---
title: 0001 - Użycie Klasy Statycznej dla Kontrolera Przeciągania
date: 2026-08-29
status: Zaakceptowany
---

## Kontekst
Wtyczka (Addon) wymaga globalnego dostępu do danych o trzymanym przedmiocie w celu komunikacji między wieloma siatkami ekwipunku. Standardowe podejście Godot (AutoLoad Node Singleton) wymusza na użytkowniku ręczną modyfikację plików konfiguracyjnych projektu (`project.godot`), co łamie zasadę hermetyzacji modułu (Plug & Play) i tworzy wąskie gardło przy deinstalacji/instalacji.

## Decyzja
Zastosowano wzorzec statycznego menedżera (`class_name InventoryDragManager extends RefCounted`) operującego wyłącznie na zmiennych i metodach statycznych (`static`).
1. Kontroler nie istnieje fizycznie w drzewie węzłów (SceneTree).
2. Podgląd wizualny (Ghost) jest wstrzykiwany bezpośrednio do głównego Viewportu (`get_tree().root`).
3. Operacje pętli ramki (`process_frame`) są dynamicznie podpinane pod API silnika tylko wtedy, gdy przedmiot jest w ruchu.

## Konsekwencje
**Pozytywne:**
* Zerowy dług instalacyjny (wtyczka działa natychmiast po skopiowaniu folderu).
* Usunięcie narzutu pamięciowego (Zero Overhead) - brak instancji węzła nasłuchującej globalnie.
* Całkowita izolacja przestrzeni nazw bez ukrywania (shadowing) wbudowanych typów.

**Negatywne:**
* Brak bezpośredniego dostępu do węzłów edytora (Inspektora) w celu wizualnego debugowania stanu menedżera. Stan musi być weryfikowany poprzez breakpointy w kodzie.
