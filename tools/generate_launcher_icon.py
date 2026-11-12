# Rebuild the local SVG, Android vectors, and legacy PNG fallbacks. Requires Pillow.
from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[1]
bg='#FFF0EC';fg='#77C7BE';sun='#FFD279'
svg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"><rect width="108" height="108" rx="23" fill="{bg}"/><g transform="translate(0 9)"><path d="M42 44a12 12 0 0 1 24 0Z" fill="{sun}"/><g stroke="{fg}" stroke-linecap="round" fill="none"><path d="M54 24v5M36 30l4 4M72 30l-4 4" stroke="{sun}" stroke-width="3"/><path d="M35 55h38M35 47v16M73 47v16" stroke-width="6"/></g></g></svg>'''
(root/'assets/branding/qingyang-icon.svg').write_text(svg)
res=root/'android/app/src/main/res'
vector=f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <group android:translateY="9">
    <path android:fillColor="{sun}" android:pathData="M42,44a12,12 0,0 1,24 0Z" />
    <path android:fillColor="@android:color/transparent" android:strokeColor="{sun}" android:strokeWidth="3" android:strokeLineCap="round" android:pathData="M54,24v5M36,30l4,4M72,30l-4,4" />
    <path android:fillColor="@android:color/transparent" android:strokeColor="{fg}" android:strokeWidth="6" android:strokeLineCap="round" android:pathData="M35,55h38M35,47v16M73,47v16" />
    </group>
</vector>
'''
(res/'drawable/ic_launcher_foreground.xml').write_text(vector)
(res/'drawable/ic_launcher_monochrome.xml').write_text(vector.replace(sun,'#FFFFFF').replace(fg,'#FFFFFF'))
for path in (res/'mipmap-anydpi-v26').glob('ic_launcher*.xml'):
    path.write_text(path.read_text().replace('@mipmap/ic_launcher_foreground','@drawable/ic_launcher_foreground'))
for path in res.glob('mipmap-*/ic_launcher_foreground.png'):path.unlink()
(res/'values/colors.xml').write_text(f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{bg}</color>
    <color name="launch_background">#F6F7F3</color>
</resources>
''')
# The PNGs are raster fallbacks of the same geometric vector for older launchers.
def make(size,round_icon=False):
    k=4
    im=Image.new('RGBA',(size*k,size*k))
    d=ImageDraw.Draw(im);q=size*k/108
    def box(coords):return tuple(v*q for v in coords)
    if round_icon:d.ellipse((0,0,size*k-1,size*k-1),fill=bg)
    else:d.rounded_rectangle((0,0,size*k-1,size*k-1),radius=23*q,fill=bg)
    d.pieslice(box((42,41,66,65)),180,360,fill=sun)
    def line(coords,width,color=fg):
        points=[(coords[i]*q,(coords[i+1]+9)*q) for i in range(0,len(coords),2)]
        d.line(points,fill=color,width=round(width*q))
        r=width*q/2
        for x,y in (points[0],points[-1]):d.ellipse((x-r,y-r,x+r,y+r),fill=color)
    for p in [(54,24,54,29),(36,30,40,34),(72,30,68,34)]:line(p,3,sun)
    for p in [(35,55,73,55),(35,47,35,63),(73,47,73,63)]:line(p,6)
    return im.resize((size,size),Image.Resampling.LANCZOS)
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    folder=res/f'mipmap-{density}'
    make(size).save(folder/'ic_launcher.png',optimize=True)
    make(size,True).save(folder/'ic_launcher_round.png',optimize=True)
make(512).save(root/'assets/branding/bodyrecomp-icon.png',optimize=True)
print('icon PNG bytes', (root/'assets/branding/bodyrecomp-icon.png').stat().st_size)
