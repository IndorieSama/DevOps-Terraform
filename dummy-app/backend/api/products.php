<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include database configuration
include_once __DIR__ . '/../config/database.php';

$database = new Database();
$db = $database->getConnection();

// If database connection fails, return error
if(!$db){
    http_response_code(503);
    echo json_encode(["message" => "Unable to connect to the database."]);
    exit();
}

$request_method = $_SERVER["REQUEST_METHOD"];

switch($request_method) {
    case 'GET':
        // Get products
        get_products($db);
        break;
    default:
        // Invalid request method
        header("HTTP/1.0 405 Method Not Allowed");
        break;
}

function get_products($db) {
    $query = "SELECT id, name, description, price, created_at FROM products ORDER BY created_at DESC";
    
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $num = $stmt->rowCount();

    if($num > 0) {
        $products_arr = array();
        $products_arr["records"] = array();

        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)){
            extract($row);
            $product_item = array(
                "id" => $id,
                "name" => $name,
                "description" => $description,
                "price" => $price,
                "created_at" => $created_at
            );
            array_push($products_arr["records"], $product_item);
        }

        http_response_code(200);
        echo json_encode($products_arr);
    } else {
        http_response_code(200);
        echo json_encode(array("records" => []));
    }
}
