CREATE DATABASE acme_business;

\c acme_business;

CREATE TABLE accounts (
    user_id VARCHAR(50) PRIMARY KEY,
    balance DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    blocked_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00
);

INSERT INTO accounts (user_id, balance, blocked_amount) VALUES 
('mario', 1000.00, 0.00),
('luigi', 5.00, 0.00),
('peach', 100.00, 0.00);

GRANT ALL PRIVILEGES ON DATABASE acme_business TO camunda;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO camunda;