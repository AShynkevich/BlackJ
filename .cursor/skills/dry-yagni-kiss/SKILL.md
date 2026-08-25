---
name: dry-yagni-kiss
description: >-
  Apply DRY, YAGNI, and KISS when writing or refactoring BlackJ / Godot code.
  Use when adding features, cleaning scripts, reviewing structure, or the user
  mentions DRY, YAGNI, KISS, duplication, overengineering, or simplicity.
---

# DRY, YAGNI, KISS

Follow these on every change. Prefer the smallest change that matches locked rules in `CONTEXT.md`.

## KISS

- One script, one job. Menu changes scenes. Table runs the session. `DeckManager` owns the shoe.
- Prefer a function over a new class. Prefer a class over a framework.
- Godot already has signals, groups, and scenes. Do not invent a custom event bus.

## YAGNI

- Do not build Duel, Split, Insurance, Double, pools, or autoloads until the classic round needs them.
- Do not add `class_name` / autoload / "manager" nodes for a single call site.
- Do not keep unused stubs "for later". Delete them.

## DRY

- Duplicate **behavior** once it appears a second time (bet buttons, spawning `CardUI`, credit text). Two similar lines are fine; three copies of deal/spawn logic are not.
- Do not DRY by accident: shared code must share **meaning**, not just look alike.
- One source of truth: card back is `card_back.tres`, face grid math lives only in `DeckManager`, display size is derived from the back — do not re-crop in `CardUI`.

## Check before adding code

1. Does `CONTEXT.md` already specify this? Implement that, nothing extra.
2. Can an existing node/script do it with a function?
3. If you are about to add a new file, name the second caller. If there is none, keep it in the current script.
