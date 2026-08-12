import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ConfirmDialog from './ConfirmDialog';

describe('ConfirmDialog', () => {
  it('renders nothing interactive when hidden', () => {
    render(<ConfirmDialog show={false} onConfirm={vi.fn()} onCancel={vi.fn()} />);
    expect(screen.queryByText('Confirm')).not.toBeInTheDocument();
  });

  it('shows title and body, and calls onConfirm when confirmed', async () => {
    const onConfirm = vi.fn();
    const onCancel = vi.fn();
    render(
      <ConfirmDialog
        show
        title="Delete venue?"
        body="This cannot be undone."
        confirmLabel="Delete"
        onConfirm={onConfirm}
        onCancel={onCancel}
      />
    );

    expect(screen.getByText('Delete venue?')).toBeInTheDocument();
    expect(screen.getByText('This cannot be undone.')).toBeInTheDocument();

    await userEvent.click(screen.getByText('Delete'));
    expect(onConfirm).toHaveBeenCalledTimes(1);
    expect(onCancel).not.toHaveBeenCalled();
  });

  it('calls onCancel when Cancel is clicked', async () => {
    const onCancel = vi.fn();
    render(<ConfirmDialog show onConfirm={vi.fn()} onCancel={onCancel} />);

    await userEvent.click(screen.getByText('Cancel'));
    expect(onCancel).toHaveBeenCalledTimes(1);
  });

  it('disables the confirm button and shows a spinner while loading', () => {
    render(<ConfirmDialog show loading confirmLabel="Delete" onConfirm={vi.fn()} onCancel={vi.fn()} />);
    expect(screen.queryByText('Delete')).not.toBeInTheDocument();
    expect(screen.getByRole('button', { name: /cancel/i })).toBeDisabled();
  });
});
