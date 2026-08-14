import { useState, useEffect, useCallback } from 'react';
import { Table, Badge, Alert, Card, Button } from 'react-bootstrap';
import { RefreshCw, Check, X, CalendarX } from 'lucide-react';
import toast from 'react-hot-toast';
import api from '../api/axios';
import { TableSkeleton } from './Skeletons';
import EmptyState from './EmptyState';

const BookingList = ({ refreshTrigger, isAdmin }) => {
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [lastUpdated, setLastUpdated] = useState(null);
  const [updatingId, setUpdatingId] = useState(null);

  const fetchBookings = useCallback(async (silent = false) => {
    if (!silent) setLoading(true);
    else setRefreshing(true);
    try {
      const res = await api.get('/bookings/owner');
      setBookings(res.data.data);
      setLastUpdated(new Date());
      setError('');
    } catch {
      setError('Failed to load bookings');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchBookings();
  }, [fetchBookings, refreshTrigger]);

  useEffect(() => {
    const interval = setInterval(() => fetchBookings(true), 30000);
    return () => clearInterval(interval);
  }, [fetchBookings]);

  const updateStatus = async (id, status) => {
    setUpdatingId(id);
    try {
      await api.patch(`/bookings/${id}/status`, { status });
      setBookings((prev) => prev.map((b) => (b._id === id ? { ...b, status } : b)));
      toast.success(status === 'confirmed' ? 'Booking confirmed' : 'Booking rejected');
    } catch (err) {
      toast.error(err.response?.data?.error || 'Failed to update booking');
    } finally {
      setUpdatingId(null);
    }
  };

  if (loading) return <TableSkeleton />;
  if (error) return <Alert variant="danger">{error}</Alert>;

  return (
    <Card className="shadow-sm">
      <Card.Header className="bg-white d-flex justify-content-between align-items-center">
        <span className="fw-bold">Recent Bookings ({bookings.length})</span>
        <div className="d-flex align-items-center gap-2">
          {lastUpdated && (
            <small className="text-muted">
              Updated {lastUpdated.toLocaleTimeString()}
            </small>
          )}
          <Button
            variant="outline-secondary"
            size="sm"
            onClick={() => fetchBookings(true)}
            disabled={refreshing}
          >
            <RefreshCw size={14} className={refreshing ? 'spin-icon' : ''} />
            {refreshing ? ' Refreshing...' : ' Refresh'}
          </Button>
        </div>
      </Card.Header>

      {bookings.length === 0 ? (
        <Card.Body>
          <EmptyState icon={CalendarX} title="No bookings found yet" />
        </Card.Body>
      ) : (
        <Table responsive hover className="mb-0">
          <thead className="bg-light">
            <tr>
              <th>Venue</th>
              {isAdmin && <th>Owner</th>}
              <th>Customer</th>
              <th>Date</th>
              <th>Time</th>
              <th>Status</th>
              <th>Payment</th>
              <th>Price</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {bookings.map((booking) => (
              <tr key={booking._id}>
                <td>{booking.venue?.name || 'Unknown'}</td>
                {isAdmin && <td>{booking.venue?.owner?.name || 'Unknown'}</td>}
                <td>
                  <div>{booking.user?.name || 'Unknown'}</div>
                  <small className="text-muted">{booking.user?.email}</small>
                </td>
                <td>{booking.date}</td>
                <td>{booking.startTime} - {booking.endTime}</td>
                <td>
                  <Badge
                    bg={booking.status === 'confirmed' ? 'success' : booking.status === 'cancelled' ? 'danger' : 'warning'}
                  >
                    {booking.status}
                  </Badge>
                </td>
                <td>
                  <Badge
                    bg={booking.paymentStatus === 'paid' ? 'success' : 'secondary'}
                  >
                    {booking.paymentStatus || 'unpaid'}
                  </Badge>
                </td>
                <td className="fw-bold">${booking.price}</td>
                <td>
                  {booking.status === 'pending' && (
                    <div className="d-flex gap-1">
                      <Button
                        variant="outline-success"
                        size="sm"
                        disabled={updatingId === booking._id}
                        onClick={() => updateStatus(booking._id, 'confirmed')}
                        title="Confirm booking"
                      >
                        <Check size={14} />
                      </Button>
                      <Button
                        variant="outline-danger"
                        size="sm"
                        disabled={updatingId === booking._id}
                        onClick={() => updateStatus(booking._id, 'cancelled')}
                        title="Reject booking"
                      >
                        <X size={14} />
                      </Button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}
    </Card>
  );
};

export default BookingList;
