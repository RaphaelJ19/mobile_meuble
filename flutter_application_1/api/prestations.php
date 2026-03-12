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
    
    // Vérifier la connexion
    if ($conn->connect_error) {
        throw new Exception('Erreur de connexion: ' . $conn->connect_error);
    }
    
    $conn->set_charset('utf8mb4');
    
    // Récupérer toutes les prestations
    $sql = "SELECT id_prestation, libelle_prestation FROM prestation ORDER BY libelle_prestation ASC";
    $result = $conn->query($sql);
    
    if (!$result) {
        throw new Exception('Erreur de requête: ' . $conn->error);
    }
    
    $prestations = [];
    while ($row = $result->fetch_assoc()) {
        $prestations[] = [
            'id' => (int)$row['id_prestation'],
            'nom' => $row['libelle_prestation'],
            'icon' => getIconForPrestation($row['libelle_prestation'])
        ];
    }
    
    $conn->close();
    
    // Retourner la réponse JSON
    echo json_encode([
        'success' => true,
        'data' => $prestations,
        'count' => count($prestations)
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

/**
 * Associer une icône à chaque prestation
 * @param string $nomPrestation Le nom de la prestation
 * @return string Le nom de l'icône
 */
function getIconForPrestation($nomPrestation) {
    $icons = [
        'WIFI' => 'wifi',
        'Parking' => 'directions_car',
        'Cuisine' => 'restaurant',
        'Télévision' => 'tv',
        'Chambre' => 'hotel'
    ];
    
    return $icons[$nomPrestation] ?? 'check_circle';
}
?>
