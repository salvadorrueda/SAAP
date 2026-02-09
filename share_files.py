import http.server
import socketserver
import os
import socket

# Path to share
SHARE_PATH = "/home/salvadorrueda/Documents"
PORT = 80

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=SHARE_PATH, **kwargs)

if __name__ == "__main__":
    if not os.path.exists(SHARE_PATH):
        print(f"Error: Directory {SHARE_PATH} does not exist.")
    else:
        ip_address = get_ip()
        print(f"Sharing files from: {SHARE_PATH}")
        print(f"Server started at: http://{ip_address}:{PORT}")
        print("Press Ctrl+C to stop.")
        
        with socketserver.TCPServer(("", PORT), Handler) as httpd:
            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                print("\nServer stopped.")
