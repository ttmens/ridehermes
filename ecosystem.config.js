
module.exports = {
  apps: [
    {
      name: 'rh-api',
      script: './ridehermes',
      cwd: '/home/test/ridehermes/src/ride-hermes',
      autorestart: true,
      max_restarts: 5
    },
    {
      name: 'rh-web',
      script: '/home/test/ridehermes/server.js',
      autorestart: true
    }
  ]
};
