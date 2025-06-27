import http.server
import socketserver
import socket
import os


class HelloHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        hostname = socket.gethostname()
        git_sha = os.environ.get("DOTFILES_GIT_SHA", "unknown")
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        message = f"Hello from {hostname}!\nDotfiles Git SHA: {git_sha}"
        self.wfile.write(message.encode())

    def log_message(self, format, *args):
        pass  # Suppress default logging


PORT = 9876
with socketserver.TCPServer(("0.0.0.0", PORT), HelloHandler) as httpd:
    httpd.allow_reuse_address = True
    print(f"Serving at port {PORT}")
    httpd.serve_forever()
