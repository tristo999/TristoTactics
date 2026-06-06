# Dev preview: render a .map with the Option-C framing look — the world continues
# past the playable grid (backdrop margin) + an edge vignette. Mock only (PIL),
# to approve the look before building the engine systems.
import sys, random
from PIL import Image, ImageDraw
ATLAS = r"assets/test/World of Solaria Demo Pack Update 04/16x16/Tilesets/New/Solaria Demo Tiles.png"
T=16
GRASS=(5,0); ROAD=(5,3); STONE=(10,6); TREE=(7,3); WALL=(10,3)
def tile(im,c,r): return im.crop((c*T,r*T,c*T+T,r*T+T))
def main():
    mp = sys.argv[1] if len(sys.argv)>1 else "data/maps/camp_training_grounds.map"
    scale = int(sys.argv[2]) if len(sys.argv)>2 else 5
    M = 8  # backdrop margin (tiles) of world past the playable edge
    text=open(mp,encoding="utf-8").read()
    if "---" in text: text=text.split("---",1)[1]
    rows=[ln.rstrip("\n").rstrip() for ln in text.splitlines() if ln.strip()!=""]
    w=max(len(r) for r in rows); rows=[r.ljust(w) for r in rows]; h=len(rows)
    atlas=Image.open(ATLAS).convert("RGBA")
    LEG={".":(GRASS,None),",":(ROAD,None),"o":(STONE,None),"T":(GRASS,TREE),"#":(WALL,None),
         "P":(GRASS,None),"E":(GRASS,None)}
    W=w+2*M; H=h+2*M
    out=Image.new("RGBA",(W*T,H*T),(20,22,28,255))
    rnd=random.Random(7)
    # backdrop margin: grass everywhere, trees scattered; denser woods toward the north/top
    for gy in range(H):
        for gx in range(W):
            inside = (M<=gx<M+w) and (M<=gy<M+h)
            if inside: continue
            out.alpha_composite(tile(atlas,*GRASS),(gx*T,gy*T))
            north_bias = 0.55 if gy < M+2 else 0.22   # thicker treeline up top
            edge = gx<2 or gy<2 or gx>=W-2 or gy>=H-2
            p = 0.7 if edge else north_bias
            if rnd.random()<p:
                out.alpha_composite(tile(atlas,*TREE),(gx*T,gy*T))
    # playable map
    for y,row in enumerate(rows):
        for x,ch in enumerate(row):
            if ch==" ": continue
            base,ov=LEG.get(ch,(GRASS,None) if ch.isdigit() else (GRASS,None))
            ox,oy=(x+M)*T,(y+M)*T
            out.alpha_composite(tile(atlas,*base),(ox,oy))
            if ov: out.alpha_composite(tile(atlas,*ov),(ox,oy))
    # vignette: darken toward edges (elliptical falloff)
    vig=Image.new("L",(W*T,H*T),0)
    d=ImageDraw.Draw(vig)
    cx,cy=W*T/2,H*T/2
    import math
    px=vig.load()
    for yy in range(0,H*T,2):
        for xx in range(0,W*T,2):
            nx=(xx-cx)/(W*T/2); ny=(yy-cy)/(H*T/2)
            r=min(1.0,(nx*nx+ny*ny)**0.5)
            a=int(max(0.0,(r-0.45)/0.55)**1.6*235)
            for dy in range(2):
                for dx in range(2):
                    if xx+dx<W*T and yy+dy<H*T: px[xx+dx,yy+dy]=a
    dark=Image.new("RGBA",(W*T,H*T),(8,8,14,255)); dark.putalpha(vig)
    out.alpha_composite(dark)
    big=out.resize((W*T*scale,H*T*scale),Image.NEAREST)
    big.save("docs/maps/camp_framing_preview.png"); print("saved",big.size,"playable",w,h,"with margin",M)
main()
