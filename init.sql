CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO products (name, description, price) VALUES ('Ordinateur Portable', 'Portable haute performance pour le travail et les loisirs', 1250.00);
INSERT INTO products (name, description, price) VALUES ('Clavier Mécanique', 'Clavier mécanique RGB avec switches Cherry MX', 180.50);
INSERT INTO products (name, description, price) VALUES ('Souris Gamer', 'Souris gaming haute précision avec capteur optique', 75.00);
