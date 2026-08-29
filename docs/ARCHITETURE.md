# Architektura Systemu Ekwipunku (Wersja 2.0)

## 1. Topologia Przestrzeni (Węzły Alokacji)
System porzuca monolityczną siatkę. Wprowadzamy dwa rygorystycznie wykluczające się typy przestrzeni (XOR):
*   **Grid Inventory (Siatka 2D):** Kwantyzacja przestrzeni oparta na współrzędnych X,Y. Determinuje kolizje geometryczne.
*   **Equipment Slot (Gniazdo Ekwipunku):** Przestrzeń bezwymiarowa. Ignoruje Bounding Box (`dimensions`). Akceptuje wyłącznie obiekt, którego typ (ItemType) zgadza się z wymaganą maską bitową gniazda. Wymusza przeliczanie statystyk postaci.

## 2. Typowanie i Dziedziczenie Przedmiotów
Aby obsłużyć filtrowanie i restrykcje, Model `ItemData` przechodzi w system klasowy.
*   **Kategoryzacja:** Enumeryczne flagi bitowe (np. `WEAPON_PRIMARY`, `ARMOR_HEAD`, `CONSUMABLE`, `CONTAINER`).
*   **Dynamiczna Waga:** Wartość skalarna aktualizowana rekurencyjnie, sumująca wagę własną przedmiotu z masą jego wewnętrznego inwentarza.
*   **Zarządzanie Stosem (Stacking):** Obiekty wymieniają właściwość boolowską "unikalności" na liczbową pojemność maksymalną. Silnik musi rozróżniać próbę upuszczenia (Drop) od próby fuzji (Merge).

## 3. Zagnieżdżanie i Integralność Danych (Rekurencja)
Przedmiot może posiadać własną instancję `InventoryData` (np. kamizelka taktyczna, plecak).
*   **Problem "Bag of Holding" (Wąskie Gardło):** Włożenie plecaka A do plecaka A zniszczy pamięć w nieskończonej pętli. System zrzutu musi implementować weryfikację drzewa za pomocą Skierowanego Grafu Acyklicznego (DAG). Przedmiot odrzuca zrzut, jeśli identyfikator docelowej bazy znajduje się w łańcuchu jego potomków.
*   **Filtry Warstwy Danych:** Kontener nadrzędny może zablokować przyjmowanie określonych pod-typów (np. apteczka przyjmuje tylko medykamenty).

## 4. Architektura Interfejsu (Draggable Windows)
Każdy widok siatki/gniazd jest osadzony w niezależnym module `PanelContainer`.
*   **Globalny Menedżer Okien:** Rejestruje aktywne panele w stosie Z-Index. Naciśnięcie `ESC` wyzwala twardy sygnał zamknięcia (zrzut z pamięci lub `hide()`) dla panelu o najwyższym priorytecie.
*   **Reaktywne Filtrowanie:** Szukanie tekstowe lub bitowe nakłada na obiekty `ItemUI` zmianę właściwości `modulate` (wyszarzanie) i wyłącza im `mouse_filter`, bez modyfikowania struktury bazy danych.

## 5. Algorytmika i Zapis (Serialization & Bots)
*   **Auto-Sort i AI:** Pakowanie ekwipunku to klasyczny "Bin Packing Problem". Zostanie wdrożony algorytm heurystyczny: sortowanie listy przedmiotów po polu powierzchni malejąco, a następnie próba alokacji od indeksu `0,0` do `N,M`. Silnik działa bezgłowo (Headless) dla NPC.
*   **Stan Trwały (Save):** Rekurencyjna serializacja bazy do formatu JSON. Konwersja wektorów `Vector2i` na jednoznaczne indeksy tablicy ułatwia odbudowę stanu po restarcie gry.
