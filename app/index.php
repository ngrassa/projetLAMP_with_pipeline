<?php

$host = "db";
$user = "rsi21user";
$password = "rsi21pass";
$db = "rsi21db";

$conn = new mysqli($host, $user, $password, $db);

if ($conn->connect_error) {
    die("Connexion échouée : " . $conn->connect_error);
}

$sql = "SELECT * FROM articles";
$result = $conn->query($sql);

echo "<h1>Liste des Articles</h1>";

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        echo "<h3>".$row["titre"]."</h3>";
        echo "<p>".$row["contenu"]."</p>";
        echo "<hr>";
    }
} else {
    echo "Aucun titre trouvé";
}

$conn->close();

?>
