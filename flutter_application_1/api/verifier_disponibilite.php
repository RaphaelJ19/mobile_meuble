<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$host = 'localhost';
$user = 'root';
$password = '';
$database = 'holidaze';

try {
    $id_bien    = isset($_GET['id_bien'])    ? (int)$_GET['id_bien']       : 0;
    $date_debut = isset($_GET['date_debut']) ? $_GET['date_debut']          : '';
    $date_fin   = isset($_GET['date_fin'])   ? $_GET['date_fin']            : '';

    if (!$id_bien || !$date_debut || !$date_fin) {
        throw new Exception('Paramètres manquants : id_bien, date_debut, date_fin requis');
    }

    // Validation format date
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date_debut) ||
        !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date_fin)) {
        throw new Exception('Format de date invalide (attendu : YYYY-MM-DD)');
    }

    if ($date_debut >= $date_fin) {
        throw new Exception('La date de fin doit être après la date de début');
    }

    $conn = new mysqli($host, $user, $password, $database);
    if ($conn->connect_error) throw new Exception($conn->connect_error);
    $conn->set_charset('utf8mb4');

    // Chercher toute réservation qui chevauche la période demandée
    // Chevauchement : debut_existant < date_fin_demandée ET fin_existant > date_debut_demandée
    $sql = "
        SELECT id_reservations, date_debut, date_fin
        FROM reservation
        WHERE id_bien = ?
          AND date_debut < ?
          AND date_fin   > ?
        LIMIT 1
    ";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("iss", $id_bien, $date_fin, $date_debut);
    $stmt->execute();
    $result = $stmt->get_result();

    $disponible = $result->num_rows === 0;
    $conflit    = null;

    if (!$disponible) {
        $row     = $result->fetch_assoc();
        $conflit = [
            'date_debut' => $row['date_debut'],
            'date_fin'   => $row['date_fin'],
        ];
    }

    $stmt->close();
    $conn->close();

    echo json_encode([
        'success'    => true,
        'disponible' => $disponible,
        'conflit'    => $conflit,
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
