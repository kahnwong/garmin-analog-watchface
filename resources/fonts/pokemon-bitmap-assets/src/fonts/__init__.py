"""Generate the watch face's BMFont text file and texture atlas."""

from pathlib import Path
import subprocess

from PIL import Image, ImageDraw, ImageFont
import rectpack


ASSETS = Path(__file__).resolve().parents[2]
FONT_SIZE = 30


def generate_bitmap_font(out_prefix: Path) -> None:
    # Pillow bundles Aileron, so generation needs no system font or download.
    font = ImageFont.load_default(size=FONT_SIZE)
    glyphs = []
    for codepoint in range(32, 127):
        char = chr(codepoint)
        if char in "012":
            with Image.open(ASSETS / f"{char}.png") as source:
                image = source.convert("RGBA")
            xoffset = yoffset = 0
            advance = image.width + 2
        else:
            left, top, right, bottom = font.getbbox(char)
            image = Image.new("RGBA", (max(1, right - left), max(1, bottom - top)))
            ImageDraw.Draw(image).text((-left, -top), char, font=font, fill="white")
            xoffset, yoffset = left, top
            advance = round(font.getlength(char))
        glyphs.append((codepoint, image, xoffset, yoffset, advance))

    # Grow the single page until every glyph fits; never silently drop glyphs.
    size = 64
    while size <= 4096:
        packer = rectpack.newPacker(rotation=False)
        for index, (_, image, _, _, _) in enumerate(glyphs):
            packer.add_rect(image.width + 2, image.height + 2, rid=index)
        packer.add_bin(size, size)
        packer.pack()
        rectangles = packer.rect_list()
        if len(rectangles) == len(glyphs):
            break
        size *= 2
    else:
        raise ValueError("Glyphs do not fit on a 4096x4096 atlas")

    atlas = Image.new("RGBA", (size, size))
    lines = [
        f'info face="pokemon" size={FONT_SIZE} bold=0 italic=0 charset="" '
        'unicode=1 stretchH=100 smooth=1 aa=1 padding=1,1,1,1 spacing=1,1 outline=0',
        f"common lineHeight={FONT_SIZE} base={int(FONT_SIZE * 0.8)} "
        f"scaleW={size} scaleH={size} pages=1 packed=0",
        f'page id=0 file="{out_prefix.name}.png"',
        f"chars count={len(glyphs)}",
    ]
    for _, x, y, _, _, index in sorted(rectangles, key=lambda rect: rect[5]):
        codepoint, image, xoffset, yoffset, advance = glyphs[index]
        atlas.paste(image, (x + 1, y + 1))
        lines.append(
            f"char id={codepoint} x={x + 1} y={y + 1} "
            f"width={image.width} height={image.height} "
            f"xoffset={xoffset} yoffset={yoffset} xadvance={advance} page=0 chnl=15"
        )

    atlas.save(out_prefix.with_suffix(".png"))
    out_prefix.with_suffix(".fnt").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    subprocess.run(["./convert.sh"], cwd=ASSETS, check=True)
    output = ASSETS.parent / "pokemon"
    generate_bitmap_font(output)
    print(f"Generated {output}.fnt and {output}.png")
