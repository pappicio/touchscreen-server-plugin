import atexit
import fcntl
import http.server
import os
import signal
import socketserver
import struct
import time
from urllib.parse import urlparse, parse_qs

PID_FILE = "/tmp/oc-touchscreen-server.pid"

def cleanup():
    try:
        if os.path.exists(PID_FILE):
            with open(PID_FILE, "r") as f:
                if f.read().strip() == str(os.getpid()):
                    os.unlink(PID_FILE)
    except OSError:
        pass

def stop_server(signum, frame):
    raise SystemExit(0)

with open(PID_FILE, "w") as f:
    f.write(str(os.getpid()))
atexit.register(cleanup)
signal.signal(signal.SIGTERM, stop_server)
signal.signal(signal.SIGINT, stop_server)

def snap():
    with open('/dev/fb0', 'rb') as f:
        v = struct.unpack('6I', fcntl.ioctl(f, 0x4600, b'\0' * 160)[:24])
        w, h, yoff = v[0], v[1], v[5]
        f.seek(yoff * v[2] * 4)
        buf = bytearray(f.read(w * h * 4))
    buf[3::4] = b'\xff' * (w * h)
    hdr = b'BM' + struct.pack('<IHHI', 54 + len(buf), 0, 0, 54)
    hdr += struct.pack('<IiiHHIIiiII', 40, w, -h, 1, 32, 0, len(buf), 2835, 2835, 0, 0)
    return hdr + buf

def touch(points, ms):
    f = open('/dev/input/event2', 'wb', buffering=0)
    def ev(t, c, v):
        f.write(struct.pack('<llHHi', 0, 0, t, c, v))
    def pos(bx, by):
        bx = max(0, min(799, bx))
        by = max(0, min(479, by))
        ev(3, 53, by)
        ev(3, 54, 800 - bx)
        ev(3, 48, 20)
        ev(3, 50, 20)
        ev(3, 57, 0)
        ev(0, 2, 0)
        ev(0, 0, 0)
    ev(1, 330, 1)
    pos(*points[0])
    step = ms / 1000.0 / max(1, len(points) - 1)
    for p in points[1:]:
        time.sleep(step)
        pos(*p)
    if len(points) == 1:
        time.sleep(0.08)
    ev(1, 330, 0)
    ev(0, 2, 0)
    ev(0, 0, 0)
    f.close()

def tap(x, y):
    touch([(x, y)], 80)

def swipe(x1, y1, x2, y2, ms):
    n = 12
    pts = [(x1 + (x2 - x1) * k // n, y1 + (y2 - y1) * k // n) for k in range(n + 1)]
    touch(pts, ms)

PAGE = b"""<body style="margin:0;background:#000;overflow:hidden"><img id=i style="cursor:pointer;touch-action:none;position:absolute;top:50%;left:50%;height:min(100vw,166.67vh);transform:translate(-50%,-50%) rotate(90deg)"><script>
function r(){var n=new Image();n.onload=function(){i.src=n.src;setTimeout(r,300)};n.onerror=function(){setTimeout(r,1000)};n.src="/s.bmp?"+Date.now()}r();
var d=null;
function P(ev){var b=i.getBoundingClientRect();return [Math.max(0,Math.min(799,Math.round(799*(ev.clientX-b.left)/b.width))),Math.max(0,Math.min(479,Math.round(479*(ev.clientY-b.top)/b.height)))]}
i.onpointerdown=function(ev){d=[P(ev),Date.now(),ev.clientX,ev.clientY];i.setPointerCapture(ev.pointerId);ev.preventDefault()};
i.onpointerup=function(ev){if(!d)return;var a=d[0],e=P(ev),ms=Math.min(1000,Math.max(120,Date.now()-d[1])),mv=Math.hypot(ev.clientX-d[2],ev.clientY-d[3]);d=null;
fetch(mv<10?"/tap?x="+a[0]+"&y="+a[1]:"/swipe?x1="+a[0]+"&y1="+a[1]+"&x2="+e[0]+"&y2="+e[1]+"&ms="+ms)};
i.onpointercancel=function(){d=null};
</script>"""

class H(http.server.BaseHTTPRequestHandler):
    def do_GET(s):
        u = urlparse(s.path)
        q = parse_qs(u.query)
        if u.path == '/tap':
            tap(int(q['x'][0]), int(q['y'][0]))
            d, t = b'ok', 'text/plain'
        elif u.path == '/swipe':
            swipe(int(q['x1'][0]), int(q['y1'][0]), int(q['x2'][0]), int(q['y2'][0]), int(q['ms'][0]))
            d, t = b'ok', 'text/plain'
        elif u.path == '/s.bmp':
            d, t = snap(), 'image/bmp'
        else:
            d, t = PAGE, 'text/html'
        s.send_response(200)
        s.send_header('Content-Type', t)
        s.send_header('Content-Length', str(len(d)))
        s.end_headers()
        s.wfile.write(d)
    def log_message(self, *a):
        pass

class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

try:
    with Server(('0.0.0.0', 8085), H) as server:
        server.serve_forever()
finally:
    cleanup()
