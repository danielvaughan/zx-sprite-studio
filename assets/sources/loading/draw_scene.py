"""Sprite Studio loading/start scene, drawn on the 8x8 cell grid after the local P-H3 master
(assets/sources/loading/sprite-studio-loading_00001_.png): squared paper with two of the studio's
figures drawn large from their real pixels (Tiger Gorilla's photographer and Mower Mayhem's bird), a pencil, and a
portable television showing two more at true size (Tiger Gorilla's gorilla and the Mower).

M3 (m2-r3 F-3, the Library): the M2 picture had the Mower alone, which read as a beetle; this one
shows several of the studio's figures, as the Library does.

Usage: draw_scene.py <dir of zxrom.py> <out dir> [<games root> [<dir of spectrum_sprites.py>]]
"""
import os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, sys.argv[1])
import zxrom
# <games root> defaults to the folder holding this repository (assets/sources/loading/ -> repo -> parent)
ROOT = sys.argv[3] if len(sys.argv) > 3 else str(os.path.dirname(os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))))
sys.path.insert(0, sys.argv[4] if len(sys.argv) > 4 else os.path.join(
    os.environ.get('ZX_PLUGINS_DIR') or os.path.join(ROOT, 'zx-plugins/plugins'), 'zx-assets/skills/zx-sprite-data/scripts'))
import spectrum_sprites as ss

ROM, _ = zxrom.rom48()
K=(0,0,0); B=(0,0,255); R=(255,0,0); Y=(255,255,0); W=(255,255,255)


def figure(repo_path, name):
    sprites = ss.parse(open(os.path.join(ROOT, repo_path)).read(), [], [])
    art = next(s['art'] for s in sprites if s['name'] == name)
    return [[c == '#' for c in row] for row in art]


# (the photographer, a made-up character, rather than All Disco's Dan: the owner cleared Dan for the
# Library, not as the face of the Studio)
SNAPPER = figure('zx-tiger-gorilla/assets/sprites/photographer/final/photographer.spr', 'pho_walk0')
BIRD = figure('zx-mower-mayhem/assets/sprites/bird.spr', 'bird_stand')
GORILLA = figure('zx-tiger-gorilla/assets/sprites/gorilla/final/gorilla-walk.spr', 'walk0')
MOWER = figure('zx-mower-mayhem/assets/sprites/mower.spr', 'mower_roll_a_e')


def text(px,s,x,y,col,scale=1):
    for i,ch in enumerate(s):
        g=ROM[0x3D00+(ord(ch)-32)*8:0x3D00+(ord(ch)-32)*8+8]
        for r in range(8):
            for c in range(8):
                if g[r]>>(7-c)&1:
                    for dy in range(scale):
                        for dx in range(scale):
                            px[x+(i*8+c)*scale+dx,y+r*scale+dy]=col


def large(d, art, x0, y0, sq):
    for r, row in enumerate(art):
        for c, ink in enumerate(row):
            if ink:
                d.rectangle([x0+c*sq, y0+r*sq, x0+c*sq+sq-1, y0+r*sq+sq-1], fill=K)


def true_size(px, art, x0, y0):
    for r, row in enumerate(art):
        for c, ink in enumerate(row):
            if ink:
                px[x0+c, y0+r] = W


def scene(tag):
    im=Image.new('RGB',(256,192),K); d=ImageDraw.Draw(im); px=im.load()
    d.rectangle([0,0,255,103],fill=B)                      # the blue wall, rows 0-12
    # squared paper: cells 1-14, rows 1-11, white with a black dot every other 3-dot square
    d.rectangle([8,8,119,95],fill=W)
    for y in range(9,95,6):
        for x in range(9,119,6):
            px[x,y]=K
    large(d, SNAPPER, 15, 15, 3)                           # the photographer, 16 x 24, 3 dots a square
    large(d, BIRD, 66, 33, 3)                              # the bird, 16 x 16
    # pencil along row 12: yellow body, black outline, red tip, white end
    d.rectangle([16,96,95,103],fill=Y); d.line([16,96,95,96],fill=K); d.line([16,103,95,103],fill=K)
    d.rectangle([8,96,15,103],fill=W); d.line([8,96,8,103],fill=K)
    d.polygon([(96,96),(103,99),(96,103)],fill=R)
    # portable television: cells 16-30, rows 1-12; white trim, black cabinet, black screen
    d.rectangle([128,8,247,103],fill=W)
    d.rectangle([136,16,239,95],fill=K)
    d.rectangle([144,24,207,87],fill=K)                   # the tube, black
    d.rectangle([143,23,208,88],outline=W)                 # its bezel
    d.rectangle([216,24,223,31],fill=Y); d.rectangle([216,40,223,47],fill=Y)
    for y in range(56,88,4): d.line([216,y,231,y],fill=W)
    true_size(px, GORILLA, 149, 40)                        # at true size, white on the black tube
    true_size(px, MOWER, 186, 56)
    text(px,"SPRITE STUDIO",24,112,Y,2)
    if tag=='loading':
        text(px,"SQUARED PAPER AND A PENCIL",24,136,W,1)
    return im


out=sys.argv[2]
scene('loading').save(out+'/composed-loading.png')
scene('start').save(out+'/composed-start.png')
