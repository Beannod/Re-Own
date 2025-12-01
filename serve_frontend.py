#!/usr/bin/env python
import http.server
import socketserver
import os
from pathlib import Path

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        return super().end_headers()

    def do_GET(self):
        # If path is just / or a directory, serve index.html
        if self.path == '/' or self.path.endswith('/'):
            self.path = '/index.html'
        return super().do_GET()

PORT = 8080
os.chdir(Path(__file__).parent / 'frontend' / 'public')

with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
    print(f"Serving frontend on http://localhost:{PORT}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped")
