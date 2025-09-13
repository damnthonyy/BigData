# Modèle de Base de Données Big Data OLAP - E-commerce

## 📋 Description du Projet

Ce projet présente un modèle de base de données OLAP (Online Analytical Processing) conçu pour analyser des données volumineuses dans le contexte d'un e-commerce. Le modèle implémente l'architecture en étoile (star schema) optimisée pour les requêtes analytiques sur de gros volumes de données.

## 🎯 Objectifs de la Consigne

### 1. Proposer un modèle de base de données Big Data (type OLAP)
- ✅ **Modèle en étoile** : Architecture optimisée pour l'analyse
- ✅ **Tables de dimension** : Structure hiérarchique des données
- ✅ **Table de faits** : Stockage des métriques et mesures
- ✅ **Relations optimisées** : Clés étrangères pour les jointures efficaces

### 2. Expliquer le stockage de données volumineuses
- ✅ **Partitionnement** : Stratégies de division des données
- ✅ **Indexation** : Optimisation des performances
- ✅ **Compression** : Réduction de l'espace de stockage
- ✅ **Distribution** : Architecture distribuée

### 3. Expliquer l'interrogation de données volumineuses
- ✅ **Requêtes analytiques** : Exemples concrets d'analyse
- ✅ **Optimisation** : Techniques de performance
- ✅ **Agrégations** : Calculs sur gros volumes
- ✅ **Filtrage** : Sélection efficace des données

## 🏗️ Architecture du Modèle

### Structure en Étoile (Star Schema)

```
                    FactSales (Table de faits)
                         |
        ┌────────────────┼────────────────┐
        |                |                |
   DimProduct      DimCustomer      DimTime
  (Dimension)      (Dimension)    (Dimension)
```

### Tables de Dimension

#### 1. **DimProduct** - Dimension Produit
- `product_id` : Identifiant unique du produit
- `name` : Nom du produit
- `category` : Catégorie du produit
- `price` : Prix unitaire

#### 2. **DimCustomer** - Dimension Client
- `customer_id` : Identifiant unique du client
- `name` : Nom du client
- `country` : Pays de résidence
- `age_group` : Tranche d'âge

#### 3. **DimTime** - Dimension Temporelle
- `date_id` : Identifiant unique de la date
- `day` : Jour du mois
- `month` : Mois
- `quarter` : Trimestre
- `year` : Année

### Table de Faits

#### **FactSales** - Faits de Vente
- `sale_id` : Identifiant unique de la vente
- `product_id` : Référence vers DimProduct
- `customer_id` : Référence vers DimCustomer
- `date_id` : Référence vers DimTime
- `quantity` : Quantité vendue
- `total_amount` : Montant total de la vente

## 💾 Stockage de Données Volumineuses

### 1. **Partitionnement (Partitioning)**
```sql
-- Partitionnement par année pour la table FactSales
CREATE TABLE FactSales_2024 PARTITION OF FactSales
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE FactSales_2025 PARTITION OF FactSales
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

**Avantages :**
- Amélioration des performances de requête
- Maintenance facilitée (suppression d'anciennes données)
- Parallélisation des opérations

### 2. **Indexation Optimisée**
```sql
-- Index composite pour les requêtes fréquentes
CREATE INDEX idx_factsales_product_date ON FactSales(product_id, date_id);
CREATE INDEX idx_factsales_customer_date ON FactSales(customer_id, date_id);
CREATE INDEX idx_factsales_amount ON FactSales(total_amount);
```

**Types d'index :**
- **B-Tree** : Pour les requêtes d'égalité et de plage
- **Bitmap** : Pour les colonnes à faible cardinalité
- **Columnstore** : Pour les requêtes analytiques

### 3. **Compression des Données**
```sql
-- Compression des données historiques
ALTER TABLE FactSales SET (compression = 'zstd');
```

**Techniques de compression :**
- **Compression de colonnes** : Stockage par colonne
- **Dictionnaire** : Encodage des valeurs répétitives
- **Delta compression** : Stockage des différences

### 4. **Distribution et Réplication**
```sql
-- Distribution par clé de partition
DISTRIBUTE BY HASH(product_id);

-- Réplication des tables de dimension
REPLICATE DimProduct;
REPLICATE DimCustomer;
REPLICATE DimTime;
```

## 🔍 Interrogation de Données Volumineuses

### 1. **Requêtes Analytiques Optimisées**

#### Analyse des Ventes par Catégorie
```sql
SELECT p.category, 
       SUM(f.total_amount) AS total_sales,
       COUNT(*) AS nb_transactions,
       AVG(f.total_amount) AS avg_transaction
FROM FactSales f
JOIN DimProduct p ON f.product_id = p.product_id
WHERE f.date_id >= 20250101  -- Filtrage temporel
GROUP BY p.category
ORDER BY total_sales DESC;
```

#### Analyse Temporelle des Performances
```sql
SELECT t.year, t.quarter,
       SUM(f.total_amount) AS quarterly_sales,
       LAG(SUM(f.total_amount)) OVER (ORDER BY t.year, t.quarter) AS prev_quarter,
       (SUM(f.total_amount) - LAG(SUM(f.total_amount)) OVER (ORDER BY t.year, t.quarter)) 
       / LAG(SUM(f.total_amount)) OVER (ORDER BY t.year, t.quarter) * 100 AS growth_rate
FROM FactSales f
JOIN DimTime t ON f.date_id = t.date_id
GROUP BY t.year, t.quarter
ORDER BY t.year, t.quarter;
```

### 2. **Techniques d'Optimisation**

#### **Prédicats de Filtrage**
- Utiliser les index sur les colonnes de filtrage
- Appliquer les filtres le plus tôt possible
- Utiliser les partitions pour limiter le scan

#### **Agrégations Pré-calculées**
```sql
-- Table de pré-agrégation pour les performances
CREATE TABLE FactSales_Daily AS
SELECT date_id, product_id, customer_id,
       SUM(quantity) AS daily_quantity,
       SUM(total_amount) AS daily_amount,
       COUNT(*) AS daily_transactions
FROM FactSales
GROUP BY date_id, product_id, customer_id;
```

#### **Cache et Matérialisation**
```sql
-- Vue matérialisée pour les requêtes fréquentes
CREATE MATERIALIZED VIEW mv_monthly_sales AS
SELECT t.year, t.month, p.category, c.country,
       SUM(f.total_amount) AS monthly_sales
FROM FactSales f
JOIN DimTime t ON f.date_id = t.date_id
JOIN DimProduct p ON f.product_id = p.product_id
JOIN DimCustomer c ON f.customer_id = c.customer_id
GROUP BY t.year, t.month, p.category, c.country;
```

### 3. **Stratégies de Requêtes pour Big Data**

#### **Parallélisation**
- Distribution des calculs sur plusieurs nœuds
- Partitionnement des données pour le traitement parallèle
- Utilisation des ressources cluster

#### **Streaming et Traitement Temps Réel**
```sql
-- Requêtes sur flux de données
SELECT product_id, 
       SUM(total_amount) OVER (PARTITION BY product_id ORDER BY date_id ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_sales
FROM FactSales
WHERE date_id >= CURRENT_DATE - 7;
```

## 📊 Exemples d'Analyses Métier

### 1. **Analyse des Performances Commerciales**
- Ventes par catégorie de produit
- Évolution temporelle des ventes
- Top clients et produits
- Analyse géographique des ventes

### 2. **Analyse Comportementale**
- Segmentation des clients par âge
- Analyse des paniers moyens
- Détection des tendances saisonnières
- Prédiction des ventes

### 3. **Tableaux de Bord Exécutifs**
- KPIs en temps réel
- Alertes sur les seuils
- Rapports automatisés
- Visualisations interactives

## 🚀 Technologies Recommandées

### **Moteurs de Base de Données**
- **PostgreSQL** : Pour les données relationnelles
- **ClickHouse** : Pour l'analytique en temps réel
- **Apache Druid** : Pour les requêtes OLAP
- **BigQuery** : Solution cloud Google

### **Outils d'Analyse**
- **Apache Superset** : Tableaux de bord
- **Grafana** : Monitoring et alertes
- **Jupyter Notebooks** : Analyses exploratoires
- **Python/R** : Analyses statistiques avancées

## 📈 Métriques de Performance

### **Indicateurs Clés**
- **Temps de réponse** : < 2 secondes pour les requêtes simples
- **Débit** : > 1000 requêtes/seconde
- **Disponibilité** : 99.9% uptime
- **Scalabilité** : Support de millions d'enregistrements

### **Optimisations Continues**
- Monitoring des performances
- Analyse des plans d'exécution
- Ajustement des index
- Mise à jour des statistiques

## 🔧 Installation et Utilisation

### **Prérequis**
- Base de données PostgreSQL 12+
- 8GB RAM minimum
- 100GB espace disque

### **Déploiement**
```bash
# Exécution du script de création
psql -d bigdata_olap -f model_olap.sql

# Création des index de performance
psql -d bigdata_olap -f create_indexes.sql

# Insertion des données de test
psql -d bigdata_olap -f sample_data.sql
```

## 📚 Ressources Supplémentaires

- [Documentation PostgreSQL OLAP](https://www.postgresql.org/docs/current/table-partitioning.html)
- [Best Practices Big Data](https://cloud.google.com/architecture/big-data-architecture)
- [Optimisation des Requêtes SQL](https://use-the-index-luke.com/)

---

*Ce modèle OLAP est conçu pour gérer efficacement des données volumineuses tout en maintenant des performances optimales pour les analyses métier.*
