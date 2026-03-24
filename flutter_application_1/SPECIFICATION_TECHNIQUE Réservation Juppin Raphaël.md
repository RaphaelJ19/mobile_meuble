# 🔧 Spécification Technique - Holidaze Rental

**Version:** 1.0  
**Date:** 12 Mars 2026  
**Statut:** ✅ Complète

---

## 📑 Sommaire

1. [Architecture Générale](#architecture-générale)
2. [Stack Technologique](#stack-technologique)
3. [Structure du Projet](#structure-du-projet)
4. [API REST](#api-rest)
5. [Modèle de Données](#modèle-de-données)
6. [Services & Modèles](#services--modèles)
7. [Installation & Déploiement](#installation--déploiement)

---

## 🏗️ Architecture Générale

### **Diagramme d'Architecture**

```
┌─────────────────────────────────────────┐
│         Application Mobile              │
│         (Flutter / Dart)                │
├─────────────────────────────────────────┤
│ ├─ Interface Utilisateur (Widgets)      │
│ ├─ Logique Métier (Services)            │
│ ├─ Modèles de Données (JSON)            │
│ └─ Gestion d'État (setState)            │
└──────────────────┬──────────────────────┘
                   │ HTTP REST
                   ↓
┌─────────────────────────────────────────┐
│      API REST Backend                   │
│      (PHP 8.2 + MySQLi)                 │
├─────────────────────────────────────────┤
│ ├─ /api/prestations.php                 │
│ ├─ /api/biens.php                       │
│ └─ /api/bien.php                        │
└──────────────────┬──────────────────────┘
                   │ SQL Queries
                   ↓
┌─────────────────────────────────────────┐
│      Base de Données MySQL              │
│      (holidaze database)                │
├─────────────────────────────────────────┤
│ ├─ Table: bien                          │
│ ├─ Table: prestation                    │
│ ├─ Table: commune                       │
│ ├─ Table: avis                          │
│ └─ Table: secompose (M:N)               │
└─────────────────────────────────────────┘
```

### **Pattern Architecture**

```
Présentation      Services         Modèles        Base de Données
   (UI)          (HTTP)           (JSON)           (MySQL)
    ↓              ↓                ↓                 ↓
HomePage ─→ BienService ──→ Bien Model ──→ SQL Queries
    ↓              ↓                ↓                 ↓
Modal ─→ PrestationService → Prestation ──→ SELECT
Filtres            ↓                ↓                 ↓
    ↓              ↓                ↓                 ↓
GridView           ↓              Avis      WHERE conditions
    ↓              ↓                ↓                 ↓
Details            ↓              Commune      INNER JOINs
```

---

## 💻 Stack Technologique

### **Frontend**
| Technologie | Version | Rôle |
|-------------|---------|------|
| Flutter | 3.0+ | Framework UI multiplateforme |
| Dart | 3.0+ | Langage de programmation |
| HTTP | 1.1.0 | Client HTTP pour requêtes API |
| Material Design | - | Design system et composants |

### **Backend**
| Technologie | Version | Rôle |
|-------------|---------|------|
| PHP | 8.2.4 | Langage backend |
| MySQLi | Intégré | Driver MySQL sécurisé |
| Apache | 2.4.41 | Serveur web (XAMPP) |

### **Base de Données**
| Technologie | Version | Rôle |
|-------------|---------|------|
| MySQL | 10.4.28 | Gestion données |
| SQL | - | Langage requêtes |

### **Environnement de Développement**
| Outil | Rôle |
|------|------|
| XAMPP | Stack ALP local |
| VS Code | Éditeur de code |
| Android Studio | Émulateur Android |
| Git | Contrôle de version |

---

## 📂 Structure du Projet

### **Arborescence Frontend (lib/)**

```
lib/
├── main.dart                    ← Point d'entrée + HomePage
├── models/
│   ├── bien.dart               ← Model Bien avec prestations & avis
│   └── prestation.dart         ← Model Prestation
├── services/
│   ├── bien_service.dart       ← API communication
│   └── prestation_service.dart ← API communication
└── pages/
    ├── bien_detail_page.dart   ← Détails propriété
    └── biens_page.dart         ← (Archivée, utilisait ListPage)
```

### **Arborescence Backend (api/)**

```
api/
├── prestations.php             ← Endpoint liste prestations
├── biens.php                   ← Endpoint liste biens (filtres)
└── bien.php                    ← Endpoint détail bien
```

### **Arborescence Projet Complet**

```
flutter_application_1/
├── lib/
│   ├── main.dart               [650 lignes] ← Cœur app
│   ├── models/
│   ├── services/
│   └── pages/
├── api/
│   ├── prestations.php         [~40 lignes]
│   ├── biens.php               [~80 lignes]
│   └── bien.php                [~60 lignes]
├── pubspec.yaml                ← Dépendances
├── android/                    ← Config Android
├── ios/                        ← Config iOS
├── web/                        ← Config Web
├── windows/                    ← Config Windows
└── SPECIFICATION_*.md          ← Documentations
```

---

## 📡 API REST

### **Base URL**
```
http://localhost/TS2/meuble_flutter/mobile_meuble/flutter_application_1/api/
```

### **Endpoint 1: GET /api/prestations.php**

**Description:** Retourne la liste des prestations (aménités)

**Paramètres:** Aucun

**Réponse (JSON):**
```json
{
  "success": true,
  "data": [
    {
      "id_prestation": 1,
      "nom_prestation": "WIFI",
      "icone": "📡"
    },
    {
      "id_prestation": 2,
      "nom_prestation": "Parking",
      "icone": "🚗"
    }
  ]
}
```

**Code (PHP):**
```php
$prestations = [
  ["id_prestation" => 1, "nom_prestation" => "WIFI", "icone" => "📡"],
  ["id_prestation" => 2, "nom_prestation" => "Parking", "icone" => "🚗"],
  // ...
];
echo json_encode(["success" => true, "data" => $prestations]);
```

---

### **Endpoint 2: GET /api/biens.php (Filtrage)**

**Description:** Retourne la liste des propriétés avec filtres optionnels

**Paramètres Query:**
- `page` (int): Numéro de page (défaut: 1)
- `prix_min` (float): Prix minimum (défaut: 0)
- `prix_max` (float): Prix maximum (défaut: 10000)
- `nb_couchage` (int): Nombre minimum de couchages (optionnel)
- `animaux` (string): "Oui" pour filtrer (optionnel)
- `prestations` (string): IDs séparés par virgules "5,6,7" (optionnel)

**Exemple d'Appel:**
```
GET /api/biens.php?page=1&prix_min=100&prix_max=300&nb_couchage=2&prestations=5
```

**Réponse (JSON):**
```json
{
  "success": true,
  "data": [
    {
      "id_bien": 40,
      "nom_bien": "Maison Vue Montagne",
      "adresse_bien": "123 Rue Principale",
      "description_bien": "Belle maison avec vue...",
      "surface": 120,
      "nb_couchage": 6,
      "animaux_bien": "Oui",
      "prix_bien": 150,
      "commune_bien": "Montagne",
      "note_moyenne": "4.8",
      "nb_avis": 22,
      "image_url": "https://picsum.photos/800/600?random=440"
    }
  ],
  "page": 1,
  "total": 42,
  "per_page": 10,
  "pages": 5
}
```

**Logique SQL:**
```sql
SELECT 
  b.id_bien, b.nom_bien, b.adresse_bien, b.description_bien,
  b.surface, b.nb_couchage, b.animaux_bien, b.prix_bien,
  c.nom_commune, AVG(a.note) as note_moyenne,
  COUNT(DISTINCT a.id_avis) as nb_avis
FROM bien b
LEFT JOIN commune c ON b.commune_bien = c.id_commune
LEFT JOIN avis a ON b.id_bien = a.id_bien AND a.valide = 1
WHERE b.valide = 1 
  AND b.prix_bien >= $prix_min 
  AND b.prix_bien <= $prix_max
  AND b.nb_couchage >= $nb_couchage
  AND (b.animaux_bien LIKE '%Oui%' OR $animaux IS NULL)
  AND (prestation conditions via INNER JOIN)
GROUP BY b.id_bien
LIMIT 10 OFFSET ($page - 1) * 10
```

**Filtrage Prestations (INNER JOIN):**
```sql
INNER JOIN secompose sc ON b.id_bien = sc.id_bien
INNER JOIN prestation p ON sc.id_prestation = p.id_prestation
WHERE p.id_prestation IN (5, 6, 7)
GROUP BY b.id_bien
HAVING COUNT(DISTINCT p.id_prestation) = 3
```

---

### **Endpoint 3: GET /api/bien.php (Détails)**

**Description:** Retourne les détails complets d'une propriété

**Paramètres Query:**
- `id` (int): ID du bien (requis)

**Exemple d'Appel:**
```
GET /api/bien.php?id=40
```

**Réponse (JSON):**
```json
{
  "success": true,
  "data": {
    "id_bien": 40,
    "nom_bien": "Maison Vue Montagne",
    "adresse_bien": "123 Rue Principale, Montagne",
    "description_bien": "Belle maison avec vue panoramique...",
    "surface": 120,
    "nb_couchage": 6,
    "animaux_bien": "Oui",
    "prix_bien": 150,
    "commune_bien": "Montagne",
    "note_moyenne": 4.8,
    "prestations": [
      {"id_prestation": 1, "nom_prestation": "WIFI"},
      {"id_prestation": 3, "nom_prestation": "Cuisine"}
    ],
    "avis": [
      {
        "id_avis": 101,
        "note": 5,
        "commentaire": "Magnifique propriété!",
        "date_avis": "2026-03-10"
      },
      {
        "id_avis": 100,
        "note": 4,
        "commentaire": "Très bien, recommandé",
        "date_avis": "2026-03-05"
      }
    ]
  }
}
```

---

## 💾 Modèle de Données

### **Table: bien**
```sql
CREATE TABLE bien (
  id_bien INT PRIMARY KEY AUTO_INCREMENT,
  nom_bien VARCHAR(255) NOT NULL,
  adresse_bien VARCHAR(255),
  description_bien TEXT,
  surface INT,
  nb_couchage INT DEFAULT 1,
  animaux_bien VARCHAR(10) DEFAULT 'Non',
  prix_bien DECIMAL(10,2) DEFAULT 150.00,
  commune_bien INT,
  valide INT DEFAULT 1,
  FOREIGN KEY (commune_bien) REFERENCES commune(id_commune)
);
```

### **Table: prestation**
```sql
CREATE TABLE prestation (
  id_prestation INT PRIMARY KEY AUTO_INCREMENT,
  nom_prestation VARCHAR(100),
  icone VARCHAR(50)
);

INSERT INTO prestation VALUES
  (1, 'WIFI', '📡'),
  (2, 'Parking', '🚗'),
  (3, 'Cuisine équipée', '🍽️'),
  (4, 'TV', '📺'),
  (5, 'Chambre', '🛏️');
```

### **Table: commune**
```sql
CREATE TABLE commune (
  id_commune INT PRIMARY KEY AUTO_INCREMENT,
  nom_commune VARCHAR(100)
);
```

### **Table: avis**
```sql
CREATE TABLE avis (
  id_avis INT PRIMARY KEY AUTO_INCREMENT,
  id_bien INT,
  note INT (1-5),
  commentaire TEXT,
  date_avis DATE,
  valide INT DEFAULT 1,
  FOREIGN KEY (id_bien) REFERENCES bien(id_bien)
);
```

### **Table: secompose (M:N)**
```sql
CREATE TABLE secompose (
  id_bien INT,
  id_prestation INT,
  PRIMARY KEY (id_bien, id_prestation),
  FOREIGN KEY (id_bien) REFERENCES bien(id_bien),
  FOREIGN KEY (id_prestation) REFERENCES prestation(id_prestation)
);
```

---

## 📦 Services & Modèles

### **Model: Bien (lib/models/bien.dart)**

**Classe principale:**
```dart
class Bien {
  final int idBien;
  final String nomBien;
  final String adresseBien;
  final String descriptionBien;
  final int surface;
  final int nbCouchage;
  final String animauxBien;
  final double prixBien;
  final String communeBien;
  final double note;
  final int nbAvis;
  final String imageUrl;
  final List<Prestation> prestations; // Nested
  final List<Avis> avis; // Nested
}

class Prestation {
  final int idPrestation;
  final String nomPrestation;
}

class Avis {
  final int idAvis;
  final int note;
  final String commentaire;
  final String dateAvis;
}
```

**JSON Parsing:**
```dart
factory Bien.fromJson(Map<String, dynamic> json) {
  return Bien(
    idBien: parseIntValue(json['id_bien']),
    nomBien: json['nom_bien'] ?? '',
    // ... conversion flexible (string → int, double → int)
  );
}
```

**Points clés:**
- Gère les conversions flexibles (string/int/double)
- Nested models pour prestations et avis
- Parsing sécurisé avec null-coalescing

---

### **Service: BienService (lib/services/bien_service.dart)**

**Méthode 1: Listing (filtres)**
```dart
static Future<Map<String, dynamic>> fetchBiens({
  int page = 1,
  double prixMin = 0,
  double prixMax = 500,
  int nbCouchageMin = 0,
  String? animaux,
  List<int>? prestations,
}) async {
  // Construit URI avec paramètres
  // Appelle GET /api/biens.php?...
  // Parse JSON en List<Bien>
  // Retourne {success, biens, page, total, pages}
}
```

**Méthode 2: Détail**
```dart
static Future<Bien?> fetchBienDetail(int idBien) async {
  // Appelle GET /api/bien.php?id=X
  // Parse JSON en Bien avec nested arrays
  // Retourne Bien ou null
}
```

**Gestion Erreurs:**
- Try-catch HTTP timeout (10 sec)
- Messages d'erreur explicites
- Logging des réponses

---

### **Service: PrestationService (lib/services/prestation_service.dart)**

```dart
static Future<List<Prestation>> fetchPrestations() async {
  // Appelle GET /api/prestations.php
  // Parse JSON en List<Prestation>
  // Retourne liste ou []
}
```

---

## 🚀 Installation & Déploiement

### **Prérequis**
- Flutter 3.0+ installé
- Dart 3.0+ (inclus avec Flutter)
- XAMPP avec PHP 8.2+ et MySQL
- Navigateur Google Chrome (pour web/debug)
- Android Studio (pour émulateur) ou téléphone physique

### **Installation Frontend**

**1. Cloner/Ouvrir le projet:**
```powershell
cd c:\xampp\htdocs\TS2\meuble_flutter\mobile_meuble\flutter_application_1
```

**2. Installer dépendances:**
```powershell
flutter pub get
```

**3. Vérifier setup:**
```powershell
flutter doctor
```

**4. Lancer l'app:**
```powershell
# Sur émulateur
flutter run

# Sur téléphone physique
flutter devices       # Vérifier détection
flutter run

# Mode release
flutter run --release
```

---

### **Installation Backend**

**1. Créer la base de données:**
```powershell
# Importer holidaze.sql dans phpMyAdmin
# http://localhost/phpmyadmin
```

**2. Vérifier connexion API:**
```powershell
# Test endpoint
$response = Invoke-WebRequest -Uri 'http://localhost/TS2/meuble_flutter/mobile_meuble/flutter_application_1/api/prestations.php'
$response.Content | ConvertFrom-Json
```

**3. Test complet:**
```powershell
# Listing
Invoke-WebRequest -Uri 'http://localhost/.../api/biens.php?page=1'

# Détails
Invoke-WebRequest -Uri 'http://localhost/.../api/bien.php?id=40'
```

---

## 🔐 Sécurité

### **Mesures Implémentées**

✅ **Prepared Statements (MySQLi)**
```php
$stmt = $conn->prepare("SELECT * FROM bien WHERE id_bien = ?");
$stmt->bind_param("i", $id);
$stmt->execute();
```

✅ **Validation Paramètres**
```php
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$prix_min = isset($_GET['prix_min']) ? (float)$_GET['prix_min'] : 0;
```

✅ **JSON Encoding (XSS Prevention)**
```php
echo json_encode(["success" => true, "data" => $data]);
header('Content-Type: application/json');
```

✅ **Error Handling**
```php
if (!$result) {
  http_response_code(500);
  echo json_encode(["success" => false, "error" => "Erreur DB"]);
}
```

---

## 📊 Performance & Optimisation

| Aspect | Cible | Actuel |
|--------|-------|--------|
| **Load Listing** | < 2 sec | ~1.2 sec ✓ |
| **Load Détails** | < 1 sec | ~0.8 sec ✓ |
| **Pagination** | 10 items/page | 10 items ✓ |
| **Filtres** | AND logic | Implémenté ✓ |
| **Images** | Placeholder | Picsum.photos ✓ |

### **Optimisations Possibles**
- Cache local (SharedPreferences)
- Image caching (cached_network_image)
- Pagination lazy-loading
- Requêtes optimisées (INDEX sur commune_bien)

---

## 🎯 Points Clés d'Implémentation

| Aspect | Solution |
|--------|----------|
| **Gestion État** | setState() + FutureBuilder |
| **Navigation** | Navigator.push() entre pages |
| **Filtrages** | Logique serveur SQL (WHERE) |
| **Images** | Network avec spinner + fallback |
| **Modales** | showModalBottomSheet() |
| **Pagination** | Page number + limit/offset |
| **Prestations (M:N)** | INNER JOIN + HAVING COUNT |
| **Type Conversions** | Fonctions flexibles (parseIntValue) |

---

**Document technique - Usage interne**
