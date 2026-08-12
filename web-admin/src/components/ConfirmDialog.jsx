import { Modal, Button, Spinner } from 'react-bootstrap';

const ConfirmDialog = ({
  show,
  title = 'Are you sure?',
  body,
  confirmLabel = 'Confirm',
  confirmVariant = 'danger',
  loading = false,
  onConfirm,
  onCancel,
}) => (
  <Modal show={show} onHide={onCancel} centered>
    <Modal.Header closeButton>
      <Modal.Title>{title}</Modal.Title>
    </Modal.Header>
    <Modal.Body>{body}</Modal.Body>
    <Modal.Footer>
      <Button variant="secondary" onClick={onCancel} disabled={loading}>
        Cancel
      </Button>
      <Button variant={confirmVariant} onClick={onConfirm} disabled={loading}>
        {loading ? <Spinner animation="border" size="sm" /> : confirmLabel}
      </Button>
    </Modal.Footer>
  </Modal>
);

export default ConfirmDialog;
