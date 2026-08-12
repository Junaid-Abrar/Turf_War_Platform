// Strips keys starting with '$' or containing '.' from req.body/params/query to block
// NoSQL operator injection (e.g. { "email": { "$gt": "" } }).
// Mutates objects in place rather than reassigning them — express-mongo-sanitize's approach
// of replacing req.query breaks on Express 5, where req.query is a read-only getter.
function sanitizeInPlace(obj) {
  if (!obj || typeof obj !== 'object') return;

  for (const key of Object.keys(obj)) {
    if (key.startsWith('$') || key.includes('.')) {
      delete obj[key];
      continue;
    }
    if (obj[key] && typeof obj[key] === 'object') {
      sanitizeInPlace(obj[key]);
    }
  }
}

function sanitize(req, res, next) {
  sanitizeInPlace(req.body);
  sanitizeInPlace(req.params);
  sanitizeInPlace(req.query);
  next();
}

module.exports = sanitize;
