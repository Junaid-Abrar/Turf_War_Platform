import { useState, useEffect } from 'react';
import { Card, Button, Row, Col, Badge, Spinner, Alert } from 'react-bootstrap';
import { Trash2, MapPin, DollarSign } from 'lucide-react'; // Icons
import api from '../api/axios';

const VenueList = ({ refreshTrigger }) => {
  const [venues, setVenues] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchVenues = async () => {
    try {
      const res = await api.get('/venues/mine'); // Only fetch MY venues
      setVenues(res.data.data);
      setLoading(false);
    } catch (err) {
      setError('Failed to load venues');
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVenues();
  }, [refreshTrigger]);

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this venue?')) {
      try {
        await api.delete(`/venues/${id}`);
        // Remove from local state to avoid refetch
        setVenues(venues.filter(v => v._id !== id));
      } catch (err) {
        alert('Failed to delete venue');
      }
    }
  };

  if (loading) return <div className="text-center mt-5"><Spinner animation="border" /></div>;
  if (error) return <Alert variant="danger">{error}</Alert>;

  return (
    <Row xs={1} md={2} lg={3} className="g-4">
      {venues.map((venue) => (
        <Col key={venue._id}>
          <Card className="h-100 shadow-sm">
            <div style={{ height: '200px', overflow: 'hidden', backgroundColor: '#eee' }}>
              {venue.images && venue.images[0] ? (
                <Card.Img 
                  variant="top" 
                  src={venue.images[0]} 
                  style={{ height: '100%', objectFit: 'cover' }} 
                />
              ) : (
                <div className="d-flex align-items-center justify-content-center h-100 text-muted">
                  No Image
                </div>
              )}
            </div>
            <Card.Body>
              <Card.Title className="d-flex justify-content-between align-items-start">
                <span>{venue.name}</span>
                <Badge bg="success">${venue.pricePerHour}/hr</Badge>
              </Card.Title>
              <Card.Text className="text-muted small mb-2">
                <MapPin size={14} className="me-1" />
                {venue.location}
              </Card.Text>
              <Card.Text>
                {venue.description.substring(0, 100)}...
              </Card.Text>
              
              <div className="mt-3">
                {venue.amenities.map(a => (
                  <Badge bg="light" text="dark" className="me-1 border" key={a}>
                    {a}
                  </Badge>
                ))}
              </div>
            </Card.Body>
            <Card.Footer className="bg-white border-top-0 text-end">
              <Button 
                variant="outline-danger" 
                size="sm" 
                onClick={() => handleDelete(venue._id)}
              >
                <Trash2 size={16} /> Delete
              </Button>
            </Card.Footer>
          </Card>
        </Col>
      ))}
    </Row>
  );
};

export default VenueList;
