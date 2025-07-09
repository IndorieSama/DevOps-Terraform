<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight OPTIONS request first
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only process POST requests
if ($_SERVER['REQUEST_METHOD'] != 'POST') {
    http_response_code(405);
    echo json_encode(['message' => 'Method Not Allowed']);
    exit();
}

include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->name) && !empty($data->description) && !empty($data->price)) {
    $query = "INSERT INTO products (name, description, price, created_at) VALUES(:name, :description, :price, NOW())";
    
    $stmt = $db->prepare($query);

    // sanitize
    $name=htmlspecialchars(strip_tags($data->name));
    $description=htmlspecialchars(strip_tags($data->description));
    $price=htmlspecialchars(strip_tags($data->price));

    $stmt->bindParam(":name", $name);
    $stmt->bindParam(":description", $description);
    $stmt->bindParam(":price", $price);

    if($stmt->execute()){
        http_response_code(201);
        echo json_encode(array("message" => "Product was created."));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to create product."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to create product. Data is incomplete."));
}
?>
