import { useState, useEffect } from 'react';
import { Table, Badge, Spinner, Alert, Card } from 'react-bootstrap';
import api from '../api/axios';

const BookingList = () => {
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchBookings = async () => {
    try {
      const res = await api.get('/bookings/owner');
      setBookings(res.data.data);
      setLoading(false);
    } catch (err) {
      setError('Failed to load bookings');
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBookings();
  }, []);

  if (loading) return <div className="text-center py-4"><Spinner animation="border" /></div>;
  if (error) return <Alert variant="danger">{error}</Alert>;
  if (bookings.length === 0) return <Alert variant="info">No bookings found yet.</Alert>;

  return (
    <Card className="shadow-sm">
      <Card.Header className="bg-white fw-bold">Recent Bookings</Card.Header>
      <Table responsive hover className="mb-0">
        <thead className="bg-light">
          <tr>
            <th>Venue</th>
            <th>Customer</th>
            <th>Date</th>
            <th>Time</th>
            <th>Status</th>
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
              <td className="fw-bold">${booking.price}</td>
            </tr>
          ))}
        </tbody>
      </Table>
    </Card>
  );
};

export default BookingList;
