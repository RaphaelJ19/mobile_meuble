<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

$host = 'localhost';
$user = 'root';
$password = '';
$database = 'holidaze';

try {
    if (!isset($_GET['id']) || empty($_GET['id'])) {
        throw new Exception('ID du bien requis');
    }
    
    $id_bien = (int)$_GET['id'];
    
    $conn = new mysqli($host, $user, $password, $database);
    
    if ($conn->connect_error) {
        throw new Exception('Erreur de connexion: ' . $conn->connect_error);
    }
    
    $conn->set_charset('utf8mb4');
    
    // Récupérer les détails du bien
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
        WHERE b.id_bien = ?
        GROUP BY b.id_bien
    ";
    
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception('Erreur de préparation: ' . $conn->error);
    }
    
    $stmt->bind_param("i", $id_bien);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception('Bien non trouvé');
    }
    
    $row = $result->fetch_assoc();
    
    // Récupérer les prestations du bien
    $prestSql = "
        SELECT p.id_prestation, p.libelle_prestation
        FROM secompose sc
        JOIN prestation p ON sc.id_prestation = p.id_prestation
        WHERE sc.id_bien = ?
    ";
    
    $prestStmt = $conn->prepare($prestSql);
    $prestStmt->bind_param("i", $id_bien);
    $prestStmt->execute();
    $prestResult = $prestStmt->get_result();
    
    $prestations = [];
    while ($pRow = $prestResult->fetch_assoc()) {
        $prestations[] = [
            'id' => (int)$pRow['id_prestation'],
            'nom' => $pRow['libelle_prestation']
        ];
    }
    
    // Récupérer les avis validés
    $avisSql = "
        SELECT 
            a.id_avis,
            a.note,
            a.commentaire,
            a.date_avis
        FROM avis a
        WHERE a.id_bien = ? AND a.valide = 1
        ORDER BY a.date_avis DESC
        LIMIT 10
    ";
    
    $avisStmt = $conn->prepare($avisSql);
    $avisStmt->bind_param("i", $id_bien);
    $avisStmt->execute();
    $avisResult = $avisStmt->get_result();
    
    $avis = [];
    while ($aRow = $avisResult->fetch_assoc()) {
        $avis[] = [
            'id' => (int)$aRow['id_avis'],
            'note' => (int)$aRow['note'],
            'commentaire' => $aRow['commentaire'],
            'date' => $aRow['date_avis']
        ];
    }
    
    $stmt->close();
    $prestStmt->close();
    $avisStmt->close();
    $conn->close();
    
    // Générer une URL d'image placeholder unique
    $imageId = 400 + $id_bien;
    $photoUrl = 'https://picsum.photos/800/600?random=' . $imageId;
    
    echo json_encode([
        'success' => true,
        'data' => [
            'id_bien' => (int)$row['id_bien'],
            'nom_bien' => $row['nom_bien'],
            'rue_bien' => $row['rue_bien'],
            'description_bien' => $row['description_bien'],
            'superficie_bien' => $row['superficie_bien'],
            'animaux_bien' => $row['animaux_bien'],
            'nb_couchage' => $row['nb_couchage'],
            'ville' => $row['nom_commune'] ?? 'Non spécifiée',
            'latitude' => (float)$row['latitude_bien'],
            'longitude' => (float)$row['longitude_bien'],
            'prix_nuit' => (int)$row['prix_nuit'],
            'note_moyenne' => (float)$row['note_moyenne'],
            'nb_avis' => (int)$row['nb_avis'],
            'photo_url' => $photoUrl,
            'prestations' => $prestations,
            'avis' => $avis
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
