<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$host     = 'localhost';
$user     = 'root';
$password = '';
$database = 'holidaze';

try {
    $data = json_decode(file_get_contents('php://input'), true);

    $id_bien      = isset($data['id_bien'])      ? (int)$data['id_bien']      : 0;
    $date_debut   = isset($data['date_debut'])   ? $data['date_debut']        : '';
    $date_fin     = isset($data['date_fin'])     ? $data['date_fin']          : '';
    $id_locataire = isset($data['id_locataire']) ? (int)$data['id_locataire'] : 19;
    $id_tarif     = isset($data['id_tarif'])     ? (int)$data['id_tarif']     : 29;

    if (!$id_bien || !$date_debut || !$date_fin) {
        throw new Exception('Paramètres manquants');
    }

    $conn = new mysqli($host, $user, $password, $database);
    if ($conn->connect_error) throw new Exception($conn->connect_error);
    $conn->set_charset('utf8mb4');

    // Double vérification chevauchement
    $check = $conn->prepare("
        SELECT id_reservations FROM reservation
        WHERE id_bien = ? AND date_debut < ? AND date_fin > ?
        LIMIT 1
    ");
    $check->bind_param("iss", $id_bien, $date_fin, $date_debut);
    $check->execute();
    $check->store_result();
    if ($check->num_rows > 0) {
        $check->close();
        $conn->close();
        echo json_encode(['success' => false, 'error' => 'Période non disponible']);
        exit;
    }
    $check->close();

    $stmt = $conn->prepare("
        INSERT INTO reservation (date_debut, date_fin, id_locataire, id_bien, id_tarif)
        VALUES (?, ?, ?, ?, ?)
    ");
    $stmt->bind_param("ssiii", $date_debut, $date_fin, $id_locataire, $id_bien, $id_tarif);
    $stmt->execute();
    $id_reservation = (int)$conn->insert_id;
    $stmt->close();
    $conn->close();

    echo json_encode(['success' => true, 'id_reservation' => $id_reservation]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
