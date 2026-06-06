# Dev tool: render a .map to PNG by compositing Solaria atlas tiles, so map look
# can be checked without the engine. Legend mirrors map_loader.gd.
import sys
from PIL import Image
ATLAS = r"assets/test/World of Solaria Demo Pack Update 04/16x16/Tilesets/New/Solaria Demo Tiles.png"
T = 16
# char -> (base_atlas, overlay_atlas_or_None)
LEG = {
    ".": ((5,0), None),
    ",": ((5,3), None),
    "o": ((10,6), None),
    "T": ((5,0), (7,3)),      # grass + tree overlay (cover)
    "#": ((10,3), None),
    "~": ((6,6), None),
    "P": ((5,0), None),
    "E": ((5,0), None),
}
def tile(im,c,r): return im.crop((c*T,r*T,c*T+T,r*T+T))
def main():
    mp = sys.argv[1] if len(sys.argv)>1 else "data/maps/camp_training_grounds.map"
    scale = int(sys.argv[2]) if len(sys.argv)>2 else 6
    text = open(mp,encoding="utf-8").read()
    if "---" in text: text = text.split("---",1)[1]
    rows = [ln.rstrip("\n").rstrip() for ln in text.splitlines() if ln.strip()!=""]
    w = max(len(r) for r in rows); rows=[r.ljust(w) for r in rows]
    atlas = Image.open(ATLAS).convert("RGBA")
    out = Image.new("RGBA",(w*T,len(rows)*T),(20,20,28,255))
    for y,row in enumerate(rows):
        for x,ch in enumerate(row):
            if ch==" ": continue
            named = ch.isdigit()
            base,ov = LEG.get(ch, ((5,0),None) if named else ((5,0),None))
            out.alpha_composite(tile(atlas,*base),(x*T,y*T))
            if ov: out.alpha_composite(tile(atlas,*ov),(x*T,y*T))
    big = out.resize((w*T*scale,len(rows)*T*scale),Image.NEAREST)
    big.save("map_preview.png"); print("saved",big.size,"grid",w,len(rows))
main()
