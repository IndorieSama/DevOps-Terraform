<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");

$response = [
    'message' => 'Hello from the PHP backend!',
    'date' => date('Y-m-d H:i:s'),
    'hostname' => gethostname()
];

echo json_encode($response);
?>
