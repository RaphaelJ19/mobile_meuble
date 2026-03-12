<?php
// Script pour générer les images des propriétés

$uploadDir = __DIR__ . '/uploads/';

// Créer le dossier s'il n'existe pas
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

// Récupérer les IDs des biens depuis la BD
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
    
    // Récupérer tous les biens
    $sql = "SELECT id_bien, nom_bien FROM bien WHERE valide = 1";
    $result = $conn->query($sql);
    
    if (!$result) {
        throw new Exception('Erreur de requête: ' . $conn->error);
    }
    
    $generatedCount = 0;
    $colors = [
        [52, 152, 219],   // Bleu
        [46, 204, 113],   // Vert
        [155, 89, 182],   // Purple
        [230, 126, 34],   // Orange
        [214, 69, 65],    // Red
        [52, 73, 94],     // Dark blue
    ];
    
    while ($row = $result->fetch_assoc()) {
        $idBien = $row['id_bien'];
        $nomBien = substr($row['nom_bien'], 0, 20);  // Limiter la longueur
        $imagePath = $uploadDir . 'bien_' . $idBien . '.jpg';
        
        // Ne pas regénérer si l'image existe déjà
        if (file_exists($imagePath)) {
            continue;
        }
        
        // Créer une image placeholder
        $width = 800;
        $height = 600;
        
        $image = imagecreatetruecolor($width, $height);
        
        // Couleur aléatoire basée sur l'ID
        $colorIndex = $idBien % count($colors);
        $color = $colors[$colorIndex];
        $bgColor = imagecolorallocate($image, $color[0], $color[1], $color[2]);
        
        // Remplir le fond
        imagefilledrectangle($image, 0, 0, $width, $height, $bgColor);
        
        // Couleur du texte
        $textColor = imagecolorallocate($image, 255, 255, 255);
        
        // Ajouter un texte simple
        $textY = $height / 2 - 30;
        imagestring($image, 5, 50, $textY - 40, 'Propriete #' . $idBien, $textColor);
        imagestring($image, 3, 50, $textY + 20, $nomBien, $textColor);
        
        // Ajouter un pattern simple (rectangles)
        for ($i = 0; $i < 5; $i++) {
            $patternColor = imagecolorallocate($image, 
                max(0, $color[0] - 30 + rand(-20, 20)), 
                max(0, $color[1] - 30 + rand(-20, 20)), 
                max(0, $color[2] - 30 + rand(-20, 20))
            );
            $x1 = rand(0, $width / 2);
            $y1 = rand(0, $height / 2);
            imagefilledrectangle($image, $x1, $y1, $x1 + 100, $y1 + 100, $patternColor);
        }
        
        // Sauvegarder l'image
        if (imagejpeg($image, $imagePath, 85)) {
            $generatedCount++;
            echo "✓ Image générée: bien_" . $idBien . ".jpg\n";
        } else {
            echo "✗ Erreur lors de la sauvegarde: bien_" . $idBien . ".jpg\n";
        }
        
        imagedestroy($image);
    }
    
    $conn->close();
    
    echo "\n✓ Total images générées: $generatedCount\n";
    
} catch (Exception $e) {
    echo "Erreur: " . $e->getMessage() . "\n";
}
?>

