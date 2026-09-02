const { AppError, asyncHandler } = require('../utils/api');

const allowedMimeTypes = new Set(['application/pdf', 'image/jpeg', 'image/png', 'image/webp']);

const validateUploadedFiles = asyncHandler(async (req, _res, next) => {
  const files = [...(req.file ? [req.file] : []), ...(Array.isArray(req.files) ? req.files : [])];
  if (!files.length) return next();
  const { fileTypeFromBuffer } = await import('file-type');
  for (const file of files) {
    const detected = await fileTypeFromBuffer(file.buffer);
    if (!detected || !allowedMimeTypes.has(detected.mime) || detected.mime !== file.mimetype) {
      throw new AppError(422, 'FILE_CONTENT_MISMATCH', `Le contenu réel du fichier « ${file.originalname} » ne correspond pas à un format PDF, JPEG, PNG ou WebP autorisé`);
    }
    file.mimetype = detected.mime;
  }
  next();
});

module.exports = { allowedMimeTypes, validateUploadedFiles };
