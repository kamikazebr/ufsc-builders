#!/usr/bin/env python3
"""Generate QR codes for every element carrying data-qr="<url>" in deck.html
and inline them as data URIs. No CDN, no runtime library, works offline.

Re-run it whenever a URL changes:   uv run --with qrcode,pillow python3 make-qr.py
"""
import base64, io, re, sys, pathlib
import qrcode
from qrcode.image.styledpil import StyledPilImage

DECK = pathlib.Path(__file__).parent / "index.html"

def png_data_uri(url: str) -> str:
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=2,
    )
    qr.add_data(url)
    qr.make(fit=True)
    # Light modules on a dark deck read badly; scanners want dark-on-light,
    # so keep the code itself conventional and let CSS give it a white plate.
    img = qr.make_image(fill_color="#0B0E13", back_color="white")
    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=True)
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()

html = DECK.read_text(encoding="utf-8")
pattern = re.compile(r'(<img class="qr"[^>]*?data-qr="([^"]+)"[^>]*?)(?:\s+src="[^"]*")?(\s*/?>)')

count = 0
def repl(m):
    global count
    head, url, tail = m.group(1), m.group(2), m.group(3)
    count += 1
    return f'{head} src="{png_data_uri(url)}"{tail}'

out = pattern.sub(repl, html)
DECK.write_text(out, encoding="utf-8")
print(f"embedded {count} QR codes")
if count == 0:
    sys.exit("no data-qr elements found — did the markup change?")
