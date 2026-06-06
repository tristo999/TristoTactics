# Render camp_v2.map with the CURRENT map_loader legend + dump a swatch strip of
# the specific atlas tiles we use, so tile identity can be verified visually.
import sys
from PIL import Image

ATLAS = r"assets/test/World of Solaria Demo Pack Update 04/16x16/Tilesets/New/Solaria Demo Tiles.png"
T = 16

# Mirror map_loader.gd consts
T_GRASS=(5,0); T_DIRT=(5,3); T_PAD=(10,6); T_BRICK=(10,3)
T_TREE3=(7,0); T_CLIFF=(1,11); T_STAIRS=(4,11); T_TREE=(7,3)
FENCE = {"tl":(0,12),"t":(1,12),"tr":(2,12),"l":(0,13),"c":(1,12),
         "r":(2,13),"bl":(0,14),"b":(1,12),"br":(2,14)}

def tile(im,c,r): return im.crop((c*T,r*T,c*T+T,r*T+T))

def is_interior(rows,x,y):
    if y<0 or y>=len(rows): return False
    row=rows[y]
    if x<0 or x>=len(row): return False
    ch=row[x]
    return ch=="g" or ch=="o" or (ch.isdigit())

def fence_piece(rows,x,y):
    iN=is_interior(rows,x,y-1); iS=is_interior(rows,x,y+1)
    iE=is_interior(rows,x+1,y); iW=is_interior(rows,x-1,y)
    if iS: return FENCE["t"]
    if iN: return FENCE["b"]
    if iE: return FENCE["l"]
    if iW: return FENCE["r"]
    if is_interior(rows,x+1,y+1): return FENCE["tl"]
    if is_interior(rows,x-1,y+1): return FENCE["tr"]
    if is_interior(rows,x+1,y-1): return FENCE["bl"]
    if is_interior(rows,x-1,y-1): return FENCE["br"]
    return FENCE["c"]

def main():
    mp = sys.argv[1] if len(sys.argv)>1 else "data/maps/camp_v2.map"
    scale = int(sys.argv[2]) if len(sys.argv)>2 else 12
    text=open(mp,encoding="utf-8").read()
    if "---" in text: text=text.split("---",1)[1]
    rows=[ln.rstrip("\n").rstrip() for ln in text.splitlines() if ln.strip()!=""]
    w=max(len(r) for r in rows); rows=[r.ljust(w) for r in rows]
    atlas=Image.open(ATLAS).convert("RGBA")
    H=len(rows)
    out=Image.new("RGBA",(w*T,H*T),(77,155,230,255))  # blue bg
    for y,row in enumerate(rows):
        for x,ch in enumerate(row):
            if ch==" ": continue
            base=None; ov=None
            if ch=="#": base=T_GRASS; ov=fence_piece(rows,x,y)
            elif ch=="L": base=T_GRASS; ov=T_CLIFF
            elif ch=="S": base=T_STAIRS
            elif ch=="B": base=T_GRASS; ov=T_BRICK
            elif ch=="T": base=T_GRASS; ov=T_TREE3
            elif ch==",": base=T_DIRT
            elif ch=="o": base=T_PAD
            else: base=T_GRASS  # . g g digits P E w C
            out.alpha_composite(tile(atlas,*base),(x*T,y*T))
            if ov: out.alpha_composite(tile(atlas,*ov),(x*T,y*T))
    big=out.resize((w*T*scale,H*T*scale),Image.NEAREST)
    big.save("docs/maps/camp_v2_layout.png")
    print("saved layout",big.size,"grid",w,H)

    # swatch strip of tiles we use
    labels=[("GRASS",T_GRASS),("DIRT",T_DIRT),("PAD",T_PAD),("BRICK",T_BRICK),
            ("TREE3",T_TREE3),("CLIFF",T_CLIFF),("STAIRS",T_STAIRS),("TREE",T_TREE),
            ("F_tl",FENCE["tl"]),("F_t",FENCE["t"]),("F_tr",FENCE["tr"]),
            ("F_l",FENCE["l"]),("F_r",FENCE["r"]),
            ("F_bl",FENCE["bl"]),("F_b",FENCE["b"]),("F_br",FENCE["br"])]
    s=8
    strip=Image.new("RGBA",(len(labels)*T*s,T*s),(40,40,48,255))
    for i,(_,co) in enumerate(labels):
        strip.alpha_composite(tile(atlas,*co).resize((T*s,T*s),Image.NEAREST),(i*T*s,0))
    strip.save("docs/maps/camp_tiles_swatch.png")
    print("saved swatch",[l for l,_ in labels])

main()
