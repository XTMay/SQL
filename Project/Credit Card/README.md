# Credit Card Spending & Fraud Detection

## Project Overview

This project analyzes credit card transaction data to uncover spending patterns, customer behavior, and detect fraudulent activities. The dataset contains comprehensive information about customers, merchants, transactions, and geographical data, providing a rich foundation for data-driven insights in the financial services domain. The project demonstrates practical applications of SQL for business intelligence, customer analytics, and fraud detection in the credit card industry.

## Dataset Schema

The database consists of six interconnected tables that model a comprehensive credit card transaction ecosystem:

### Customers Table
| Field      | Type     | Description                    |
|------------|----------|--------------------------------|
| cc_num     | BIGINT   | Primary key, credit card number|
| first      | TEXT     | Customer first name            |
| last       | TEXT     | Customer last name             |
| gender     | CHAR(1)  | Gender (M/F)                   |
| dob        | DATE     | Date of birth                  |
| job        | TEXT     | Customer occupation            |
| street     | TEXT     | Street address                 |
| city       | TEXT     | City name                      |
| state      | CHAR(2)  | State code                     |
| zip        | INT      | ZIP code                       |
| lat        | FLOAT    | Latitude coordinate            |
| long       | FLOAT    | Longitude coordinate           |
| city_pop   | INT      | City population                |

### Merchants Table
| Field         | Type     | Description                    |
|---------------|----------|--------------------------------|
| merchant_id   | INTEGER  | Primary key, auto-increment    |
| merchant_name | TEXT     | Merchant business name         |
| category      | TEXT     | Business category              |
| merch_lat     | FLOAT    | Merchant latitude              |
| merch_long    | FLOAT    | Merchant longitude             |

### Transactions Table
| Field       | Type     | Description                    |
|-------------|----------|--------------------------------|
| trans_num   | TEXT     | Primary key, transaction ID    |
| cc_num      | BIGINT   | Foreign key to customers       |
| merchant_id | INT      | Foreign key to merchants       |
| trans_date  | DATETIME | Transaction timestamp          |
| unix_time   | BIGINT   | Unix timestamp                 |
| amt         | FLOAT    | Transaction amount             |
| is_fraud    | BOOLEAN  | Fraud indicator flag           |

### Categories Table
| Field       | Type     | Description                    |
|-------------|----------|--------------------------------|
| category    | TEXT     | Primary key, category code     |
| description | TEXT     | Category description           |

### States Table
| Field      | Type     | Description                    |
|------------|----------|--------------------------------|
| state_code | CHAR(2)  | Primary key, state code        |
| state_name | TEXT     | Full state name                |

### Cities Table
| Field      | Type     | Description                    |
|------------|----------|--------------------------------|
| city       | TEXT     | City name                      |
| state_code | CHAR(2)  | State code                     |
| city_pop   | INT      | Population                     |
| lat        | FLOAT    | Latitude                       |
| long       | FLOAT    | Longitude                      |

## Analysis Objectives

### 1. Customer Spending Analysis
- Analyze spending patterns by demographics (age, gender, occupation)
- Identify high-value customers and spending trends
- Geographic spending distribution analysis

### 2. Fraud Detection & Prevention
- Identify suspicious transaction patterns
- Analyze fraud indicators by merchant category
- Geographic fraud hotspot identification
- Time-based fraud pattern analysis

### 3. Merchant Performance Analytics
- Revenue analysis by merchant category
- Geographic distribution of merchant performance
- Customer-merchant relationship patterns

### 4. Risk Assessment
- Customer risk profiling based on transaction behavior
- Merchant risk scoring
- Regional risk assessment

### 5. Business Intelligence
- Market penetration analysis by geography
- Customer lifetime value calculation
- Seasonal spending pattern identification

## SQL Examples

### 1. Customer Spending Analysis by Demographics
```sql
-- Average spending by age group and gender
SELECT 
    CASE 
        WHEN (julianday('now') - julianday(dob))/365.25 < 30 THEN '18-29'
        WHEN (julianday('now') - julianday(dob))/365.25 < 40 THEN '30-39'
        WHEN (julianday('now') - julianday(dob))/365.25 < 50 THEN '40-49'
        WHEN (julianday('now') - julianday(dob))/365.25 < 60 THEN '50-59'
        ELSE '60+' 
    END as age_group,
    gender,
    COUNT(*) as customer_count,
    AVG(amt) as avg_transaction_amount,
    SUM(amt) as total_spending
FROM customers c
JOIN transactions t ON c.cc_num = t.cc_num
GROUP BY age_group, gender
ORDER BY total_spending DESC;
```

### 2. Fraud Detection Analysis
```sql
-- Identify potential fraud patterns by analyzing transaction amounts and frequency
SELECT 
    c.cc_num,
    c.first || ' ' || c.last as customer_name,
    COUNT(CASE WHEN is_fraud = TRUE THEN 1 END) as fraud_transactions,
    COUNT(*) as total_transactions,
    ROUND(100.0 * COUNT(CASE WHEN is_fraud = TRUE THEN 1 END) / COUNT(*), 2) as fraud_rate,
    AVG(CASE WHEN is_fraud = TRUE THEN amt END) as avg_fraud_amount,
    AVG(CASE WHEN is_fraud = FALSE THEN amt END) as avg_legitimate_amount
FROM customers c
JOIN transactions t ON c.cc_num = t.cc_num
GROUP BY c.cc_num, customer_name
HAVING fraud_transactions > 0
ORDER BY fraud_rate DESC, fraud_transactions DESC;
```

### 3. Merchant Category Performance
```sql
-- Revenue analysis by merchant category with fraud impact
SELECT 
    cat.category,
    cat.description,
    COUNT(t.trans_num) as total_transactions,
    SUM(t.amt) as total_revenue,
    AVG(t.amt) as avg_transaction_amount,
    COUNT(CASE WHEN t.is_fraud = TRUE THEN 1 END) as fraud_count,
    ROUND(100.0 * COUNT(CASE WHEN t.is_fraud = TRUE THEN 1 END) / COUNT(*), 2) as fraud_percentage
FROM categories cat
JOIN merchants m ON cat.category = m.category
JOIN transactions t ON m.merchant_id = t.merchant_id
GROUP BY cat.category, cat.description
ORDER BY total_revenue DESC;
```

### 4. Geographic Risk Assessment
```sql
-- State-level fraud analysis with population context
SELECT 
    s.state_name,
    COUNT(DISTINCT c.cc_num) as unique_customers,
    COUNT(t.trans_num) as total_transactions,
    SUM(t.amt) as total_volume,
    COUNT(CASE WHEN t.is_fraud = TRUE THEN 1 END) as fraud_transactions,
    ROUND(100.0 * COUNT(CASE WHEN t.is_fraud = TRUE THEN 1 END) / COUNT(*), 2) as fraud_rate,
    AVG(c.city_pop) as avg_city_population
FROM states s
JOIN customers c ON s.state_code = c.state
JOIN transactions t ON c.cc_num = t.cc_num
GROUP BY s.state_name
HAVING total_transactions > 5
ORDER BY fraud_rate DESC;
```

### 5. Customer Behavior Segmentation
```sql
-- Customer segmentation based on spending behavior
WITH customer_metrics AS (
    SELECT 
        c.cc_num,
        c.first || ' ' || c.last as customer_name,
        c.job,
        COUNT(t.trans_num) as transaction_frequency,
        SUM(t.amt) as total_spending,
        AVG(t.amt) as avg_transaction_amount,
        MAX(t.amt) as max_transaction_amount,
        COUNT(CASE WHEN t.is_fraud = TRUE THEN 1 END) as fraud_incidents
    FROM customers c
    JOIN transactions t ON c.cc_num = t.cc_num
    GROUP BY c.cc_num, customer_name, c.job
)
SELECT 
    customer_name,
    job,
    CASE 
        WHEN total_spending > 200 AND transaction_frequency > 3 THEN 'High Value - Active'
        WHEN total_spending > 200 AND transaction_frequency <= 3 THEN 'High Value - Occasional'
        WHEN total_spending <= 200 AND transaction_frequency > 3 THEN 'Low Value - Active'
        ELSE 'Low Value - Occasional'
    END as customer_segment,
    transaction_frequency,
    total_spending,
    avg_transaction_amount,
    fraud_incidents
FROM customer_metrics
ORDER BY total_spending DESC;
```

## Visualization Ideas

### 1. Spending Pattern Visualizations
- **Bar Charts**: Average spending by age group, gender, and occupation
- **Line Charts**: Transaction trends over time, seasonal spending patterns
- **Pie Charts**: Spending distribution by merchant category

### 2. Fraud Detection Visualizations
- **Scatter Plots**: Transaction amount vs. time with fraud indicators
- **Heatmaps**: Fraud occurrence by geographic region and time of day
- **Box Plots**: Transaction amount distributions for legitimate vs. fraudulent transactions

### 3. Geographic Analysis
- **Choropleth Maps**: Fraud rates by state, spending intensity by region
- **Point Maps**: Customer and merchant locations with transaction volumes
- **Flow Maps**: Transaction patterns between customer and merchant locations

### 4. Customer Analytics
- **Histogram**: Customer age distribution, spending distribution
- **Treemap**: Customer segments by value and activity level
- **Radar Charts**: Customer profiles across multiple dimensions

### 5. Business Intelligence Dashboards
- **KPI Cards**: Total transactions, fraud rate, average transaction amount
- **Time Series**: Daily/monthly transaction volumes and fraud incidents
- **Correlation Matrix**: Relationships between demographic factors and spending

## Project Highlights

### Real-World Relevance
This project addresses critical challenges in the financial services industry, providing practical insights into customer behavior analysis and fraud prevention strategies that are directly applicable to credit card companies and financial institutions.

### Comprehensive Data Pipeline
- **Data Modeling**: Well-structured relational database design with proper normalization
- **Data Quality**: Clean, consistent data with appropriate constraints and relationships
- **Scalable Architecture**: Designed to handle growing transaction volumes and additional data sources

### Advanced Analytics Capabilities
- **Fraud Detection**: Multi-dimensional fraud analysis combining transaction patterns, geographic data, and customer behavior
- **Customer Segmentation**: Data-driven customer classification for targeted marketing and risk management
- **Predictive Insights**: Foundation for building predictive models for fraud detection and customer lifetime value

### Technical Skills Demonstration
- Complex SQL queries with advanced joins, subqueries, and window functions
- Geographic data analysis capabilities
- Statistical analysis and business intelligence reporting
- Database design and optimization principles

### Business Impact
- **Risk Reduction**: Improved fraud detection capabilities to minimize financial losses
- **Customer Insights**: Deep understanding of customer behavior for better service delivery
- **Operational Efficiency**: Data-driven decision making for business optimization

## Future Work

### 1. Machine Learning Integration
- Develop predictive models using scikit-learn or TensorFlow for real-time fraud detection
- Implement customer churn prediction models
- Create recommendation systems for personalized offers

### 2. Advanced Analytics
- Time series forecasting for transaction volume prediction
- Network analysis to identify fraud rings and suspicious merchant networks
- Anomaly detection algorithms for unusual spending patterns

### 3. Real-Time Processing
- Implement streaming data processing using Apache Kafka or similar technologies
- Build real-time dashboards for fraud monitoring
- Develop alert systems for immediate fraud detection

### 4. Enhanced Data Sources
- Integrate external data sources (weather, economic indicators, social media sentiment)
- Add device fingerprinting and behavioral biometrics data
- Incorporate merchant rating and review data

### 5. Advanced Visualization
- Interactive dashboard development using Tableau or Power BI
- Web-based analytics platform using D3.js or Plotly
- Mobile analytics app for on-the-go insights

### 6. Production Deployment
- Cloud deployment on AWS, Azure, or Google Cloud Platform
- API development for external system integration
- Data pipeline automation using Apache Airflow or similar tools

---

*This project demonstrates practical application of SQL for financial data analysis, fraud detection, and business intelligence in the credit card industry.*