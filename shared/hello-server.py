import http.server
import socketserver
import socket

class HelloHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        hostname = socket.gethostname()
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(f'Hello from {hostname} - separately defined file test!\n'.encode())
    
    def log_message(self, format, *args):
        pass  # Suppress default logging

PORT = 9876
with socketserver.TCPServer(('0.0.0.0', PORT), HelloHandler) as httpd:
    print(f'Serving at port {PORT}')
    httpd.serve_forever()
