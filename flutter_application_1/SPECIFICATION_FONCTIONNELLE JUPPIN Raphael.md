# 📋 Spécification Fonctionnelle - Holidaze Rental

**Version:** 2.0 - Allégée  
**Date:** 12 Mars 2026  
**Statut:** ✅ Validée

---

## 📑 Sommaire

1. [Présentation](#présentation)
2. [Fonctionnalités](#fonctionnalités)
3. [Flux Utilisateur](#flux-utilisateur)
4. [Exigences Clés](#exigences-clés)
5. [Critères d'Acceptation](#critères-dacceptation)

---

## 🎯 Présentation

**Holidaze** est une app mobile Flutter de recherche de propriétés meublées à court terme (vacances, séjours).

L'application permet aux utilisateurs de:
- 🏠 Parcourir une liste de propriétés disponibles
- 🔍 Filtrer selon leurs critères (prix, équipements, capacité, animaux)
- 📍 Consulter les détails complets d'une propriété
- ⭐ Voir les avis et notes d'autres utilisateurs

**Fonctionnalités MVP (Minimum Viable Product):**
- ✅ **Listing** - Affichage paginé des propriétés disponibles (10 par page)
- ✅ **Filtres avancés** - Prix, chambres, lits, animaux, prestations (équipements)
- ✅ **Détails** - Page complète d'une propriété avec images, description, specs
- ✅ **Avis** - Notes moyennes et retours des clients précédents

---

## 🚀 Fonctionnalités

### **1️⃣ Listing des Propriétés**
Affichage en grille (2 colonnes) de 10 propriétés par page avec les infos essentielles:
- **Image** - Photo principale de la propriété
- **Nom** - Titre du bien (ex: "Appartement Centre-Ville")
- **Lieu** - Ville/commune où se trouve la propriété
- **Prix** - Tarif nuit (actuellement 150€ pour tous les biens - à mettre à jour depuis base)
- **Note moyenne** - Moyenne des avis (ex: 4.5/5)
- **Nombre d'avis** - Combien de clients ont laissé un avis

**Pagination:**
- Boutons "Précédent" et "Suivant" en bas de la liste
- Affiche le numéro de page actuelle (ex: "Page 2/5")
- Clic sur une carte → Ouvre la page de détails de la propriété

**Exemple:** L'utilisateur voit 10 biens, clique "Suivant" → voit les 10 biens suivants

### **2️⃣ Système de Filtres**
Modal (volet) qui s'ouvre au clic du bouton "🔍 FILTRES". Tous les filtres fonctionnent ensemble (logique **ET** - TOUS les critères doivent être respectés).

**Prix:** 
- Curseur horizontal de plage (Range Slider)
- Sélectionner entre 0€ et 500€
- Exemple: Sélectionner 150€-300€ affiche que les biens dans cette fourchette

**Chambres / Lits:**
- Compteurs avec boutons - et + pour ajuster le nombre
- "Chambres" = nombre minimum de chambres désirées
- "Lits" = nombre minimum de couchages (lits) désiré
- La requête cherche les biens qui ont **AU MOINS** ce nombre
- Exemple: Sélectionner 2 chambres affiche les biens avec 2, 3, 4... chambres

**Animaux:**
- Checkbox simple "Acceptent les animaux de compagnie"
- Coché = affiche que les propriétés qui acceptent les animaux
- Non coché = affiche toutes les propriétés (avec ou sans animaux)

**Prestations (Équipements):**
- Multi-sélection de filtres: WIFI, Parking, Cuisine, TV, Chambre
- Sélectionner plusieurs = cherche biens qui ont **TOUS** les équipements cochés
- Exemple: Cocher "WIFI" ET "Parking" → affiche propriétés avec WIFI **ET** Parking (strict)
- Utilise INNER JOIN SQL pour match exact

**Bouton "Appliquer":**
- Ferme le modal et recharge la liste avec les filtres appliqués
- **La page retourne à 1** (réinitialisation pagination)
- Les filtres restent actifs jusqu'à modification

### **3️⃣ Détails Propriété**
Page complète d'une propriété accessible en cliquant sur une carte du listing.

**Sections affichées:**
1. **Image principale** - Avec spinner de chargement pendant le téléchargement
2. **Informations clés** - Nom, lieu, note moyenne avec avis_count
3. **Description** - Texte long du bien (pliant/dépliable pour épargner l'espace)
4. **Caractéristiques** - Superficie, chambres, lits, animaux acceptés
5. **Prestations** - Liste des équipements disponibles (WIFI, Parking, etc.)
6. **Avis clients** - Maximum 10 derniers avis (trié par date descendante) avec:
   - Note donnée (1-5 étoiles)
   - Commentaire du client
   - Date

**Navigation:**
- Bouton "← Retour" en haut → Retourne au listing
- **Les filtres et la position de page sont conservés** (UX)
- Si l'utilisateur a appliqué des filtres, ils restent actifs

**Exemple d'avis:** "Magnifique lieu! Propriétaire très sympa. ⭐⭐⭐⭐⭐"

### **4️⃣ Navigation**
Flux d'navigation dans l'application:
```
HomePage ←→ Modal Filtres
   ↓
BienDetailPage → Back → HomePage
```

---

## 📋 Flux Utilisateur

### **Scénario Standard - Recherche Simple**
Imagine un client qui cherche un appartement pour ses vacances:

1. **Lancement** - Utilisateur ouvre l'app Holidaze
   - Voit immédiatement la page d'accueil avec 10 propriétés
   - Page 1/5 affichée

2. **Ouverture des filtres** - Clique sur bouton "🔍 FILTRES"
   - Modal s'ouvre avec tous les paramètres
   - Valeurs par défaut: Prix 0-500€, Chambres 0, Lits 0, Aucune préstation sélectionnée

3. **Application des filtres** - L'utilisateur ajuste:
   - **Prix:** Déplace curseur pour sélectionner 100€-300€
   - **Prestations:** Clique sur "WIFI" qui devient surligné/coché
   - Ignore le reste des filtres (tous les biens acceptent les animaux pour ce cas)

4. **Soumission** - Clique bouton "Appliquer" dans le modal
   - Modal ferme automatiquement
   - Listing recharge avec les nouveaux filtres (WHERE prix ENTRE 100-300 ET prestations CONTIENT WIFI)
   - Page retourne à 1

5. **Consultation du listing filtré** - Voit maintenant 5 biens à la place de 10
   - Affiche uniquement les propriétés entre 100-300€ avec WIFI
   - Les cartes affichent nom, image, lieu, prix, avis

6. **Consultation des détails** - Clique sur un des biens
   - Ouvre page détail individuelle
   - Page charge l'image, description complète, avis clients (max 10)
   - Sections pliables pour épargner de l'espace

7. **Retour** - Clique bouton "← Retour" en haut
   - Retourne au listing
   - **Filtres sont conservés** (toujours Prix 100-300€ + WIFI)
   - **Position de page conservée** - Si c'était page 2, retourne page 2

### **Cas Limites - Aucun Résultat**
Scénario: L'utilisateur applique des filtres trop restrictifs (ex: Prix 50€-60€ + Prestations "Chambre")
- Listing affiche **"Aucun bien trouvé avec ces critères"**
- Bouton "Réinitialiser filtres" disponible pour recommencer

### **Cas Limite - Erreur API**
Scénario: MySQL ne répond pas ou l'API plantée
- Message d'erreur affiché: **"Erreur lors du chargement des propriétés. Rechargez la page."**
- Permet à l'utilisateur de comprendre ce qui s'est passé

### **Cas Limite - Image Non Disponible**
Scénario: URL de l'image est cassée ou inaccessible
- Affiche **icône par défaut** (placeholder) à la place
- Propriété reste visible et consultable
- Spinner de chargement visible le temps du chargement

---

## 🔧 Exigences Clés

### **Performance et Délais**
- **Listing initial** - Doit charger < 2 secondes (10 biens + images)
- **Détails propriété** - Doit charger < 1 seconde (1 bien + avis)
- **Réponse API** - Chaque requête PHP doit répondre < 500ms
- **Temps du filtre** - L'app doit réagir au clic "Appliquer" en < 2 secondes

**Pourquoi:** Les utilisateurs s'impatientent après 3 secondes. Une app lente = mauvaise expérience = utilisateurs qui partent.

### **Compatibilité Multi-Plateforme**
- **Android** - Version 9 et supérieure (Flutter 3.0+)
- **iOS** - Version 12 et supérieure (Flutter 3.0+)
- **Web** - Interface responsive (responsive design - s'adapte à tous les écrans)
- **Résolution** - Fonctionne sur écrans 480px (téléphones vieux) jusqu'à 1440px (tablettes)

**Pourquoi:** Le public cible utilise divers appareils. Doit fonctionner partout.

### **Sécurité des Données**
- **Prepared Statements** - Toutes les requêtes MySQLi doivent utiliser `$stmt->bind_param()` (protège contre les injections SQL)
- **Validation serveur** - L'API doit valider TOUS les paramètres reçus (ex: verifier que `prix_min` est un nombre)
- **Prévention XSS** - Aucun utilisateur input ne doit être affiché sans échappement HTML
- **CORS approprié** - En production, remplacer `Access-Control-Allow-Origin: *` par domaine spécifique

**Pourquoi:** Les hackeurs cherchent des vulnérabilités. Les données clients doivent être protégées.

### **Accessibilité Utilisateur**
- Textes lisibles (taille minimum 14px)
- Contraste suffisant pour daltoniens et malvoyants
- Boutons suffisamment grands (minimum 48x48dp)





---

## ✅ Critères d'Acceptation

Voici comment tester que chaque fonctionnalité fonctionne correctement:

| # | Fonctionnalité | Critère de Test | Résultat Attendu |
|---|---------|----------|----------|
| 1 | **Listing initial** | Ouvrir l'app | Affiche 10 biens en grille 2 colonnes |
| 2 | **Pagination suivant** | Cliquer "Suivant" | Affiche les 10 biens suivants, numéro page augmente |
| 3 | **Pagination précédent** | Sur page 2, cliquer "Précédent" | Retourne page 1 |
| 4 | **Filtre Prix (bas)** | Sélectionner Prix 0€-100€, cliquer Appliquer | Liste affiche que biens <= 100€ |
| 5 | **Filtre Prix (haut)** | Sélectionner Prix 200€-500€, cliquer Appliquer | Liste affiche que biens >= 200€ |
| 6 | **Filtre Prestations (strict)** | Sélectionner WIFI ET Parking, appliquer | Affiche UNIQUEMENT biens avec WIFI **ET** Parking (pas WIFI seul) |
| 7 | **Filtre Chambres** | Sélectionner Chambres >= 3, appliquer | Affiche que biens avec 3+ chambres |
| 8 | **Filtre Lits** | Sélectionner Lits >= 6, appliquer | Affiche que biens avec 6+ couchages |
| 9 | **Filtre Animaux** | Cocher "Acceptent les animaux", appliquer | Affiche que propriétés acceptant animaux |
| 10 | **Combinaison filtres** | Prix 100-300€ + WIFI + Animaux Oui | Toutes les conditions appliquées ensemble (logique ET) |
| 11 | **Détails propriété** | Cliquer sur une carte du listing | Ouvre page détail individuelle avec toutes infos |
| 12 | **Image + spinner** | Consulter une propriété | Affiche spinner pendant chargement, puis image |
| 13 | **Avis affichés** | Consulter détails propriété | Affiche max 10 avis avec note, texte, date |
| 14 | **Aucun résultat** | Appliquer filtres très restrictifs | Affiche message "Aucun bien trouvé avec ces critères" |
| 15 | **Filtre conservé** | Appliquer filtres, consulter détail, retour | Filtres toujours actifs, page numéro conservée |
| 16 | **Erreur API** | Éteindre MySQL, essayer recherche | Affiche message d'erreur utilisateur lisible |

**Comment valider:** Pour chaque ligne, exécuter le test et vérifier que le "Résultat Attendu" est obtenu. ✅ = PASS / ❌ = FAIL

Par exemple, pour le test 6:
1. Ouvrir Filtres
2. Sélectionner WIFI (coché ✓)
3. Sélectionner Parking (coché ✓)
4. Cliquer Appliquer
5. ✅ **PASS si:** Listing montre que propriétés avec WIFI ET Parking
6. ❌ **FAIL si:** Listing montre propriétés avec seulement WIFI ou seulement Parking

---

## 🚀 Backlog Futur (Futures Phases de Développement)

Ces fonctionnalités ne sont **PAS** dans le MVP actuel. Elles seront ajoutées dans les phases suivantes:

### **Phase 1 - Authentification Utilisateur** (Priorité 🔴 Haute)
Permettre aux utilisateurs de se créer un compte et se connecter.
- Création de compte (email + mot de passe)
- Connexion avec JWT token
- Profil utilisateur personnel
- Deconnexion
**Impact:** Nécessaire pour réservations futures

### **Phase 2 - Système de Réservation** (Priorité 🔴 Haute)
Permettre aux utilisateurs de réserver une propriété.
- Sélectionner dates d'arrivée/départ
- Paiement (Stripe ou PayPal)
- Confirmation réservation (email)
- Historique réservations
**Impact:** Monétisation de l'app

### **Phase 3 - Soumission d'Avis** (Priorité 🟡 Moyenne)
Permettre aux locataires de laisser des avis après leur séjour.
- Écrire un avis (texte + note 1-5⭐)
- Upload photos de leur expérience
- Modération des avis
**Impact:** Améliore confiance des futurs clients

### **Phase 4 - Tableau de Bord Propriétaire** (Priorité 🟡 Moyenne)
Interface pour les propriétaires pour gérer leurs biens.
- Ajouter/modifier propriété
- Gérer réservations
- Consulter revenus
- Répondre aux avis
**Impact:** Permet aux propriétaires d'utiliser l'app - génère du contenu

### **Phase 5 - Recherche Avancée + Tri** (Priorité 🟢 Basse)
Améliorations du système de filtres.
- Recherche par texte (nom lieu, description)
- Tri (prix croissant/décroissant, note, récent)
- Sauvegarde recherches favorites
**Impact:** Meilleure UX de recherche

### **Phase 6 - Favoris / Liste de Souhaits** (Priorité 🟢 Basse)
Permettre aux utilisateurs de sauvegarder leurs propriétés préférées.
- Bouton "♥ Ajouter aux favoris"
- Liste "Mes favoris" avec filtres
- Partager liste avec amis
**Impact:** Encourage les utilisateurs à revenir

### **Phase 7 - Intégration Carte** (Priorité 🟢 Basse)
Afficher les propriétés sur une carte interactive.
- Google Maps intégré
- Épingles pour chaque propriété
- Géolocalisation utilisateur
- Rayon de recherche sur carte
**Impact:** Aide les utilisateurs à visualiser les emplacements

### **Phase 8 - Recommandations ML** (Priorité 🟢 Basse)
Système de recommandations intelligentes.
- Analyse l'historique de l'utilisateur
- Suggère des propriétés similaires
- Recommande basé sur tendances populaires
**Impact:** Fidélisation utilisateurs, augmente réservations
