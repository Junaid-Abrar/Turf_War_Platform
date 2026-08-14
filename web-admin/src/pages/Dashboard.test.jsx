import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import Dashboard from './Dashboard';
import AuthContext from '../context/AuthContext';
import ThemeContext from '../context/ThemeContext';

vi.mock('react-router-dom', () => ({
  useNavigate: () => vi.fn(),
}));

vi.mock('../components/VenueList', () => ({
  default: ({ isAdmin }) => <div data-testid="venue-list">{String(isAdmin)}</div>,
}));
vi.mock('../components/BookingList', () => ({
  default: ({ isAdmin }) => <div data-testid="booking-list">{String(isAdmin)}</div>,
}));
vi.mock('../components/ChatSystem', () => ({ default: () => <div>chats</div> }));
vi.mock('../components/AnalyticsDashboard', () => ({
  default: ({ isAdmin }) => <div data-testid="analytics">{String(isAdmin)}</div>,
}));
vi.mock('../components/AddVenueModal', () => ({ default: () => null }));
vi.mock('../components/UserManagement', () => ({ default: () => <div>users</div> }));

const renderAs = (role) =>
  render(
    <AuthContext.Provider value={{ user: { name: 'Test', role }, logout: vi.fn() }}>
      <ThemeContext.Provider value={{ theme: 'light', toggleTheme: vi.fn() }}>
        <Dashboard />
      </ThemeContext.Provider>
    </AuthContext.Provider>
  );

describe('Dashboard role rendering', () => {
  it('brands and labels itself for a venue owner, and shows Add Venue', () => {
    renderAs('venue_owner');

    expect(screen.getByText('Turf War — My Venues')).toBeInTheDocument();
    expect(screen.getByText('My Venues')).toBeInTheDocument();
    expect(screen.getByText('Add Venue')).toBeInTheDocument();
    expect(screen.getByTestId('venue-list')).toHaveTextContent('false');
    expect(screen.getByTestId('booking-list')).toHaveTextContent('false');
    expect(screen.getByTestId('analytics')).toHaveTextContent('false');
    expect(screen.queryByText('Users')).not.toBeInTheDocument();
  });

  it('brands and labels itself for an admin, hides Add Venue, and shows the Users tab', () => {
    renderAs('admin');

    expect(screen.getByText('Turf War Admin')).toBeInTheDocument();
    expect(screen.getByText('Platform Administration')).toBeInTheDocument();
    expect(screen.queryByText('Add Venue')).not.toBeInTheDocument();
    expect(screen.getByTestId('venue-list')).toHaveTextContent('true');
    expect(screen.getByTestId('booking-list')).toHaveTextContent('true');
    expect(screen.getByTestId('analytics')).toHaveTextContent('true');
    expect(screen.getByText('Users')).toBeInTheDocument();
  });
});
