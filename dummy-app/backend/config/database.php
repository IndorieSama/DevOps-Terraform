<?php
class Database {
    private $host;
    private $db_name;
    private $username;
    private $password;
    public $conn;

    public function __construct() {
        $this->host = getenv('MYSQL_HOST');
        $this->db_name = getenv('MYSQL_DATABASE');
        $this->username = getenv('MYSQL_USERNAME');
        $this->password = getenv('MYSQL_PASSWORD');
    }

    public function getConnection() {
        $this->conn = null;

        $ssl_ca = __DIR__ . '/BaltimoreCyberTrustRoot.crt.pem';
        $ssl_options = [];
        if (file_exists($ssl_ca)) {
            $ssl_options = [
                PDO::MYSQL_ATTR_SSL_CA => $ssl_ca,
                PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => false, // Important for Azure
            ];
        }

        try {
            $dsn = "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8mb4";
            $this->conn = new PDO($dsn, $this->username, $this->password, $ssl_options);
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch(PDOException $exception) {
            // Log error details for debugging
            error_log("Database connection failed: " . $exception->getMessage());
            error_log("Host: " . $this->host);
            error_log("Database: " . $this->db_name);
            error_log("Username: " . $this->username);
            
            // Return null to indicate connection failure
            $this->conn = null;
        }
        return $this->conn;
    }
}
?>
