module.exports = Object.freeze({
  APPLICATION_STATUS: ['draft', 'submitted', 'under_review', 'approved', 'rejected', 'cancelled'],
  DOCUMENT_STATUS: ['pending', 'uploaded', 'under_review', 'approved', 'rejected'],
  PAYMENT_STATUS: ['pending', 'processing', 'paid', 'failed', 'cancelled', 'refunded'],
  ADMIN_ROLES: ['super_admin', 'admin', 'admin_etablissement', 'reviewer', 'finance', 'sub_admin'],
  SUB_ADMIN_ROLES: ['applications_manager', 'documents_validator', 'documents_viewer', 'grades_entry', 'grades_validator', 'payments_viewer', 'reports_viewer', 'messaging_agent'],
  ADMIN_PERMISSIONS: ['manage_subadmins', 'view_applications', 'manage_applications', 'view_documents', 'validate_documents', 'enter_grades', 'validate_grades', 'view_payments', 'manage_payments', 'view_reports', 'manage_messages'],
});
