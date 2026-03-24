<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$host = 'localhost';
$user = 'root';
$password = '';
$database = 'holidaze';

try {
    if (!isset($_GET['id_bien']) || empty($_GET['id_bien'])) {
        throw new Exception('id_bien requis');
    }

    $id_bien = (int)$_GET['id_bien'];

    $conn = new mysqli($host, $user, $password, $database);
    if ($conn->connect_error) throw new Exception($conn->connect_error);
    $conn->set_charset('utf8mb4');

    // Récupérer toutes les réservations futures (ou en cours) pour ce bien
    $sql = "
        SELECT date_debut, date_fin
        FROM reservation
        WHERE id_bien = ?
          AND date_fin >= CURDATE()
        ORDER BY date_debut ASC
    ";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id_bien);
    $stmt->execute();
    $result = $stmt->get_result();

    $periodes = [];
    while ($row = $result->fetch_assoc()) {
        $periodes[] = [
            'date_debut' => $row['date_debut'],
            'date_fin'   => $row['date_fin'],
        ];
    }

    $stmt->close();
    $conn->close();

    echo json_encode(['success' => true, 'periodes' => $periodes]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
