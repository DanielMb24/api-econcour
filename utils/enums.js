module.exports = Object.freeze({
  APPLICATION_STATUS: ['draft', 'submitted', 'under_review', 'approved', 'rejected', 'cancelled'],
  DOCUMENT_STATUS: ['pending', 'uploaded', 'under_review', 'approved', 'rejected'],
  PAYMENT_STATUS: ['pending', 'processing', 'paid', 'failed', 'cancelled', 'refunded'],
  ADMIN_ROLES: ['super_admin', 'admin', 'reviewer', 'finance'],
});
