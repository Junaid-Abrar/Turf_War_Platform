import { Card, Placeholder, Row, Col } from 'react-bootstrap';

export const VenueCardSkeleton = () => (
  <Card className="h-100 shadow-sm">
    <div style={{ height: '200px', backgroundColor: 'var(--bs-tertiary-bg)' }} />
    <Card.Body>
      <Placeholder as="div" animation="glow">
        <Placeholder xs={7} size="lg" /> <Placeholder xs={3} />
        <Placeholder xs={5} className="d-block mt-2" />
        <Placeholder xs={12} className="d-block mt-2" />
        <Placeholder xs={9} />
      </Placeholder>
    </Card.Body>
  </Card>
);

export const VenueGridSkeleton = ({ count = 3 }) => (
  <Row xs={1} md={2} lg={3} className="g-4">
    {Array.from({ length: count }).map((_, i) => (
      <Col key={`venue-skeleton-${i}`}>
        <VenueCardSkeleton />
      </Col>
    ))}
  </Row>
);

export const TableSkeleton = ({ rows = 5, cols = 5 }) => (
  <Placeholder as="div" animation="glow">
    {Array.from({ length: rows }).map((_, r) => (
      <div key={`row-skeleton-${r}`} className="d-flex gap-3 py-3 border-bottom px-3">
        {Array.from({ length: cols }).map((_, c) => (
          <Placeholder key={`cell-skeleton-${r}-${c}`} style={{ flex: 1 }} />
        ))}
      </div>
    ))}
  </Placeholder>
);

export const MetricCardSkeleton = () => (
  <Card className="text-center h-100 shadow-sm border-0">
    <Card.Body>
      <Placeholder as="div" animation="glow">
        <Placeholder xs={4} size="lg" className="d-block mx-auto mb-2" />
        <Placeholder xs={6} className="d-block mx-auto" />
      </Placeholder>
    </Card.Body>
  </Card>
);
