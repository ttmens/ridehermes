#!/usr/bin/env python3
"""
RideHermes 反向代理服务器
- 静态文件服务（SPA 单页应用路由支持）
- API 请求代理到后端
"""

import http.server
import socketserver
import urllib.request
import urllib.error
import os
import posixpath

PORT = 9001
STATIC_DIR = os.path.expanduser('~/ridehermes/src/admin-web/dist')
API_BACKEND = 'http://localhost:8686'

class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=STATIC_DIR, **kwargs)
    
    def do_GET(self):
        if self.path.startswith('/api/v1/') or self.path == '/health':
            return self.proxy_request('GET')
        else:
            # SPA 支持：检查文件是否存在，不存在返回 index.html
            static_path = self.translate_path(self.path)
            if not os.path.exists(static_path) or os.path.isdir(static_path):
                self.path = '/index.html'
            return super().do_GET()
    
    def do_POST(self):
        if self.path.startswith('/api/v1/') or self.path == '/health':
            return self.proxy_request('POST')
        else:
            self.send_error(405)
    
    def do_PUT(self):
        if self.path.startswith('/api/v1/') or self.path == '/health':
            return self.proxy_request('PUT')
        else:
            self.send_error(405)
    
    def do_DELETE(self):
        if self.path.startswith('/api/v1/') or self.path == '/health':
            return self.proxy_request('DELETE')
        else:
            self.send_error(405)
    
    def proxy_request(self, method):
        url = API_BACKEND + self.path
        headers = {key: value for key, value in self.headers.items() 
                   if key.lower() not in ['host', 'connection', 'content-length']}
        
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length) if content_length > 0 else None
            
            req = urllib.request.Request(url, data=body, headers=headers, method=method)
            
            with urllib.request.urlopen(req, timeout=30) as response:
                self.send_response(response.status)
                for key, value in response.getheaders():
                    if key.lower() not in ['transfer-encoding', 'connection']:
                        self.send_header(key, value)
                self.end_headers()
                self.wfile.write(response.read())
                
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            for key, value in e.headers.items():
                if key.lower() not in ['transfer-encoding', 'connection']:
                    self.send_header(key, value)
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:
            self.send_error(500, str(e))
    
    def log_message(self, format, *args):
        print(f"[{self.log_date_time_string()}] {format % args}")

if __name__ == '__main__':
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), ProxyHandler) as httpd:
        print(f"RideHermes Proxy running on port {PORT}")
        print(f"Static files: {STATIC_DIR}")
        print(f"API backend: {API_BACKEND}")
        print(f"SPA mode: enabled (all unknown paths -> index.html)")
        httpd.serve_forever()
