"""Split 2x2 grayscale sheets into R(luminance)/G(erosion)/A(coverage) textures.

Deterministic: same source and same seed always produce identical output.
G is generated here because image models cannot paint a data channel.
"""
from pathlib import Path
import json
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets/generated/vfx/toon-fx-v1/source"
OUT = ROOT / "assets/generated/vfx/toon-fx-v1"
SIZE = 512
MAGICK = shutil.which("magick")
if not MAGICK:
    raise SystemExit("ImageMagick 7 (magick) is required")


def run(*args):
    return subprocess.check_output([MAGICK, *map(str, args)], text=True).strip()


def split(cell: Path, index: int, tag: str) -> Path:
    base = OUT / f"{tag}-{index}"
    r = base.with_name(base.name + "-r.png")
    a = base.with_name(base.name + "-a.png")
    g = base.with_name(base.name + "-g.png")
    b = base.with_name(base.name + "-b.png")
    # R: quantize luminance into exactly three cel bands.
    run(cell, "-colorspace", "Gray", "-resize", f"{SIZE}x{SIZE}!",
        "-fx", "(u<0.45?0.30:(u<0.85?0.70:1.0))", r)
    # A: transparency, with a little softness so edges do not alias.
    run(cell, "-alpha", "extract", "-resize", f"{SIZE}x{SIZE}!",
        "-level", "4%,20%", a)
    # G: deterministic erosion noise, one seed per cell.
    run("-size", f"{SIZE}x{SIZE}", "-seed", str(131 + index * 17 + len(tag)),
        "plasma:fractal", "-colorspace", "Gray", "-blur", "0x0.6", g)
    run("-size", f"{SIZE}x{SIZE}", "xc:black", b)
    run(r, g, b, a, "-combine", base.with_name(base.name + ".png"))
    for tmp in (r, a, g, b):
        tmp.unlink(missing_ok=True)
    return base.with_name(base.name + ".png")


sheets = sorted(SRC.glob("toon_*_2x2*.png"))
if not sheets:
    raise SystemExit(f"no source sheets in {SRC}")
report = []
for sheet in sheets:
    tag = sheet.stem.replace("_2x2", "").replace("-black", "")
    width, height = map(int, run("identify", "-format", "%w %h", sheet).split())
    if width != height:
        raise SystemExit(f"{sheet.name} is not square: {width}x{height}")
    half = width // 2
    cells = []
    for index, (x, y) in enumerate([(0, 0), (1, 0), (0, 1), (1, 1)]):
        cell = OUT / f".cell-{tag}-{index}.png"
        run(sheet, "-crop", f"{half}x{half}+{x * half}+{y * half}", "+repage", cell)
        cells.append(split(cell, index, tag))
        cell.unlink(missing_ok=True)
    atlas = OUT / f"{tag}_2x2.png"
    run("(", cells[0], cells[1], "+append", ")", "(", cells[2], cells[3], "+append", ")",
        "-append", atlas)
    for path in cells + [atlas]:
        report.append({
            "file": path.name,
            "image": run("identify", "-format", "%wx%h %[channels]", path),
            "alpha_range": run(path, "-alpha", "extract", "-format",
                               "%[fx:minima] %[fx:maxima]", "info:"),
            "luminance_range": run(path, "-colorspace", "Gray", "-format",
                                   "%[fx:minima] %[fx:maxima]", "info:"),
        })
(OUT / "normalization-report.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report, indent=2))
