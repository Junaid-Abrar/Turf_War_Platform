import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useContext } from 'react';
import AuthContext, { AuthProvider } from './AuthContext';
import api from '../api/axios';
import { makeValidToken, makeExpiredToken } from '../test/fakeJwt';

vi.mock('../api/axios', () => ({
  default: { post: vi.fn() },
  setOnUnauthorized: vi.fn(),
}));

const Probe = () => {
  const { user, loading, login, logout } = useContext(AuthContext);
  return (
    <div>
      <span data-testid="loading">{String(loading)}</span>
      <span data-testid="user">{user ? user.email : 'none'}</span>
      <button onClick={() => login('ada@example.com', 'secret')}>login</button>
      <button onClick={logout}>logout</button>
    </div>
  );
};

const renderWithProvider = () =>
  render(
    <AuthProvider>
      <Probe />
    </AuthProvider>
  );

describe('AuthContext', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.clearAllMocks();
  });

  it('starts with no user when localStorage is empty', async () => {
    renderWithProvider();
    await waitFor(() => expect(screen.getByTestId('loading')).toHaveTextContent('false'));
    expect(screen.getByTestId('user')).toHaveTextContent('none');
  });

  it('restores the user from a valid token in localStorage', async () => {
    localStorage.setItem('adminToken', makeValidToken());
    renderWithProvider();
    await waitFor(() => expect(screen.getByTestId('user')).toHaveTextContent('ada@example.com'));
  });

  it('discards an expired token instead of restoring the user', async () => {
    localStorage.setItem('adminToken', makeExpiredToken());
    renderWithProvider();
    await waitFor(() => expect(screen.getByTestId('loading')).toHaveTextContent('false'));
    expect(screen.getByTestId('user')).toHaveTextContent('none');
    expect(localStorage.getItem('adminToken')).toBeNull();
  });

  it('logs in successfully and stores the token', async () => {
    api.post.mockResolvedValueOnce({ data: { token: makeValidToken() } });
    renderWithProvider();
    await waitFor(() => expect(screen.getByTestId('loading')).toHaveTextContent('false'));

    await userEvent.click(screen.getByText('login'));

    await waitFor(() => expect(screen.getByTestId('user')).toHaveTextContent('ada@example.com'));
    expect(localStorage.getItem('adminToken')).toBeTruthy();
  });

  it('logs out and clears the token', async () => {
    localStorage.setItem('adminToken', makeValidToken());
    renderWithProvider();
    await waitFor(() => expect(screen.getByTestId('user')).toHaveTextContent('ada@example.com'));

    await userEvent.click(screen.getByText('logout'));

    expect(screen.getByTestId('user')).toHaveTextContent('none');
    expect(localStorage.getItem('adminToken')).toBeNull();
  });
});
