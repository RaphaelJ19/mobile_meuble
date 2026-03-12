<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Connexion à la base de données
$host = 'localhost';
$user = 'root';
$password = '';
$database = 'holidaze';

try {
    $conn = new mysqli($host, $user, $password, $database);
    
    if ($conn->connect_error) {
        throw new Exception('Erreur de connexion: ' . $conn->connect_error);
    }
    
    $conn->set_charset('utf8mb4');
    
    // Paramètres optionnels
    $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
    $limit = 10;
    $offset = ($page - 1) * $limit;
    
    // Paramètres de filtre
    $prix_min = isset($_GET['prix_min']) ? (int)$_GET['prix_min'] : 0;
    $prix_max = isset($_GET['prix_max']) ? (int)$_GET['prix_max'] : 10000;
    $nb_couchage_min = isset($_GET['nb_couchage']) ? (int)$_GET['nb_couchage'] : 0;
    $animaux = isset($_GET['animaux']) ? $_GET['animaux'] : null;
    $prestations = isset($_GET['prestations']) ? explode(',', $_GET['prestations']) : [];
    
    // Construire la requête SQL avec filtres
    $where_conditions = ['b.valide = 1'];
    $where_conditions[] = '150 >= ' . $prix_min . ' AND 150 <= ' . $prix_max;
    
    if ($nb_couchage_min > 0) {
        $where_conditions[] = 'b.nb_couchage >= ' . $nb_couchage_min;
    }
    
    if ($animaux !== null && $animaux !== '') {
        $animaux_escaped = $conn->real_escape_string($animaux);
        $where_conditions[] = "b.animaux_bien LIKE '%" . $animaux_escaped . "%'";
    }
    
    $where_clause = 'WHERE ' . implode(' AND ', $where_conditions);
    
    // Si des prestations sont sélectionnées, ajouter un JOIN et GROUP BY
    $join_clause = '';
    $group_clause = '';
    $having_clause = '';
    if (!empty($prestations)) {
        $prestations_ids = array_map('intval', $prestations);
        $prestations_str = implode(',', $prestations_ids);
        $join_clause = "
            INNER JOIN secompose sc ON b.id_bien = sc.id_bien
            INNER JOIN prestation p ON sc.id_prestation = p.id_prestation
        ";
        $where_clause .= " AND p.id_prestation IN ($prestations_str)";
        $group_clause = "GROUP BY b.id_bien";
        $having_clause = "HAVING COUNT(DISTINCT p.id_prestation) = " . count($prestations_ids);
    }
    
    // Récupérer les biens avec informations des communes et notes moyennes
    $sql = "
        SELECT 
            b.id_bien,
            b.nom_bien,
            b.rue_bien,
            b.description_bien,
            b.superficie_bien,
            b.animaux_bien,
            b.nb_couchage,
            b.latitude_bien,
            b.longitude_bien,
            c.nom_commune,
            c.id_commune,
            COALESCE(ROUND(AVG(a.note), 1), 0) as note_moyenne,
            COUNT(DISTINCT a.id_avis) as nb_avis,
            150 as prix_nuit
        FROM bien b
        LEFT JOIN commune c ON b.id_commune = c.id_commune
        LEFT JOIN avis a ON b.id_bien = a.id_bien AND a.valide = 1
        $join_clause
        $where_clause
        $group_clause
        $having_clause
        ORDER BY b.nom_bien ASC
        LIMIT ? OFFSET ?
    ";
    
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception('Erreur de préparation: ' . $conn->error);
    }
    
    $stmt->bind_param("ii", $limit, $offset);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $biens = [];
    while ($row = $result->fetch_assoc()) {
        // Vérifier que le bien est valide (id_bien > 0)
        if ((int)$row['id_bien'] > 0) {
            // Générer une URL d'image placeholder unique basée sur l'ID du bien
            $imageId = 400 + (int)$row['id_bien'];  // Pour avoir des images différentes
            $photoUrl = 'https://picsum.photos/800/600?random=' . $imageId;
            
            $biens[] = [
                'id_bien' => (int)$row['id_bien'],
                'nom_bien' => $row['nom_bien'],
                'rue_bien' => $row['rue_bien'],
                'description_bien' => $row['description_bien'],
                'superficie_bien' => $row['superficie_bien'],
                'animaux_bien' => $row['animaux_bien'],
                'nb_couchage' => $row['nb_couchage'],
                'ville' => $row['nom_commune'] ?? 'Non spécifiée',
                'id_commune' => (int)$row['id_commune'],
                'latitude' => (float)$row['latitude_bien'],
                'longitude' => (float)$row['longitude_bien'],
                'prix_nuit' => (int)$row['prix_nuit'],
                'note_moyenne' => (float)$row['note_moyenne'],
                'nb_avis' => (int)$row['nb_avis'],
                'photo_url' => $photoUrl
            ];
        }
    }
    
    // Récupérer le total de biens (avec les mêmes filtres)
    $totalSql = "
        SELECT COUNT(DISTINCT b.id_bien) as total 
        FROM bien b
        $join_clause
        $where_clause
    ";
    $totalResult = $conn->query($totalSql);
    $totalRow = $totalResult->fetch_assoc();
    $total = (int)$totalRow['total'];
    
    $stmt->close();
    $conn->close();
    
    echo json_encode([
        'success' => true,
        'data' => $biens,
        'page' => $page,
        'total' => $total,
        'per_page' => $limit,
        'pages' => ceil($total / $limit)
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
