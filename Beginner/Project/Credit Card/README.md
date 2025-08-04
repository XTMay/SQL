# 🧠 SQL Fraud Detection Analysis

This project showcases how to use **pure SQL** to query and analyze a real-world dataset: [Credit Card Fraud Detection](https://www.kaggle.com/datasets/kartik2112/fraud-detection). It’s ideal for anyone learning SQL through hands-on data exploration and fraud pattern analysis.

## 📂 Dataset Summary

- **Source**: Kaggle — Simulated credit card transactions
- **Size**: ~1.5 million records
- **Features**: customer_id, merchant, category, amount, timestamp, is_fraud (target label)
- **Goal**: Use SQL to uncover patterns in fraudulent vs. legitimate transactions.

## 💡 What You’ll Learn

- How to create and import a dataset into a SQL database
- Write SQL queries to explore and filter financial transactions
- Aggregate and compare fraud vs. non-fraud patterns
- Perform group-by analysis, time-based queries, and basic risk profiling

## 🧰 Project Structure

```bash
.
├── README.md
├── dataset/
│   └── fraud_detection.csv
├── scripts/
│   ├── create_tables.sql         # Schema definition
│   ├── load_data.sql             # Data import
│   └── analysis_queries.sql      # Key SQL analysis
└── notebooks/
    └── fraud_sql_walkthrough.ipynb  # Optional: run SQL via Python + SQLite
```

🚀 How to Use
	1.	Clone this repository.
	2.	Import fraud_detection.csv into SQLite, PostgreSQL, or MySQL using the SQL scripts.
	3.	Open and run analysis_queries.sql to begin analyzing.

✅ Tip: You can use DB Browser for SQLite, DBeaver, or Jupyter SQL to interactively run and explore queries.

📊 Example SQL Queries

-- Total transactions and fraud rate by merchant
SELECT merchant, 
       COUNT(*) AS total_tx, 
       SUM(is_fraud) AS fraud_count,
       ROUND(AVG(is_fraud) * 100, 2) AS fraud_rate_percent
FROM transactions
GROUP BY merchant
ORDER BY fraud_rate_percent DESC
LIMIT 10;

📦 Tools Required
	•	SQLite / PostgreSQL / MySQL (any one)
	•	SQL client or Jupyter notebook (optional for interactive learning)
	•	Python 3 (if using the notebook)

📘 License

MIT License.
Dataset is for educational purposes only.
