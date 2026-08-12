import { Routes, Route, Navigate } from 'react-router-dom';
import { useContext } from 'react';
import { Spinner } from 'react-bootstrap';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import AuthContext from './context/AuthContext';

// Protected Route Component
const PrivateRoute = ({ children }) => {
  const { user, loading } = useContext(AuthContext);

  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center" style={{ minHeight: '100vh' }}>
        <Spinner animation="border" />
      </div>
    );
  }

  return user ? children : <Navigate to="/login" />;
};

function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route 
        path="/dashboard" 
        element={
          <PrivateRoute>
            <Dashboard />
          </PrivateRoute>
        } 
      />
      {/* Redirect root to dashboard (which redirects to login if needed) */}
      <Route path="/" element={<Navigate to="/dashboard" />} />
    </Routes>
  );
}

export default App;