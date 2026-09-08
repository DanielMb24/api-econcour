# Comptes candidats et configuration administrative

Avant de déployer la nouvelle version, créer les deux index du compte candidat :

```powershell
node backend/scripts/create-candidate-account-indexes.js
```

Ce script ajoute les index uniques de `username` et `accountPhone`, sans modifier les anciens profils. Les index automatiques sont désactivés en production. Ne pas ouvrir les nouvelles inscriptions avant leur création.

La configuration SMTP existante est utilisée pour les codes email (expiration 10 minutes, cinq essais). Un profil existant est récupéré par son adresse email vérifiée ; son NIPCAN, sa photo, ses provinces et ses candidatures sont conservés. Le même formulaire permet la récupération du compte et révoque les anciennes sessions. Les nouveaux mots de passe sont hachés avec bcrypt. Les sessions candidat durent 24 heures.

Les nouvelles associations de matières portent sur le couple concours–filière. Les anciennes associations globales sont conservées et ne sont pas copiées implicitement à tous les concours. Configurez les épreuves de chaque concours dans « Filières et matières ».

Les statistiques utilisent les candidatures enregistrées. Le taux présenté correspond aux dossiers validés parmi les dossiers décidés, et non à un taux de réussite aux examens. Les répartitions comptent les candidatures ; le total candidats déduplique les personnes.

L’IA reçoit les indications administratives propres à chaque pièce. Une confiance inférieure à 90 % exige un contrôle humain. L’appel Gemini et l’envoi SMTP doivent être vérifiés dans l’environnement configuré ; les tests locaux utilisent des réponses simulées.

## Première candidature

La première candidature publique crée le compte avec un nom d’utilisateur dérivé du NIPCAN et un mot de passe temporaire aléatoire de 20 caractères. Seul le hash bcrypt est conservé en base. Les identifiants sont retournés une seule fois avec la réponse de création (Cache-Control: no-store), affichés sur la confirmation et inclus dans l’email. Les candidats existants doivent se connecter ; aucune nouvelle candidature ne réinitialise leur mot de passe. Le changement de mot de passe est disponible dans Paramètres et exige le mot de passe actuel.

## Mail

Configurer MAIL_HOST, MAIL_PORT, MAIL_USERNAME, MAIL_PASSWORD, MAIL_FROM_NAME et MAIL_FROM_ADDRESS dans l’environnement de l’API. MAIL_FORCE_IPV4=true utilise une résolution IPv4 ; MAIL_CONNECTION_TIMEOUT définit le délai de connexion. Le port 465 active toujours TLS implicite. Les fichiers .env locaux ne sont pas publiés par Git : ces paramètres doivent également être fournis à l’hébergement.
