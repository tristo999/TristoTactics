# Dev preview: Wargroove-style framing. The playable map sits on readable terrain
# that continues a small margin past the playable edge (same tileset, looks like
# part of the map), with a thin frame at the very edge. NO vignette/darkening.
# The camera would over-scroll just into this margin and stop.
import sys, random
from PIL import Image, ImageDraw
ATLAS = r"assets/test/World of Solaria Demo Pack Update 04/16x16/Tilesets/New/Solaria Demo Tiles.png"
T=16
GRASS=(5,0); ROAD=(5,3); STONE=(10,6); TREE=(7,3); WALL=(10,3)
def tile(im,c,r): return im.crop((c*T,r*T,c*T+T,r*T+T))
def main():
    mp=sys.argv[1] if len(sys.argv)>1 else "data/maps/camp_training_grounds.map"
    scale=int(sys.argv[2]) if len(sys.argv)>2 else 5
    M=4  # small "barely scroll" margin of readable backdrop
    text=open(mp,encoding="utf-8").read()
    if "---" in text: text=text.split("---",1)[1]
    rows=[ln.rstrip("\n").rstrip() for ln in text.splitlines() if ln.strip()!=""]
    w=max(len(r) for r in rows); rows=[r.ljust(w) for r in rows]; h=len(rows)
    atlas=Image.open(ATLAS).convert("RGBA")
    LEG={".":(GRASS,None),",":(ROAD,None),"o":(STONE,None),"T":(GRASS,TREE),"#":(WALL,None),
         "P":(GRASS,None),"E":(GRASS,None)}
    W=w+2*M; H=h+2*M
    out=Image.new("RGBA",(W*T,H*T),(60,90,55,255))
    rnd=random.Random(11)
    # backdrop: grass + forest continuing past the map. Denser woods to the north
    # (the treeline the raid comes from); a road continues out the south entrance.
    entrance_col=None
    for x,ch in enumerate(rows[-1]):
        if ch in ".,": entrance_col=x  # bottom-row opening
    for gy in range(H):
        for gx in range(W):
            if (M<=gx<M+w) and (M<=gy<M+h): continue  # playable area drawn later
            out.alpha_composite(tile(atlas,*GRASS),(gx*T,gy*T))
            mx=gx-M; my=gy-M
            # road continuing south out the entrance
            if entrance_col is not None and my>=h and abs(mx-entrance_col)<=0 :
                out.alpha_composite(tile(atlas,*ROAD),(gx*T,gy*T)); continue
            dens=0.75 if my<0 else 0.5      # thicker treeline north
            if rnd.random()<dens:
                out.alpha_composite(tile(atlas,*TREE),(gx*T,gy*T))
    # playable map
    for y,row in enumerate(rows):
        for x,ch in enumerate(row):
            if ch==" ": continue
            base,ov=LEG.get(ch,(GRASS,None))
            ox,oy=(x+M)*T,(y+M)*T
            out.alpha_composite(tile(atlas,*base),(ox,oy))
            if ov: out.alpha_composite(tile(atlas,*ov),(ox,oy))
    big=out.resize((W*T*scale,H*T*scale),Image.NEAREST)
    # thin Wargroove-style frame at the very edge (light parchment), not a darken
    d=ImageDraw.Draw(big); bw=scale*3
    for i in range(bw):
        c=(214,200,158,255)
        d.rectangle([i,i,big.size[0]-1-i,big.size[1]-1-i],outline=c)
    big.save("docs/maps/camp_framing_preview.png"); print("saved",big.size,"margin",M)
main()
