# 🔧 Spécification Technique - Module Réservation

**Version:** 1.0  
**Date:** 12 Mars 2026  
**Statut:** ✅ Complète

---

## 📑 Sommaire

1. [Architecture du Module](#architecture-du-module)
2. [Flux Fonctionnel](#flux-fonctionnel)
3. [API REST](#api-rest)
4. [Modèle de Données](#modèle-de-données)
5. [Services Flutter](#services-flutter)
6. [Interface Utilisateur](#interface-utilisateur)
7. [Sécurité & Validation](#sécurité--validation)

---

## 🏗️ Architecture du Module

### **Diagramme d'Architecture**

```
┌─────────────────────────────────────────┐
│         Application Mobile              │
│         (Flutter / Dart)                │
├─────────────────────────────────────────┤
│ ├─ BienDetailPage (bouton réserver)     │
│ ├─ _ReservationSheet (bottom sheet)     │
│ ├─ _ReservationSheetState (logique)     │
│ └─ BienService (HTTP calls)             │
└──────────────────┬──────────────────────┘
                   │ HTTP REST
                   ↓
┌─────────────────────────────────────────┐
│      API REST Backend                   │
│      (PHP 8.2 + MySQLi)                 │
├─────────────────────────────────────────┤
│ ├─ /api/verifier_disponibilite.php      │
│ └─ /api/reserver.php                    │
└──────────────────┬──────────────────────┘
                   │ SQL Queries
                   ↓
┌─────────────────────────────────────────┐
│      Base de Données MySQL              │
│      (holidaze database)                │
├─────────────────────────────────────────┤
│ ├─ Table: reservation                   │
│ ├─ Table: locataire                     │
│ └─ Table: tarif                         │
└─────────────────────────────────────────┘
```

### **Pattern Architecture**

```
Présentation        Services          API PHP          Base de Données
   (UI)            (HTTP)            (Backend)           (MySQL)
    ↓                 ↓                  ↓                   ↓
BienDetailPage → BienService → verifier_disponibilite → SELECT reservation
    ↓                 ↓                  ↓                   ↓
_ReservationSheet     ↓          reserver.php  ──────→ INSERT reservation
    ↓                 ↓                  ↓                   ↓
_confirmer()  → creerReservation → Vérif chevauchement → Contraintes FK
```

---

## 🔄 Flux Fonctionnel

### **Étapes du Processus de Réservation**

```
1. Utilisateur clique "Réserver maintenant"
         ↓
2. Ouverture du Bottom Sheet (_ReservationSheet)
         ↓
3. Sélection date d'arrivée (showDatePicker)
         ↓
4. Sélection date de départ (showDatePicker)
         ↓
5. Affichage récapitulatif automatique
   (nuits × prix = total)
         ↓
6. Clic "Confirmer la réservation"
         ↓
7. Appel GET verifier_disponibilite.php
         ↓
   ┌─────┴─────┐
   ↓           ↓
Occupé      Libre
   ↓           ↓
Erreur      Appel POST reserver.php
rouge            ↓
(dates       INSERT en BDD
conflit)         ↓
             Fermeture sheet
                 ↓
             Snackbar vert ✅
```

### **Gestion des Cas d'Erreur**

| Cas | Comportement |
|-----|-------------|
| Dates non sélectionnées | Snackbar orange |
| Période occupée | Snackbar rouge + dates du conflit + reset dates |
| Erreur réseau | Snackbar rouge avec message technique |
| Erreur BDD (FK, etc.) | Snackbar rouge avec message serveur |

---

## 📡 API REST

### **Base URL**
```
http://localhost/TS2/meuble_flutter/mobile_meuble/flutter_application_1/api/
```

---

### **Endpoint 1 : GET /api/verifier_disponibilite.php**

**Description :** Vérifie si une période est disponible pour un bien donné via détection de chevauchement SQL.

**Paramètres Query :**
- `id_bien` (int) : ID du bien (requis)
- `date_debut` (string) : Date d'arrivée format `YYYY-MM-DD` (requis)
- `date_fin` (string) : Date de départ format `YYYY-MM-DD` (requis)

**Exemple d'Appel :**
```
GET /api/verifier_disponibilite.php?id_bien=40&date_debut=2026-04-01&date_fin=2026-04-05
```

**Réponse — Période libre :**
```json
{
  "success": true,
  "disponible": true,
  "conflit": null
}
```

**Réponse — Période occupée :**
```json
{
  "success": true,
  "disponible": false,
  "conflit": {
    "date_debut": "2026-03-19",
    "date_fin": "2026-03-21"
  }
}
```

**Logique SQL (détection chevauchement) :**
```sql
SELECT id_reservations, date_debut, date_fin
FROM reservation
WHERE id_bien = ?
  AND date_debut < ?   -- date_fin demandée
  AND date_fin   > ?   -- date_debut demandée
LIMIT 1
```

> La condition `A.debut < B.fin AND A.fin > B.debut` couvre tous les cas de chevauchement d'intervalles.

---

### **Endpoint 2 : POST /api/reserver.php**

**Description :** Insère une nouvelle réservation en base de données après double vérification de disponibilité côté serveur.

**Méthode :** `POST`  
**Content-Type :** `application/json`

**Body JSON :**
```json
{
  "id_bien": 40,
  "date_debut": "2026-04-01",
  "date_fin": "2026-04-05",
  "id_locataire": 19,
  "id_tarif": 29
}
```

**Paramètres :**
| Champ | Type | Requis | Défaut | Description |
|-------|------|--------|--------|-------------|
| `id_bien` | int | ✅ | — | ID du bien à réserver |
| `date_debut` | string | ✅ | — | Date d'arrivée `YYYY-MM-DD` |
| `date_fin` | string | ✅ | — | Date de départ `YYYY-MM-DD` |
| `id_locataire` | int | ❌ | 19 | ID du locataire |
| `id_tarif` | int | ❌ | 29 | ID du tarif appliqué |

**Réponse — Succès :**
```json
{
  "success": true,
  "id_reservation": 5
}
```

**Réponse — Période non disponible :**
```json
{
  "success": false,
  "error": "Période non disponible"
}
```

**Réponse — Paramètres manquants :**
```json
{
  "success": false,
  "error": "Paramètres manquants"
}
```

**Logique PHP :**
```php
// 1. Vérification chevauchement (sécurité serveur)
$check = $conn->prepare("
    SELECT id_reservations FROM reservation
    WHERE id_bien = ? AND date_debut < ? AND date_fin > ?
    LIMIT 1
");
$check->bind_param("iss", $id_bien, $date_fin, $date_debut);
$check->execute();
$check->store_result();
if ($check->num_rows > 0) { /* retourner erreur */ }

// 2. Insertion
$stmt = $conn->prepare("
    INSERT INTO reservation (date_debut, date_fin, id_locataire, id_bien, id_tarif)
    VALUES (?, ?, ?, ?, ?)
");
$stmt->bind_param("ssiii", $date_debut, $date_fin, $id_locataire, $id_bien, $id_tarif);
$stmt->execute();
```

**Gestion CORS (preflight OPTIONS) :**
```php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}
```

---

## 💾 Modèle de Données

### **Table: reservation**
```sql
CREATE TABLE reservation (
  id_reservations INT PRIMARY KEY AUTO_INCREMENT,
  date_debut      DATE NOT NULL,
  date_fin        DATE NOT NULL,
  id_locataire    INT NOT NULL,
  id_bien         INT NOT NULL,
  id_tarif        INT NOT NULL,
  FOREIGN KEY (id_locataire) REFERENCES locataire(id_locataire),
  FOREIGN KEY (id_bien)      REFERENCES bien(id_bien),
  FOREIGN KEY (id_tarif)     REFERENCES tarif(id_tarif)
);
```

### **Table: locataire**
```sql
CREATE TABLE locataire (
  id_locataire INT PRIMARY KEY AUTO_INCREMENT,
  -- ... autres colonnes
);
-- Données actuelles : id_locataire = 19
```

### **Table: tarif**
```sql
CREATE TABLE tarif (
  id_tarif INT PRIMARY KEY AUTO_INCREMENT,
  -- ... autres colonnes
);
-- Données actuelles : id_tarif = 29
```

### **Exemple de Réservation en BDD**
```sql
-- Réservation existante (test)
SELECT * FROM reservation WHERE id_bien = 40;
-- id_reservations | date_debut | date_fin   | id_locataire | id_bien | id_tarif
-- 1               | 2026-03-19 | 2026-03-21 | 19           | 40      | 29
```

---

## 📦 Services Flutter

### **BienService — Méthode verifierDisponibilite**

```dart
static Future<Map<String, dynamic>> verifierDisponibilite({
  required int idBien,
  required DateTime dateDebut,
  required DateTime dateFin,
}) async {
  String fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final uri = Uri.parse('$_baseUrl/verifier_disponibilite.php').replace(
    queryParameters: {
      'id_bien':    idBien.toString(),
      'date_debut': fmt(dateDebut),
      'date_fin':   fmt(dateFin),
    },
  );

  final response = await http.get(uri).timeout(const Duration(seconds: 15));
  return jsonDecode(response.body) as Map<String, dynamic>;
}
```

### **BienService — Méthode creerReservation**

```dart
static Future<Map<String, dynamic>> creerReservation({
  required int idBien,
  required DateTime dateDebut,
  required DateTime dateFin,
  int idLocataire = 19,
  int idTarif = 29,
}) async {
  String fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final response = await http.post(
    Uri.parse('$_baseUrl/reserver.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'id_bien':      idBien,
      'date_debut':   fmt(dateDebut),
      'date_fin':     fmt(dateFin),
      'id_locataire': idLocataire,
      'id_tarif':     idTarif,
    }),
  ).timeout(const Duration(seconds: 15));

  return jsonDecode(response.body) as Map<String, dynamic>;
}
```

---

## 🖥️ Interface Utilisateur

### **Composants UI**

| Widget | Rôle |
|--------|------|
| `_ReservationSheet` | StatefulWidget — bottom sheet principal |
| `_ReservationSheetState` | Logique d'état (dates, verifying) |
| `_DateTile` | Tuile cliquable pour sélection de date |
| `_RecapRow` | Ligne du récapitulatif (label / valeur) |
| `showDatePicker` | Sélecteur de date natif Flutter (locale FR) |

### **État du Widget (_ReservationSheetState)**

```dart
DateTime? _dateDebut;   // Date d'arrivée sélectionnée
DateTime? _dateFin;     // Date de départ sélectionnée
bool _verifying;        // true pendant les appels API (désactive le bouton)
```

### **Méthode _confirmer() — Séquence async**

```
1. Vérifier que _dateDebut et _dateFin sont non null
         ↓
2. Capturer AVANT tout await :
   - dateDebut, dateFin, nbNuits
   - messenger = ScaffoldMessenger.of(context)
   - navigator = Navigator.of(context)
         ↓
3. setState(() => _verifying = true)
         ↓
4. await verifierDisponibilite(...)
         ↓
5. Si occupé → setState reset dates + snackbar rouge
         ↓
6. await creerReservation(...)
         ↓
7. navigator.pop() + snackbar vert
```

> **Pattern important :** Les références `messenger` et `navigator` sont capturées AVANT le premier `await` pour éviter les erreurs `use_build_context_synchronously` après destruction du widget.

### **Récapitulatif Automatique**

```dart
int get _nbNuits {
  if (_dateDebut == null || _dateFin == null) return 0;
  return _dateFin!.difference(_dateDebut!).inDays;
}
// Affiché uniquement si _nbNuits > 0
// Total = _nbNuits * bien.prixNuit
```

### **Aperçu du Bottom Sheet**

```
┌─────────────────────────────┐
│ Réserver              [✕]   │
│ Nom du bien                 │
│                             │
│ Date d'arrivée              │
│ [📅 01/04/2026          ]   │
│                             │
│ Date de départ              │
│ [📅 05/04/2026          ]   │
│                             │
│ ┌─────────────────────────┐ │
│ │ Durée          4 nuits  │ │
│ │ 150€ × 4 nuits  600€   │ │
│ │ ─────────────────────── │ │
│ │ Total           600€   │ │
│ └─────────────────────────┘ │
│                             │
│ [  Confirmer la réservation ] │
└─────────────────────────────┘
```

---

## 🔐 Sécurité & Validation

### **Double Vérification de Disponibilité**

La disponibilité est vérifiée **deux fois** pour éviter les race conditions :

| Étape | Où | Quand |
|-------|----|-------|
| 1ère vérification | Flutter → `verifier_disponibilite.php` | Au clic "Confirmer" |
| 2ème vérification | `reserver.php` (côté serveur) | Avant l'INSERT |

### **Mesures Implémentées**

✅ **Prepared Statements (MySQLi)**
```php
$stmt = $conn->prepare("INSERT INTO reservation ... VALUES (?, ?, ?, ?, ?)");
$stmt->bind_param("ssiii", $date_debut, $date_fin, $id_locataire, $id_bien, $id_tarif);
```

✅ **Validation Paramètres PHP**
```php
$id_bien = isset($data['id_bien']) ? (int)$data['id_bien'] : 0;
if (!$id_bien || !$date_debut || !$date_fin) {
    throw new Exception('Paramètres manquants');
}
```

✅ **Validation Format Date**
```php
if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date_debut)) {
    throw new Exception('Format de date invalide');
}
```

✅ **Contraintes Flutter côté client**
```dart
// date_fin ne peut pas être avant ou égale à date_debut
if (_dateFin != null && !_dateFin!.isAfter(picked)) _dateFin = null;

// firstDate du picker de départ = date_debut + 1 jour
final first = _dateDebut?.add(const Duration(days: 1));
```

✅ **Gestion async sécurisée**
```dart
if (!mounted) return; // Vérification après chaque await
```

---

## 📊 Performance

| Aspect | Valeur |
|--------|--------|
| Timeout vérification dispo | 15 sec |
| Timeout création réservation | 15 sec |
| Requêtes SQL par réservation | 2 (SELECT + INSERT) |
| Affichage spinner pendant appel | ✅ `_verifying` |

---

## 🗂️ Fichiers du Module

### **Backend (api/)**

```
api/
├── verifier_disponibilite.php   ← GET  — Vérifie chevauchement
└── reserver.php                 ← POST — Insère la réservation
```

### **Frontend (lib/)**

```
lib/
├── services/
│   └── bien_service.dart        ← verifierDisponibilite() + creerReservation()
└── pages/
    └── bien_detail_page.dart    ← _ReservationSheet + _ReservationSheetState
```

---

**Document technique - Usage interne**
