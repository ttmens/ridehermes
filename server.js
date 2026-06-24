
const http = require('http');
const fs = require('fs');
const path = require('path');

const DIST_DIR = '/home/test/ridehermes/src/admin-web/dist';
const PORT = 3002;
const API_URL = 'http://localhost:8686';

const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

const server = http.createServer((req, res) => {
  // API 代理
  if (req.url.startsWith('/api/')) {
    const options = {
      hostname: 'localhost',
      port: 8686,
      path: req.url,
      method: req.method,
      headers: req.headers,
    };
    const proxy = http.request(options, (proxyRes) => {
      res.writeHead(proxyRes.statusCode, proxyRes.headers);
      proxyRes.pipe(res);
    });
    req.pipe(proxy);
    proxy.on('error', () => {
      res.writeHead(502);
      res.end('Bad Gateway');
    });
    return;
  }

  // 静态文件
  let filePath = path.join(DIST_DIR, req.url === '/' ? 'index.html' : req.url);
  
  // SPA fallback
  if (!fs.existsSync(filePath) && !req.url.includes('.')) {
    filePath = path.join(DIST_DIR, 'index.html');
  }
  
  const ext = path.extname(filePath);
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';
  
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not Found');
      return;
    }
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`RideHermes Web running on http://0.0.0.0:${PORT}`);
});
