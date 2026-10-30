import bpy, numpy as np, sys
src, out = sys.argv[sys.argv.index('--')+1:]
img = bpy.data.images.load(src)
w,h = img.size
A = np.array(img.pixels[:], dtype=np.float32).reshape(h,w,4)[::-1]
def resize(a, nw, nh):
    ys = np.linspace(0, a.shape[0]-1, nh); xs = np.linspace(0, a.shape[1]-1, nw)
    y0 = np.floor(ys).astype(int); x0 = np.floor(xs).astype(int)
    y1 = np.minimum(y0+1, a.shape[0]-1); x1 = np.minimum(x0+1, a.shape[1]-1)
    fy = (ys-y0)[:,None,None]; fx = (xs-x0)[None,:,None]
    return (a[y0][:,x0]*(1-fx)+a[y0][:,x1]*fx)*(1-fy)+(a[y1][:,x0]*(1-fx)+a[y1][:,x1]*fx)*fy
W,H = 1536, 864
C = np.zeros((H,W,4), np.float32)
right = resize(A[0:640, 1180:1536], 481, H)
C[:, W-481:] = right
left = right[:, ::-1].copy()
# Cover the mirrored lighthouse islet with nearby sea before it becomes a twin.
sea = left[250:262, 220:300].mean(axis=(0,1))
left[180:300, 30:215] = sea
C[:, 0:481] = left
mid = resize(A[0:640, 830:1180], W-962, H)
C[:, 481:W-481] = mid
def feather(x, width=40):
    for i in range(-width, width):
        t = (i+width)/(2*width)
        C[:, x+i] = C[:, x+i]  # keep; img2img repaints seams
feather(481); feather(W-481)
C[...,3] = 1
o = bpy.data.images.new('c', W, H, alpha=True); o.pixels = C[::-1].ravel()
o.filepath_raw = out; o.file_format='PNG'; o.save()
