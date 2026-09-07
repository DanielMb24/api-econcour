# Analyse documentaire avec Gemini

Dans `.env` (ou les variables du serveur de production), configurer :

```dotenv
GEMINI_API_KEY=votre-cle
GEMINI_DOCUMENT_MODEL=gemini-3.6-flash
```

Sur Vercel, ajouter ces variables au projet API puis redeployer. Le chat administrateur et le controle documentaire utilisent Gemini. Aucun secret Gemini ne doit etre configure dans le projet frontend. La cle reste exclusivement sur le serveur, sans prefixe `VITE_`. Sans cle, les analyses sont marquees `disabled`.

Le service transmet les images et PDF a Gemini et attend une recommandation JSON. Le traitement existant applique la recommandation et envoie les notifications. Une reponse bloquee, incomplete ou invalide marque l'analyse `failed` sans valider le document.

Reference API : https://ai.google.dev/api/generate-content
