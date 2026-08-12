import { useState, useEffect } from 'react';
import { Row, Col, Card, Alert } from 'react-bootstrap';
import {
  BarChart, Bar, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts';
import api from '../api/axios';
import { TrendingUp, Users, DollarSign } from 'lucide-react';
import { MetricCardSkeleton } from './Skeletons';

const AnalyticsDashboard = ({ refreshTrigger }) => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchData = async () => {
      try {
        const res = await api.get('/analytics');
        setData(res.data.data);
      } catch {
        setError('Failed to load analytics');
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [refreshTrigger]);

  if (loading) {
    return (
      <div>
        <h4 className="mb-4">Overview</h4>
        <Row className="mb-4">
          {[0, 1, 2].map((i) => (
            <Col md={4} key={i}><MetricCardSkeleton /></Col>
          ))}
        </Row>
      </div>
    );
  }
  if (error) return <Alert variant="danger">{error}</Alert>;
  if (!data) return null;

  return (
    <div>
      <h4 className="mb-4">Overview</h4>

      {/* Metrics Cards */}
      <Row className="mb-4">
        <Col md={4}>
          <Card className="text-center h-100 shadow-sm border-0">
            <Card.Body>
              <DollarSign size={32} className="text-success mb-2" />
              <h3>${data.totalRevenue}</h3>
              <p className="text-muted">Total Revenue</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="text-center h-100 shadow-sm border-0">
            <Card.Body>
              <Users size={32} className="text-primary mb-2" />
              <h3>{data.totalBookings}</h3>
              <p className="text-muted">Total Bookings</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="text-center h-100 shadow-sm border-0">
            <Card.Body>
              <TrendingUp size={32} className="text-info mb-2" />
              <h3>{data.bookingsPerVenue.length}</h3>
              <p className="text-muted">Active Venues</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Revenue over time */}
      <Card className="shadow-sm border-0 p-3 mb-4">
        <h5 className="mb-3">Revenue (Last 30 Days)</h5>
        <div style={{ height: 300 }}>
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data.revenueOverTime}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip formatter={(value) => [`$${value}`, 'Revenue']} />
              <Line type="monotone" dataKey="revenue" stroke="#16a34a" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </Card>

      {/* Bookings per venue */}
      <Card className="shadow-sm border-0 p-3 mb-4">
        <h5 className="mb-3">Bookings per Venue</h5>
        <div style={{ height: 300 }}>
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={data.bookingsPerVenue}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="value" fill="#8884d8" name="Bookings" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </Card>
    </div>
  );
};

export default AnalyticsDashboard;
