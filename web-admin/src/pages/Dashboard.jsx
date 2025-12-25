import { useContext, useState } from 'react';
import { Container, Navbar, Nav, Button, Tabs, Tab } from 'react-bootstrap';
import AuthContext from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import VenueList from '../components/VenueList';
import BookingList from '../components/BookingList';
import AddVenueModal from '../components/AddVenueModal';
import { PlusCircle, LayoutGrid, Calendar } from 'lucide-react';

const Dashboard = () => {
  const { logout, user } = useContext(AuthContext);
  const navigate = useNavigate();
  
  const [showAddModal, setShowAddModal] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0); 

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const handleVenueAdded = () => {
    setRefreshKey(prev => prev + 1);
  };

  return (
    <>
      <Navbar bg="dark" variant="dark" expand="lg" className="mb-4">
        <Container>
          <Navbar.Brand href="#home">Turf War Admin</Navbar.Brand>
          <Navbar.Toggle aria-controls="basic-navbar-nav" />
          <Navbar.Collapse id="basic-navbar-nav" className="justify-content-end">
            <Nav className="align-items-center">
              <Navbar.Text className="me-3">
                Hello, <span className="text-white fw-bold">{user?.name || user?.id}</span>
              </Navbar.Text>
              <Button variant="outline-light" size="sm" onClick={handleLogout}>Logout</Button>
            </Nav>
          </Navbar.Collapse>
        </Container>
      </Navbar>

      <Container>
        <div className="d-flex justify-content-between align-items-center mb-4">
          <h2>Dashboard</h2>
          <Button variant="success" onClick={() => setShowAddModal(true)}>
            <PlusCircle size={18} className="me-2" />
            Add Venue
          </Button>
        </div>

        <Tabs defaultActiveKey="venues" className="mb-4">
          <Tab eventKey="venues" title={<><LayoutGrid size={16} className="me-1"/> Venues</>}>
            <VenueList refreshTrigger={refreshKey} />
          </Tab>
          <Tab eventKey="bookings" title={<><Calendar size={16} className="me-1"/> Bookings</>}>
            <BookingList />
          </Tab>
        </Tabs>

        <AddVenueModal 
          show={showAddModal} 
          handleClose={() => setShowAddModal(false)} 
          onVenueAdded={handleVenueAdded}
        />
      </Container>
    </>
  );
};

export default Dashboard;
