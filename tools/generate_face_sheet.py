#!/usr/bin/env python3
"""Build a tight 13x4 face sheet: no gutters, transparent corners."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

# Must match CardUI.CARD_SIZE so faces draw 1:1 and stay sharp.
CARD_W = 120
CARD_H = 180
COLS = 13
ROWS = 4
CORNER = 10

RANKS = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
SUITS = [
    ("Spades", "♠", (28, 28, 28, 255)),
    ("Hearts", "♥", (196, 36, 48, 255)),
    ("Diamonds", "♦", (196, 36, 48, 255)),
    ("Clubs", "♣", (28, 28, 28, 255)),
]

# Relative pip positions inside the card face (x, y).
PIP_LAYOUTS: dict[int, list[tuple[float, float]]] = {
    1: [(0.50, 0.50)],
    2: [(0.50, 0.24), (0.50, 0.76)],
    3: [(0.50, 0.24), (0.50, 0.50), (0.50, 0.76)],
    4: [(0.32, 0.24), (0.68, 0.24), (0.32, 0.76), (0.68, 0.76)],
    5: [(0.32, 0.24), (0.68, 0.24), (0.50, 0.50), (0.32, 0.76), (0.68, 0.76)],
    6: [
        (0.32, 0.24),
        (0.68, 0.24),
        (0.32, 0.50),
        (0.68, 0.50),
        (0.32, 0.76),
        (0.68, 0.76),
    ],
    7: [
        (0.32, 0.24),
        (0.68, 0.24),
        (0.50, 0.37),
        (0.32, 0.50),
        (0.68, 0.50),
        (0.32, 0.76),
        (0.68, 0.76),
    ],
    8: [
        (0.32, 0.22),
        (0.68, 0.22),
        (0.50, 0.36),
        (0.32, 0.50),
        (0.68, 0.50),
        (0.50, 0.64),
        (0.32, 0.78),
        (0.68, 0.78),
    ],
    9: [
        (0.32, 0.20),
        (0.68, 0.20),
        (0.32, 0.38),
        (0.68, 0.38),
        (0.50, 0.50),
        (0.32, 0.62),
        (0.68, 0.62),
        (0.32, 0.80),
        (0.68, 0.80),
    ],
    10: [
        (0.32, 0.18),
        (0.68, 0.18),
        (0.50, 0.30),
        (0.32, 0.38),
        (0.68, 0.38),
        (0.32, 0.62),
        (0.68, 0.62),
        (0.50, 0.70),
        (0.32, 0.82),
        (0.68, 0.82),
    ],
}

FONT_DIR = Path("/System/Library/Fonts/Supplemental")
RANK_FONT = FONT_DIR / "Arial Bold.ttf"
SUIT_FONT = FONT_DIR / "Arial Unicode.ttf"
OUT_PATH = Path(__file__).resolve().parents[1] / "assets" / "cards" / "card-deck.png"


def _font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size)


def _draw_centered(
    draw: ImageDraw.ImageDraw,
    xy: tuple[float, float],
    text: str,
    font: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int, int],
) -> None:
    box = draw.textbbox((0, 0), text, font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    draw.text((xy[0] - w / 2 - box[0], xy[1] - h / 2 - box[1]), text, font=font, fill=fill)


def _draw_card(rank: str, suit: str, color: tuple[int, int, int, int]) -> Image.Image:
    card = Image.new("RGBA", (CARD_W, CARD_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(card)
    inset = 1
    draw.rounded_rectangle(
        (inset, inset, CARD_W - 1 - inset, CARD_H - 1 - inset),
        radius=CORNER,
        fill=(252, 250, 246, 255),
        outline=(36, 36, 36, 255),
        width=2,
    )

    rank_font = _font(RANK_FONT, 22 if rank != "10" else 18)
    suit_font = _font(SUIT_FONT, 18)
    pip_font = _font(SUIT_FONT, 36)
    ace_font = _font(SUIT_FONT, 64)
    face_font = _font(RANK_FONT, 54)
    face_suit_font = _font(SUIT_FONT, 28)

    draw.text((10, 6), rank, font=rank_font, fill=color)
    draw.text((10, 28), suit, font=suit_font, fill=color)

    corner = Image.new("RGBA", (CARD_W, CARD_H), (0, 0, 0, 0))
    corner_draw = ImageDraw.Draw(corner)
    corner_draw.text((10, 6), rank, font=rank_font, fill=color)
    corner_draw.text((10, 28), suit, font=suit_font, fill=color)
    card.alpha_composite(corner.rotate(180))

    if rank == "A":
        _draw_centered(draw, (CARD_W / 2, CARD_H / 2), suit, ace_font, color)
    elif rank in {"J", "Q", "K"}:
        _draw_centered(draw, (CARD_W / 2, CARD_H / 2 - 14), rank, face_font, color)
        _draw_centered(draw, (CARD_W / 2, CARD_H / 2 + 32), suit, face_suit_font, color)
    else:
        for px, py in PIP_LAYOUTS[int(rank)]:
            _draw_centered(draw, (px * CARD_W, py * CARD_H), suit, pip_font, color)

    return card


def main() -> None:
    sheet = Image.new("RGBA", (CARD_W * COLS, CARD_H * ROWS), (0, 0, 0, 0))
    for row, (_name, suit, color) in enumerate(SUITS):
        for col, rank in enumerate(RANKS):
            card = _draw_card(rank, suit, color)
            sheet.paste(card, (col * CARD_W, row * CARD_H), card)
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT_PATH, "PNG")
    print(f"Wrote {OUT_PATH} ({sheet.size[0]}x{sheet.size[1]})")


if __name__ == "__main__":
    main()
