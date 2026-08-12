import { useState, useEffect } from 'react';
import { Table, Badge, Form, Alert, Card } from 'react-bootstrap';
import { Users } from 'lucide-react';
import toast from 'react-hot-toast';
import api from '../api/axios';
import { TableSkeleton } from './Skeletons';
import EmptyState from './EmptyState';

const UserManagement = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchUsers = async () => {
    try {
      const res = await api.get('/auth/users');
      setUsers(res.data.data);
    } catch {
      setError('Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleRoleChange = async (userId, newRole) => {
    try {
      await api.put(`/auth/users/${userId}/role`, { role: newRole });
      setUsers(users.map(u => u._id === userId ? { ...u, role: newRole } : u));
      toast.success('Role updated');
    } catch (err) {
      toast.error(err.response?.data?.error || 'Failed to update role');
    }
  };

  if (loading) return <TableSkeleton />;
  if (error) return <Alert variant="danger">{error}</Alert>;

  return (
    <Card className="shadow-sm">
      <Card.Header className="bg-white">
        <h5 className="mb-0">User Management</h5>
      </Card.Header>
      {users.length === 0 ? (
        <Card.Body>
          <EmptyState icon={Users} title="No users found" />
        </Card.Body>
      ) : (
        <Table responsive hover className="mb-0">
          <thead className="bg-light">
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Joined</th>
              <th>Current Role</th>
              <th>Change Role</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u._id}>
                <td className="align-middle">{u.name}</td>
                <td className="align-middle">{u.email}</td>
                <td className="align-middle">{new Date(u.createdAt).toLocaleDateString()}</td>
                <td className="align-middle">
                  <Badge
                    bg={u.role === 'admin' ? 'danger' : u.role === 'venue_owner' ? 'success' : 'secondary'}
                  >
                    {u.role}
                  </Badge>
                </td>
                <td className="align-middle">
                  <Form.Select
                    size="sm"
                    value={u.role}
                    onChange={(e) => handleRoleChange(u._id, e.target.value)}
                    style={{ width: 'auto' }}
                    disabled={u.role === 'admin'}
                  >
                    <option value="user">User</option>
                    <option value="venue_owner">Venue Owner</option>
                    {/* Keep admin option in case they really need to promote someone else to admin */}
                    <option value="admin">Admin</option>
                  </Form.Select>
                </td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}
    </Card>
  );
};

export default UserManagement;
