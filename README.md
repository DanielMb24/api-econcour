# API eConcour

Backend Express/MongoDB de GabConcours, compatible avec Vercel Functions.

## Variables Vercel obligatoires

- `NODE_ENV=production`
- `DATABASE_DRIVER=mongodb`
- `MONGODB_URI`
- `MONGODB_DB_NAME=gabconcours`
- `JWT_SECRET`
- `CORS_ORIGINS` (URL exacte du frontend)

Pour l'envoi des identifiants, ajouter `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS` et `FRONTEND_URL`.

Après déploiement, vérifier `GET /api/v1/health`.

Les secrets ne doivent jamais être ajoutés au dépôt Git.
