# BlackJ — project context

Blackjack for mobile and desktop, built in Godot 4.7. This file records the current state: what already works, how scenes and scripts are structured, and what is still missing.

**Language:** comments, docs, and commit messages are written in English.

## Goal

Ship a Blackjack game that plays the same on a phone (tap) and on desktop (mouse). First ship a **classic table prototype**. A **Duel** mode (alternating hits, late raise) is a later, separate mode — do not mix those rules into the prototype.

## Game concept (locked)

Classic Blackjack, one player vs a computer dealer. Locked for the first playable prototype. Change this section only if the rules change on purpose.

### Bank and bets

- Player starts a session with **$100**.
- Before each round the player picks a bet: **$10 / $25 / $50**.
- Bet cannot exceed remaining credit. If credit is **$0**, the session ends (or offer a refill later — not in v1).
- Payouts for v1: win pays **1:1**, natural Blackjack also **1:1**, push returns the bet. 3:2 on Blackjack can wait.

### Visibility (who sees what)

- Player cards are **face up**. The player must see their hand. Showing them on the table is fine and matches a shoe game.
- Dealer: one card **face up**, one **hole card** face down until the dealer plays / the round resolves.
- The player sees the dealer's up card and never the hole card until reveal.
- Fair dealer means the AI **does not read the player's hand**. It only uses its own total and the house rule. Do not hide the player's cards from the screen to achieve that.

### Deal

- After the bet: two cards to the player (face up), two to the dealer (one up, one down).
- Deck is `Array[CardData]`. Instantiate `CardUI` only for cards that leave the deck.

### Natural Blackjack

- Ace + 10-value on the **first two cards** is a natural.
- If the player has a natural and the dealer does not → player wins immediately (no Hit/Stand).
- If both have a natural → push.
- If only the dealer has a natural → player loses immediately.
- 21 from three or more cards is not a natural.

### Player turn

- Actions: **Hit** or **Stand** only.
- Player hits until they stand or bust (**total > 21**).
- Bust → player loses immediately. Dealer does not play.
- No Double, Split, Insurance, or late raise in this mode.

### Dealer turn

- Runs only if the player stood without busting.
- Hole card is revealed, then the dealer plays.
- House rule: **hit while total is below 17**, **stand on 17 or more** (including soft 17 for v1).
- Dealer AI must not inspect player cards or player total.

### Scoring

- Ace counts as **11**, or **1** when 11 would bust (soft/hard Ace).
- After both have finished: higher total **≤ 21** wins.
- Same total → **push**.
- If the dealer busts and the player did not → player wins.

### Round loop

1. Choose bet (if credit allows).
2. Deal.
3. Resolve naturals if any.
4. Player Hit/Stand (or already lost on bust).
5. Dealer plays if needed.
6. Compare, pay, return cards / rebuild the deck as needed.
7. Next round.

### Out of scope (later)

- **Duel mode:** alternating Hit/Stand, then a late raise (nothing / +10 / +25 / +50 / ×2). Separate rules, separate flow.
- Split, Insurance, Double Down, 3:2 Blackjack, multi-deck shoe, chip animations.

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
- **TO MENU** (top-right) → back to `menu.tscn`.
- Child node `DeckManager` uses `scripts/deck_manager.gd`.
- Entering the scene generates the deck and shuffles it immediately (`DeckManager._ready`).
- Session start: modal confirms **$100** starting credit. OK awards `credit`, shows **Credit: $N** top-left, and reveals the face-down deck pile (right side, `card_back.tres`).
- Credit stays `0` until OK. The overlay blocks the table until then.
- No hands, bet chips, or Hit/Stand yet.

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

- Scene root is `CardUI` (`Control`) with `card_ui.gd`. Child `TextureRect` draws the face or back.
- Fixed size `120×223` (`CARD_SIZE`) — same aspect as one cell of `card-deck.png`.
- Face texture comes from `CardData.texture` (cut in `DeckManager`).
- Back texture is `assets/cards/card_back.tres` (`AtlasTexture` over `cards-back.png`). Region is already cropped in the editor.
- `card_pressed(card: CardUI)` fires on left click; on mobile a tap arrives as the same left-button event.
- No card is spawned on the table yet.

## Assets

| File | Purpose |
|------|---------|
| `assets/bj_logo.png` | Menu logo |
| `assets/table.png` | Table background |
| `assets/cards/card-deck.png` | 13×4 face spritesheet |
| `assets/cards/cards-back.png` | Card-back spritesheet (several designs) |
| `assets/cards/card_back.tres` | AtlasTexture for one cropped card back |
| `icon.svg` | Project icon (Godot default) |

Keep the matching `.import` files in git. Compiled `.ctex` files live under `.godot/` and stay out of the repo.

## What is not done yet

- Round flow from the locked concept: bet → deal → naturals → Hit/Stand → dealer rule → payout.
- Soft Ace (11 ↔ 1), bust, push, natural vs 21 from extra cards.
- Bet buttons ($10 / $25 / $50) after the deck is on the table.
- Spawn `CardUI` only for dealt cards; dealer hole card uses `is_face_up = false`.
- Deal and flip animations.
- Adaptive layout for portrait/landscape (buttons use absolute offsets).
- Duel mode.
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
  ├─ CreditLabel (hidden until OK)
  ├─ Button TO MENU → menu.tscn
  ├─ DeckPile (hidden until OK, card_back.tres)
  ├─ DeckManager (scripts/deck_manager.gd)
  │    └─ generate + shuffle 52 CardData
  └─ CreditDialog → OK awards $100, shows credit + deck
```

## Conventions for later work

- Engine: Godot 4.7, GDScript. `CardData` and `CardUI` already have `class_name`.
- Write comments, docs, and commit messages in English.
- Commit `*.gd.uid` and `*.import` next to their sources. Do not gitignore `*.uid`.
- Do not commit `.godot/`.
- Wire input through `_gui_input` / button signals so tap and click behave the same.
- Keep Blackjack rules out of menu scenes. Deal, scoring, and dealer AI belong in scripts next to `scripts/`.
- Dealer AI may use only the dealer hand and the hit-below-17 rule.
- Next sensible step: bet buttons ($10 / $25 / $50), then deal two hands from the pile.

## Git

Keep out of the repo: `.godot/`, `.DS_Store`, Android/iOS build folders, `export_credentials.cfg`, export binaries (`*.apk`, `*.pck`, `*.exe`, and similar). Full list is in `.gitignore`.
