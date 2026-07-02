const express = require('express');
const os = require('os');
const router = express.Router();

router.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'cruz-azul-erp-frontend',
    instance: os.hostname(),
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;
