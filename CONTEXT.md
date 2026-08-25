# BlackJ — project context

Blackjack for mobile and desktop, built in Godot 4.7. This file records the current state: what already works, how scenes and scripts are structured, and what is still missing.

**Language:** comments, docs, and commit messages are written in English.

## Goal

Ship a full Blackjack game that plays the same on a phone (tap) and on desktop (mouse). Right now this is a scaffold: a menu, a table, deck generation, and a card UI stub. There is no gameplay round yet (bets, deal, Hit/Stand, dealer, result).

## Engine and settings

- Godot **4.7**, **GL Compatibility** renderer (desktop and mobile).
- Startup scene: `menu.tscn` (`project.godot` → `run/main_scene`).
- Window: `canvas_items` + `aspect=expand` — the scene scales to different resolutions.
- 3D physics (Jolt) comes from the project template and is unused.
- Project icon is the default Godot `icon.svg`, not branded.

## What is already done

### Main menu (`menu.tscn` + `menu.gd`)

- Full-screen dark background (`ColorRect`).
- Logo `assets/bj_logo.png` in the top panel.
- **START** → `main_level.tscn`.
- **EXIT** → `get_tree().quit()`.
- Button styles are set by hand (gold `StyleBoxFlat`, dark text).

### Table (`main_level.tscn` + `main_level.gd`)

- Full-screen table background `assets/table.png`.
- **TO MENU** → back to `menu.tscn`.
- Child node `DeckManager` uses `scripts/deck_manager.gd`.
- Entering the scene generates the deck and shuffles it immediately (`DeckManager._ready`).
- No hands, score, chips, or action buttons on the table yet.

### Card data (`scripts/card_data.gd`)

`CardData` resource:

| Field       | Type          | Meaning                                      |
|-------------|---------------|----------------------------------------------|
| `card_name` | `String`      | Rank: Ace, 2…10, Jack…King                   |
| `suit`      | `String`      | Spades / Hearts / Diamonds / Clubs           |
| `value`     | `int`         | Blackjack value: 2–10, faces = 10, Ace = 11  |
| `texture`   | `AtlasTexture`| Cropped region from the spritesheet          |

Ace is always 11. Soft/hard Ace (11 ↔ 1) is not implemented.

### Deck (`scripts/deck_manager.gd`)

- Builds a standard **52-card** deck from `assets/cards/card-deck.png`.
- Grid: **13 columns × 4 rows** (rank × suit).
- Rows: Spades, Hearts, Diamonds, Clubs.
- Columns: Ace, 2–10, Jack, Queen, King.
- Each card gets an `AtlasTexture` with its region on the sheet.
- `shuffle_deck()` calls `Array.shuffle()`.
- No `draw_card()`, discard pile, multi-deck shoe, or discard tracking.

### Card UI (`card_ui.gd` + `card_ui.tscn`)

`CardUI` class (`Control`):

- `data: CardData` updates the texture.
- `is_face_up` toggles face / back `assets/cards/cards-back.png`.
- `card_pressed(card: CardUI)` fires on left click; on mobile a tap arrives as the same left-button event.
- **Scene is incomplete:** `card_ui.tscn` has no child `TextureRect`, but the script expects `$TextureRect`. Instantiating it as-is will fail.
- No card is spawned on the table yet.

## Assets

| File | Purpose |
|------|---------|
| `assets/bj_logo.png` | Menu logo |
| `assets/table.png` | Table background |
| `assets/cards/card-deck.png` | 13×4 face spritesheet |
| `assets/cards/cards-back.png` | Card back |
| `icon.svg` | Project icon (Godot default) |

Keep the matching `.import` files in git. Compiled `.ctex` files live under `.godot/` and stay out of the repo.

## What is not done yet

- Deal to player and dealer, including the dealer's hole card.
- Hit / Stand / Double / Split / Insurance buttons.
- Scoring, soft Ace, Blackjack, Bust, Push.
- Bets, bankroll, chips.
- Deal and flip animations.
- Adaptive layout for portrait/landscape (buttons use absolute offsets).
- Audio, localization, saves.
- Export presets for Android / iOS / desktop.

## Draft files (not on the play path)

Early editor stubs. The main scene does not reference them. Safe to delete later or reuse.

- `main.tscn` + `main.gd` — empty `MainTable`, only `print("It works")`.
- Root `deck_manager.gd` — stub `print("DM works")`. The real manager is `scripts/deck_manager.gd`.
- `control.gd` — draft that `extends` the real `deck_manager.gd`.

Root names collide with the working scripts. Put new types under `scripts/` and do not add a second `deck_manager.gd`.

## Scene map

```
menu.tscn          ← entry point
  └─ START  → main_level.tscn
  └─ EXIT   → quit

main_level.tscn
  ├─ TextureRect (table)
  ├─ Button TO MENU → menu.tscn
  └─ DeckManager (scripts/deck_manager.gd)
       └─ generate + shuffle 52 CardData
```

## Conventions for later work

- Engine: Godot 4.7, GDScript. `CardData` and `CardUI` already have `class_name`.
- Write comments, docs, and commit messages in English.
- Commit `*.gd.uid` and `*.import` next to their sources. Do not gitignore `*.uid`.
- Do not commit `.godot/`.
- Wire input through `_gui_input` / button signals so tap and click behave the same.
- Keep Blackjack rules out of menu scenes. Deal and scoring belong in scripts next to `scripts/`.
- Next sensible step: fix `card_ui.tscn` (add `TextureRect`), teach the deck to deal a card, lay out two hands, and hook Hit/Stand.

## Git

Keep out of the repo: `.godot/`, `.DS_Store`, Android/iOS build folders, `export_credentials.cfg`, export binaries (`*.apk`, `*.pck`, `*.exe`, and similar). Full list is in `.gitignore`.
