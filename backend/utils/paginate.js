const MAX_LIMIT = 100;
const DEFAULT_LIMIT = 20;

// Shared pagination + sorting helper for list endpoints.
// Reads `page`, `limit`, `sort` from query params and applies them to a Mongoose query.
async function paginate(Model, filter, query = {}, options = {}) {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(MAX_LIMIT, Math.max(1, parseInt(query.limit, 10) || DEFAULT_LIMIT));
  const skip = (page - 1) * limit;
  const sort = query.sort || options.defaultSort || '-createdAt';

  let mongooseQuery = Model.find(filter).sort(sort).skip(skip).limit(limit);
  if (options.populate) {
    mongooseQuery = mongooseQuery.populate(options.populate);
  }
  if (options.select) {
    mongooseQuery = mongooseQuery.select(options.select);
  }

  const [data, total] = await Promise.all([
    mongooseQuery,
    Model.countDocuments(filter)
  ]);

  return {
    data,
    page,
    limit,
    total,
    totalPages: Math.max(1, Math.ceil(total / limit))
  };
}

module.exports = { paginate };
