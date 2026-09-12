#!/usr/bin/env python3
"""Draw numbered finding boxes over a screenshot.

Usage:
    annotate.py <screenshot.png> <findings.json> <out.png> [--html]

findings.json:
{
  "image_size": [1116, 798],             # optional; used only for normalized boxes
  "findings": [
    {
      "id": 1,
      "severity": "blocking" | "should-fix" | "nice-to-have",
      "title": "Play button straddles the fold",
      "box": [x, y, w, h],                # pixels, OR
      "box_norm": [x, y, w, h],           # 0–1 fractions of the image (argent `describe` frames)
      "rule": "H2"                        # checklist id, optional
    }
  ],
  "guides": {                             # optional reference lines/strips to draw
    "fold_x_norm": 0.5,                   # vertical line at the hinge
    "bar_edge": "trailing" | "leading",   # shade the vertical-bar strip
    "bar_width_norm": 0.11
  }
}

Output: <out.png> with boxes + numbered labels (needs Pillow). If Pillow is
missing, writes <out>.html instead — the same overlay as SVG over the image,
viewable in any browser — and exits 0 so the workflow still completes.
Install Pillow for PNG output:  python3 -m pip install --user pillow
"""
import base64, json, pathlib, sys

COLORS = {
    "blocking":     (229, 57, 53),    # red
    "should-fix":   (251, 140, 0),    # orange
    "nice-to-have": (30, 136, 229),   # blue
}
GUIDE = (120, 120, 120)

def load(findings_path):
    data = json.loads(pathlib.Path(findings_path).read_text())
    return data.get("findings", []), data.get("guides", {}), data.get("image_size")

def to_px(f, W, H):
    if "box" in f: return [float(v) for v in f["box"]]
    x, y, w, h = f["box_norm"]
    return [x * W, y * H, w * W, h * H]

def guide_shapes(guides, W, H):
    shapes = []
    if "fold_x_norm" in guides:
        x = guides["fold_x_norm"] * W
        shapes.append(("line", (x, 0, x, H)))
    if guides.get("bar_edge"):
        bw = guides.get("bar_width_norm", 0.11) * W
        x0 = W - bw if guides["bar_edge"] == "trailing" else 0
        shapes.append(("strip", (x0, 0, bw, H)))
    return shapes

def render_png(img_path, findings, guides, out_path):
    from PIL import Image, ImageDraw, ImageFont
    im = Image.open(img_path).convert("RGBA")
    W, H = im.size
    overlay = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    lw = max(2, W // 300)
    for kind, g in guide_shapes(guides, W, H):
        if kind == "line":
            d.line(g, fill=GUIDE + (200,), width=lw)
        else:
            x0, y0, w, h = g
            d.rectangle([x0, y0, x0 + w, y0 + h], fill=GUIDE + (50,))
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", max(14, W // 45))
    except Exception:
        font = ImageFont.load_default()
    for f in findings:
        x, y, w, h = to_px(f, W, H)
        c = COLORS.get(f.get("severity", "should-fix"), COLORS["should-fix"])
        d.rectangle([x, y, x + w, y + h], outline=c + (255,), width=lw, fill=c + (40,))
        label = str(f.get("id", "?"))
        tw, th = d.textbbox((0, 0), label, font=font)[2:]
        pad = lw * 2
        bx, by = max(0, x - pad), max(0, y - th - pad * 3)
        d.rectangle([bx, by, bx + tw + pad * 2, by + th + pad * 2], fill=c + (255,))
        d.text((bx + pad, by + pad), label, fill=(255, 255, 255, 255), font=font)
    Image.alpha_composite(im, overlay).convert("RGB").save(out_path)

def render_html(img_path, findings, guides, out_path, size):
    b64 = base64.b64encode(pathlib.Path(img_path).read_bytes()).decode()
    W, H = size or (1000, 1000)
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" style="max-width:100%;height:auto">',
             f'<image href="data:image/png;base64,{b64}" width="{W}" height="{H}"/>']
    for kind, g in guide_shapes(guides, W, H):
        if kind == "line":
            parts.append(f'<line x1="{g[0]}" y1="{g[1]}" x2="{g[2]}" y2="{g[3]}" stroke="rgb{GUIDE}" stroke-width="{W/300}" stroke-dasharray="8 6"/>')
        else:
            parts.append(f'<rect x="{g[0]}" y="{g[1]}" width="{g[2]}" height="{g[3]}" fill="rgb{GUIDE}" opacity="0.2"/>')
    for f in findings:
        x, y, w, h = to_px(f, W, H)
        c = "rgb%s" % (COLORS.get(f.get("severity", "should-fix"), COLORS["should-fix"]),)
        parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}" fill-opacity="0.15" stroke="{c}" stroke-width="{W/300}"/>')
        parts.append(f'<text x="{x+4}" y="{max(18, y-6)}" font-family="Helvetica,Arial" font-size="{W/45}" font-weight="bold" fill="{c}">{f.get("id","?")}</text>')
    parts.append("</svg>")
    legend = "".join(f'<li><b>{f.get("id")}</b> — {f.get("title","")} <i>({f.get("severity","")})</i></li>' for f in findings)
    pathlib.Path(out_path).write_text(f"<!doctype html><title>Duo inspection</title><body style='font-family:system-ui;margin:16px'>{''.join(parts)}<ol style='list-style:none;padding:0'>{legend}</ol></body>")

def main():
    if len(sys.argv) < 4:
        print(__doc__); sys.exit(1)
    img, fj, out = sys.argv[1:4]
    want_html = "--html" in sys.argv
    findings, guides, size = load(fj)
    if not want_html:
        try:
            render_png(img, findings, guides, out)
            print(f"wrote {out} ({len(findings)} finding(s))")
            return
        except ImportError:
            print("Pillow not installed — falling back to HTML overlay. For PNG: python3 -m pip install --user pillow", file=sys.stderr)
    if size is None:
        try:
            import struct
            with open(img, "rb") as fh:
                head = fh.read(24)
            if head[:8] == b"\x89PNG\r\n\x1a\n":
                size = struct.unpack(">II", head[16:24])
        except Exception:
            pass
    html_out = out if out.endswith(".html") else str(pathlib.Path(out).with_suffix(".html"))
    render_html(img, findings, guides, html_out, size)
    print(f"wrote {html_out} ({len(findings)} finding(s))")

if __name__ == "__main__":
    main()
