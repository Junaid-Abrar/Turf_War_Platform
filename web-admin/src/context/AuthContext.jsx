import { createContext, useState, useEffect, useCallback } from 'react';
import { jwtDecode } from 'jwt-decode';
import toast from 'react-hot-toast';
import api, { setOnUnauthorized } from '../api/axios';

const AuthContext = createContext();

const isExpired = (decoded) => !decoded.exp || decoded.exp * 1000 <= Date.now();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  const logout = useCallback(() => {
    localStorage.removeItem('adminToken');
    setUser(null);
  }, []);

  useEffect(() => {
    const token = localStorage.getItem('adminToken');
    if (token) {
      try {
        const decoded = jwtDecode(token);
        if (isExpired(decoded)) {
          localStorage.removeItem('adminToken');
        } else {
          // eslint-disable-next-line react-hooks/set-state-in-effect -- one-time auth check on mount, not a render-driven update
          setUser(decoded);
        }
      } catch {
        localStorage.removeItem('adminToken');
      }
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    setOnUnauthorized(() => {
      localStorage.removeItem('adminToken');
      setUser(null);
      toast.error('Your session has expired. Please log in again.');
    });
    return () => setOnUnauthorized(null);
  }, []);

  const login = async (email, password) => {
    try {
      const res = await api.post('/auth/login', { email, password });
      const { token } = res.data;
      const decoded = jwtDecode(token);

      if (isExpired(decoded)) {
        return { success: false, error: 'Received an already-expired session. Please try again.' };
      }

      localStorage.setItem('adminToken', token);
      setUser(decoded);
      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.error || 'Login failed',
      };
    }
  };

  return (
    <AuthContext.Provider value={{ user, login, logout, loading }}>
      {children}
    </AuthContext.Provider>
  );
};

export default AuthContext;
