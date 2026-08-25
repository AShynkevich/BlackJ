---
name: gamedev-patterns
description: >-
  Use game-dev design patterns that fit Godot 4 and BlackJ. Use when implementing
  rounds, input, card spawning, dealer AI, state flow, or the user mentions
  patterns, FSM, observer, command, pool, or composition.
---

# Game-dev patterns (this project)

Use a pattern when it removes a real tangle. Godot scenes + signals are the default.

## Use now

**Composition (scene + data)**  
`CardData` is data. `card_ui.tscn` is the view. Instantiate a view only for cards that left the deck.

**Observer (signals)**  
Buttons and `CardUI.card_pressed` are the event path. Same for tap and click. Do not poll in `_process`.

**State as an explicit phase**  
Session phases are already implicit: credit dialog → betting → dealt. When Hit/Stand arrives, make a small enum (`Betting`, `PlayerTurn`, `DealerTurn`, `Resolve`) on the table/round script. Hide illegal buttons for the current phase. Do not start a full FSM plugin.

## Use when the classic round needs them

**Strategy**  
Dealer action = one function: hit below 17. Swap later for another rule without reading the player hand.

**Command** (optional)  
Hit / Stand as two functions called from buttons. Enough. Do not queue a command stack unless you add replay/undo.

## Do not add yet (YAGNI)

| Pattern | Why not now |
|---------|-------------|
| Object pool | Four cards on table. `queue_free` is fine. |
| Autoload singleton | Session state still lives on `main_level`. |
| Event bus | Node signals reach the parent. |
| MVC / ECS | Overkill for one table. |
| Double-buffer / dirty-rect | 2D Control UI. |

## Godot-specific

- Prefer child nodes and `@onready` over finding nodes by long paths from other scenes.
- Prefer `change_scene_to_file` for menu ↔ table. Do not keep a hidden table under the menu.
- One `DeckManager` node. Do not spawn 52 `CardUI` in the shoe.
