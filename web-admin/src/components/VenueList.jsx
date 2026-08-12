import { useState, useEffect } from 'react';
import { Card, Button, Row, Col, Badge, Alert } from 'react-bootstrap';
import { Trash2, Pencil, MapPin, LayoutGrid } from 'lucide-react';
import toast from 'react-hot-toast';
import api from '../api/axios';
import { VenueGridSkeleton } from './Skeletons';
import EmptyState from './EmptyState';
import ConfirmDialog from './ConfirmDialog';
import EditVenueModal from './EditVenueModal';

const VenueList = ({ refreshTrigger }) => {
  const [venues, setVenues] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleting, setDeleting] = useState(false);
  const [editTarget, setEditTarget] = useState(null);

  const fetchVenues = async () => {
    try {
      const res = await api.get('/venues/mine');
      setVenues(res.data.data);
      setError('');
    } catch {
      setError('Failed to load venues');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVenues();
  }, [refreshTrigger]);

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await api.delete(`/venues/${deleteTarget._id}`);
      setVenues(venues.filter((v) => v._id !== deleteTarget._id));
      toast.success('Venue deleted');
      setDeleteTarget(null);
    } catch {
      toast.error('Failed to delete venue');
    } finally {
      setDeleting(false);
    }
  };

  if (loading) return <VenueGridSkeleton />;
  if (error) return <Alert variant="danger">{error}</Alert>;

  if (venues.length === 0) {
    return (
      <EmptyState
        icon={LayoutGrid}
        title="No venues yet"
        description="Add your first venue to start accepting bookings."
      />
    );
  }

  return (
    <>
      <Row xs={1} md={2} lg={3} className="g-4">
        {venues.map((venue) => (
          <Col key={venue._id}>
            <Card className="h-100 shadow-sm">
              <div style={{ height: '200px', overflow: 'hidden', backgroundColor: 'var(--bs-tertiary-bg)' }}>
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
                  {venue.amenities.map((a) => (
                    <Badge bg="light" text="dark" className="me-1 border" key={a}>
                      {a}
                    </Badge>
                  ))}
                </div>
              </Card.Body>
              <Card.Footer className="bg-white border-top-0 text-end">
                <Button
                  variant="outline-secondary"
                  size="sm"
                  className="me-2"
                  onClick={() => setEditTarget(venue)}
                >
                  <Pencil size={16} /> Edit
                </Button>
                <Button
                  variant="outline-danger"
                  size="sm"
                  onClick={() => setDeleteTarget(venue)}
                >
                  <Trash2 size={16} /> Delete
                </Button>
              </Card.Footer>
            </Card>
          </Col>
        ))}
      </Row>

      <ConfirmDialog
        show={!!deleteTarget}
        title="Delete venue?"
        body={`This will permanently delete "${deleteTarget?.name}" and cannot be undone.`}
        confirmLabel="Delete"
        confirmVariant="danger"
        loading={deleting}
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />

      <EditVenueModal
        show={!!editTarget}
        venue={editTarget}
        handleClose={() => setEditTarget(null)}
        onVenueUpdated={fetchVenues}
      />
    </>
  );
};

export default VenueList;
