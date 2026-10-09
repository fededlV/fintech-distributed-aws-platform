require('dotenv').config();
const express = require('express');
const pagosRouter = require('./routes/pagos');

const pool = require('./db');

const app = express();
app.use(express.json());

let lastDbCheck = 0;
let lastDbStatus = false;

app.get('/', (_req, res) => {
  res.json({ status: 'ok', servicio: 'api-pagos' });
});

app.get('/health/live', (_req, res) => {
  res.json({ status: 'UP' });
});

app.get('/health/ready', async (_req, res) => {
  const now = Date.now();
  if (now - lastDbCheck < 3000) {
    return lastDbStatus
      ? res.json({ status: 'UP' })
      : res.status(503).json({ status: 'DOWN' });
  }

  try {
    await pool.query('SELECT 1');
    lastDbStatus = true;
    lastDbCheck = now;
    return res.json({ status: 'UP' });
  } catch (err) {
    console.error('[HealthCheck] Payments DB ping failed:', err.message);
    lastDbStatus = false;
    lastDbCheck = now;
    return res.status(503).json({ status: 'DOWN' });
  }
});

app.use('/pagos', pagosRouter);

app.use((_req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`API de pagos escuchando en el puerto ${PORT}`);
});
