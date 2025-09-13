-- ==============================
-- RATTRAPAGE SQL FOR BIG DATA
-- Modèle OLAP : Vente e-commerce
-- ==============================

-- 1️⃣ Création des tables dimension

CREATE TABLE DimProduct (
    product_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10,2)
);

CREATE TABLE DimCustomer (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(50),
    age_group VARCHAR(20)
);

CREATE TABLE DimTime (
    date_id INT PRIMARY KEY,
    day INT,
    month INT,
    quarter INT,
    year INT
);

-- 2️⃣ Création de la table de faits

CREATE TABLE FactSales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    customer_id INT,
    date_id INT,
    quantity INT,
    total_amount DECIMAL(10,2),
    FOREIGN KEY (product_id) REFERENCES DimProduct(product_id),
    FOREIGN KEY (customer_id) REFERENCES DimCustomer(customer_id),
    FOREIGN KEY (date_id) REFERENCES DimTime(date_id)
);

-- 3️⃣ Exemple d'insertion de données (optionnel, pour tests)
INSERT INTO DimProduct VALUES
(1, 'Laptop', 'Electronics', 1200.00),
(2, 'Headphones', 'Electronics', 150.00),
(3, 'Coffee Maker', 'Home Appliances', 80.00);

INSERT INTO DimCustomer VALUES
(1, 'Alice', 'USA', '25-34'),
(2, 'Bob', 'UK', '35-44');

INSERT INTO DimTime VALUES
(1, 1, 1, 1, 2025),
(2, 2, 1, 1, 2025);

INSERT INTO FactSales VALUES
(1, 1, 1, 1, 2, 2400.00),
(2, 2, 2, 2, 1, 150.00);

-- 4️⃣ Exemples de requêtes analytiques

-- 1️⃣ Total des ventes par catégorie de produit
SELECT p.category, SUM(f.total_amount) AS total_sales
FROM FactSales f
JOIN DimProduct p ON f.product_id = p.product_id
GROUP BY p.category;

-- 2️⃣ Ventes mensuelles par pays
SELECT t.month, c.country, SUM(f.total_amount) AS total_sales
FROM FactSales f
JOIN DimTime t ON f.date_id = t.date_id
JOIN DimCustomer c ON f.customer_id = c.customer_id
GROUP BY t.month, c.country;

-- 3️⃣ Top produits les plus vendus
SELECT p.name, SUM(f.quantity) AS total_quantity
FROM FactSales f
JOIN DimProduct p ON f.product_id = p.product_id
GROUP BY p.name
ORDER BY total_quantity DESC
LIMIT 10;

-- 4️⃣ Ventes par tranche d'âge des clients
SELECT c.age_group, SUM(f.total_amount) AS total_sales
FROM FactSales f
JOIN DimCustomer c ON f.customer_id = c.customer_id
GROUP BY c.age_group;

-- 5️⃣ Évolution trimestrielle des ventes
SELECT t.year, t.quarter, SUM(f.total_amount) AS total_sales
FROM FactSales f
JOIN DimTime t ON f.date_id = t.date_id
GROUP BY t.year, t.quarter
ORDER BY t.year, t.quarter;
