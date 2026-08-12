const EmptyState = ({ icon: Icon, title, description, action }) => (
  <div className="text-center py-5 text-muted">
    {Icon && <Icon size={40} className="mb-3 opacity-50" />}
    <h6 className="mb-1">{title}</h6>
    {description && <p className="mb-3 small">{description}</p>}
    {action}
  </div>
);

export default EmptyState;
