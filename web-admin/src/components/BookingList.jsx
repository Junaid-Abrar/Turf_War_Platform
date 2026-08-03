import { useState, useEffect, useCallback } from 'react';
import { Table, Badge, Spinner, Alert, Card, Button } from 'react-bootstrap';
import { RefreshCw } from 'lucide-react';
import api from '../api/axios';

const BookingList = ({ refreshTrigger }) => {
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [lastUpdated, setLastUpdated] = useState(null);

  const fetchBookings = useCallback(async (silent = false) => {
    if (!silent) setLoading(true);
    else setRefreshing(true);
    try {
      const res = await api.get('/bookings/owner');
      setBookings(res.data.data);
      setLastUpdated(new Date());
      setError('');
    } catch (err) {
      setError('Failed to load bookings');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  // Initial fetch + re-fetch when parent increments refreshTrigger
  useEffect(() => {
    fetchBookings();
  }, [fetchBookings, refreshTrigger]);

  // Auto-poll every 30 seconds for new bookings
  useEffect(() => {
    const interval = setInterval(() => fetchBookings(true), 30000);
    return () => clearInterval(interval);
  }, [fetchBookings]);

  if (loading) return <div className="text-center py-4"><Spinner animation="border" /></div>;
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
          <Alert variant="info" className="mb-0">No bookings found yet.</Alert>
        </Card.Body>
      ) : (
        <Table responsive hover className="mb-0">
          <thead className="bg-light">
            <tr>
              <th>Venue</th>
              <th>Customer</th>
              <th>Date</th>
              <th>Time</th>
              <th>Status</th>
              <th>Payment</th>
              <th>Price</th>
            </tr>
          </thead>
          <tbody>
            {bookings.map((booking) => (
              <tr key={booking._id}>
                <td>{booking.venue?.name || 'Unknown'}</td>
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
              </tr>
            ))}
          </tbody>
        </Table>
      )}
    </Card>
  );
};

export default BookingList;
