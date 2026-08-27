# GabConcours Backend

Backend API pour la plateforme de gestion des concours gabonaise.

## Technologies utilisées

- **Node.js** - Runtime JavaScript
- **Express.js** - Framework web
- **MySQL2** - Base de données MySQL
- **Multer** - Upload de fichiers
- **JWT** - Authentification
- **CORS** - Gestion des requêtes cross-origin

## Installation et configuration

### 1. Installation des dépendances

```bash
cd backend
npm install
```

### 2. Configuration de l'environnement

Copiez le fichier `.env` et modifiez les paramètres selon votre configuration :

```env
# Configuration de la base de données
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=votre_mot_de_passe
DB_NAME=gabconcours
DB_PORT=3306

# Configuration du serveur
PORT=3001
NODE_ENV=development

# JWT Secret
JWT_SECRET=votre_cle_secrete_jwt

# Upload paths
UPLOAD_PATH=uploads
```

### 3. Initialisation de la base de données

```bash
npm run init-db
```

Cette commande va :

- Créer la base de données `gabconcours`
- Créer toutes les tables nécessaires
- Insérer des données de test

### 4. Démarrage du serveur

```bash
# Mode développement (avec nodemon)
npm run dev

# Mode production
npm start
```

Le serveur sera accessible sur `http://localhost:3001`

## Structure de l'API

### Endpoints principaux

- `GET /api` - Information sur l'API
- `GET /api/concours` - Liste des concours
- `GET /api/concours/:id` - Détails d'un concours
- `POST /api/etudiants` - Création d'un étudiant/candidature
- `GET /api/candidats/nip/:nip` - Recherche par NIP
- `GET /api/participations/numero/:numero` - Recherche par numéro de candidature
- `GET /api/provinces` - Liste des provinces
- `POST /api/payements` - Création d'un paiement
- `POST /api/dossiers` - Upload de documents

### Format des réponses

Toutes les réponses suivent le format :

```json
{
  "success": true,
  "data": {
    ...
  },
  "message": "Description du résultat"
}
```

En cas d'erreur :

```json
{
  "success": false,
  "message": "Description de l'erreur",
  "errors": [
    "Détails de l'erreur"
  ]
}
```

## Base de données

### Tables principales

- `provinces` - Provinces du Gabon
- `niveaux` - Niveaux d'études
- `etablissements` - Établissements d'enseignement
- `concours` - Concours disponibles
- `candidats` - Informations des candidats
- `participations` - Inscriptions aux concours
- `documents` - Documents uploadés
- `dossiers` - Gestion des dossiers
- `paiements` - Paiements des frais
- `sessions` - Sessions utilisateur

### Relations

- Un candidat peut avoir plusieurs participations
- Une participation correspond à un concours et un candidat
- Un paiement est lié à un candidat
- Les documents sont liés aux dossiers

## Upload de fichiers

Les fichiers sont stockés dans le dossier `uploads/` avec la structure :

- `uploads/documents/` - Documents des candidatures

Formats acceptés : PDF, JPEG, PNG
Taille maximale : 5MB par fichier

## Sécurité

- CORS configuré pour le développement local
- Validation des types de fichiers
- Authentification JWT (mode développement bypass avec token "123")
- Validation des données d'entrée

## Développement

### Ajouter de nouveaux endpoints

1. Créer le modèle dans `models/`
2. Créer les routes dans `routes/`
3. Ajouter les routes dans `server.js`

### Structure des modèles

Chaque modèle doit implémenter :

- `findAll()` - Récupérer tous les éléments
- `findById(id)` - Récupérer par ID
- `create(data)` - Créer un nouvel élément
- `update(id, data)` - Mettre à jour un élément

## Production

Pour déployer en production :

1. Modifier les variables d'environnement
2. Configurer une vraie base de données MySQL
3. Utiliser un serveur web (nginx) comme proxy
4. Configurer SSL/HTTPS
5. Mettre en place la sauvegarde de la base de données
