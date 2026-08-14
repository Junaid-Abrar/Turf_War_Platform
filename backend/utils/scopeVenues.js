// Admin sees every venue; a venue_owner is scoped to their own.
function venueScopeFilter(user) {
  return user.role === 'admin' ? {} : { owner: user.id };
}

module.exports = { venueScopeFilter };
