import { useState } from 'react';
import { Modal, Button, Form, Alert, Spinner, Badge } from 'react-bootstrap';
import toast from 'react-hot-toast';
import api from '../api/axios';

const AMENITY_OPTIONS = [
  'Wifi', 'Parking', 'Showers', 'Lockers', 'Water',
  'Floodlights', 'Changing Rooms', 'Cafeteria', 'First Aid',
];

const AddVenueModal = ({ show, handleClose, onVenueAdded }) => {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    location: '',
    pricePerHour: '',
  });
  const [selectedAmenities, setSelectedAmenities] = useState([]);
  const [image, setImage] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleFileChange = (e) => {
    setImage(e.target.files[0]);
  };

  const toggleAmenity = (amenity) => {
    setSelectedAmenities(prev =>
      prev.includes(amenity)
        ? prev.filter(a => a !== amenity)
        : [...prev, amenity]
    );
  };

  const handleClose_ = () => {
    setFormData({ name: '', description: '', location: '', pricePerHour: '' });
    setSelectedAmenities([]);
    setImage(null);
    setError('');
    handleClose();
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const data = new FormData();
      data.append('name', formData.name);
      data.append('description', formData.description);
      data.append('location', formData.location);
      data.append('pricePerHour', formData.pricePerHour);
      if (image) {
        data.append('photo', image);
      }
      // Append amenities as a JSON string so the backend can parse them
      data.append('amenities', JSON.stringify(selectedAmenities));

      await api.post('/venues', data, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });

      setLoading(false);
      toast.success('Venue created');
      onVenueAdded(); // Refresh list
      handleClose_();
    } catch (err) {
      console.error(err);
      setError(err.response?.data?.error || 'Failed to create venue');
      setLoading(false);
    }
  };

  return (
    <Modal show={show} onHide={handleClose_}>
      <Modal.Header closeButton>
        <Modal.Title>Add New Venue</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        {error && <Alert variant="danger">{error}</Alert>}
        <Form onSubmit={handleSubmit}>
          <Form.Group className="mb-3">
            <Form.Label>Venue Name</Form.Label>
            <Form.Control 
              type="text" name="name" required 
              value={formData.name} onChange={handleChange} 
            />
          </Form.Group>
          
          <Form.Group className="mb-3">
            <Form.Label>Location</Form.Label>
            <Form.Control 
              type="text" name="location" required 
              value={formData.location} onChange={handleChange} 
            />
          </Form.Group>

          <Form.Group className="mb-3">
            <Form.Label>Price Per Hour ($)</Form.Label>
            <Form.Control 
              type="number" name="pricePerHour" required 
              value={formData.pricePerHour} onChange={handleChange} 
            />
          </Form.Group>

          <Form.Group className="mb-3">
            <Form.Label>Description</Form.Label>
            <Form.Control 
              as="textarea" rows={3} name="description" required 
              value={formData.description} onChange={handleChange} 
            />
          </Form.Group>

          <Form.Group className="mb-3">
            <Form.Label>Amenities</Form.Label>
            <div className="d-flex flex-wrap gap-2 mt-1">
              {AMENITY_OPTIONS.map(amenity => (
                <Badge
                  key={amenity}
                  bg={selectedAmenities.includes(amenity) ? 'success' : 'light'}
                  text={selectedAmenities.includes(amenity) ? 'white' : 'dark'}
                  className="border"
                  style={{ cursor: 'pointer', fontSize: '0.85rem', padding: '6px 10px' }}
                  onClick={() => toggleAmenity(amenity)}
                >
                  {selectedAmenities.includes(amenity) ? '✓ ' : ''}{amenity}
                </Badge>
              ))}
            </div>
            {selectedAmenities.length > 0 && (
              <small className="text-muted mt-1 d-block">
                Selected: {selectedAmenities.join(', ')}
              </small>
            )}
          </Form.Group>

          <Form.Group className="mb-3">
            <Form.Label>Cover Image</Form.Label>
            <Form.Control 
              type="file" accept="image/*" 
              onChange={handleFileChange} 
            />
          </Form.Group>

          <div className="d-flex justify-content-end">
            <Button variant="secondary" onClick={handleClose_} className="me-2">
              Cancel
            </Button>
            <Button variant="success" type="submit" disabled={loading}>
              {loading ? <Spinner animation="border" size="sm" /> : 'Create Venue'}
            </Button>
          </div>
        </Form>
      </Modal.Body>
    </Modal>
  );
};

export default AddVenueModal;
