import bpy, numpy as np, sys
src, out = sys.argv[sys.argv.index('--')+1:]
img = bpy.data.images.load(src)
w,h = img.size
A = np.array(img.pixels[:], dtype=np.float32).reshape(h,w,4)[::-1].copy()
sea = A[160:240, 0:200].copy()
x0,x1,y0,y1 = 130, 485, 195, 338
patch = np.zeros((y1-y0, x1-x0, 4), np.float32)
for yy in range(0, y1-y0, 80):
    for xx in range(0, x1-x0, 200):
        tile = sea[:, ::-1] if (xx//200 + yy//80) % 2 else sea
        hh = min(80, y1-y0-yy); ww = min(200, x1-x0-xx)
        patch[yy:yy+hh, xx:xx+ww] = tile[:hh, :ww]
# Feather the patch into the painting over 24 pixels.
f = 24
ys = np.arange(y1-y0)[:,None]; xs = np.arange(x1-x0)[None,:]
edge = np.minimum(np.minimum(ys, (y1-y0-1)-ys), np.minimum(xs, (x1-x0-1)-xs))
alpha = np.clip(edge / f, 0, 1)[..., None]
A[y0:y1, x0:x1] = A[y0:y1, x0:x1]*(1-alpha) + patch*alpha
A[...,3] = 1
o = bpy.data.images.new('p', w, h, alpha=True); o.pixels = A[::-1].ravel()
o.filepath_raw = out; o.file_format='PNG'; o.save()
