---
name: solid-principles
description: >-
  Apply SOLID when designing Godot / GDScript types in BlackJ. Use when adding
  scripts, splitting responsibilities, wiring dealer AI, scoring, or the user
  mentions SOLID, SRP, OCP, LSP, ISP, DIP, or architecture.
---

# SOLID (Godot / BlackJ)

Map SOLID onto scenes and scripts. Do not add layers that SOLID does not require.

## Single responsibility

| Owner | Owns | Must not own |
|-------|------|----------------|
| `menu.gd` | Scene changes, quit | Bets, deck, scoring |
| `main_level.gd` | Session UI flow (credit → bet → deal) | Face-sheet math, Ace 11↔1 rules long-term |
| `DeckManager` | Build, shuffle, `draw_card` | Hands, bets, who won |
| `CardData` | Rank, suit, value, face texture | Nodes, input, layout |
| `CardUI` | Show one card, tap | Deck, scoring |

When Hit/Stand and scoring land, put **rules** in `scripts/` (hand total, natural, dealer hit-below-17). Keep `main_level.gd` as orchestration + UI.

## Open / closed

- Extend with a new script or a new mode scene. Do not bolt Duel rules onto classic `if`s inside the deal path.
- Dealer policy is a function or small object (`hit if total < 17`). Classic vs later Duel stay separate.

## Liskov

- A `CardData` is always a playable card. Do not subclass it into "UI card" or "hole card". Face-down is `CardUI.is_face_up`.
- Do not make `Control` scripts that only work if the parent is `MainLevel`.

## Interface segregation

- `CardUI` exposes `data`, `is_face_up`, `card_pressed`. Do not add bankroll or bet APIs to it.
- Dealer AI receives **dealer cards / dealer total only**, never the player hand.

## Dependency inversion

- UI depends on `CardData` and signals, not on how the atlas was cut.
- Scoring should depend on card values, not on `TextureRect` nodes.
- Prefer `preload` + `instantiate` of `card_ui.tscn` over baking cards into `main_level.tscn`.
