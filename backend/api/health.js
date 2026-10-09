export default function handler(req, res) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  return res.status(200).json({
    status: 'ok',
    service: 'e-commerce-backend',
    timestamp: new Date().toISOString()
  });
}
