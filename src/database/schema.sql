-- ============================================
-- TABLE: users (Utenti)
-- ============================================
CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    password VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE users IS 'Utenti del sistema';
COMMENT ON COLUMN users.user_id IS 'Identificativo univoco utente (es: mario, luigi)';

INSERT INTO users (user_id, password) VALUES
('mario', 'mario'),
('luigi', 'luigi'),
('peach', 'peach'),
('wario', 'wario'),
('waluigi', 'waluigi'),
('toad', 'toad');

-- ============================================
-- TABLE: user_bank (Conti in banca degli utenti)
-- ============================================
CREATE TABLE user_bank(
    user_id VARCHAR(50) PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    balance DECIMAL(10, 2) NOT NULL DEFAULT 100.00,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dati iniziali
INSERT INTO user_bank (user_id, balance) VALUES
('mario', 1000.00),
('luigi', 5.00),
('peach', 100.00),
('wario', 1000.00),
('waluigi', 1000.00),
('toad', 100.00);

-- ============================================
-- TABLE: stations (Stazioni fisiche)
-- ============================================
CREATE TABLE stations (
    station_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    latitude DECIMAL(10, 7),
    longitude DECIMAL(11, 7)
);

COMMENT ON TABLE stations IS 'Stazioni di parcheggio veicoli';
COMMENT ON COLUMN stations.station_id IS 'Identificativo univoco stazione';

-- Dati iniziali (coordinate Bari, Italia)
INSERT INTO stations (station_id, name, latitude, longitude) VALUES
('station1', 'Bari Centro', 41.1171, 16.8719),
('station2', 'Bari Porto', 41.1222, 16.8715),
('station3', 'Bari Università', 41.1200, 16.8700);


-- ============================================
-- TABLE: vehicles (Veicolo)
-- ============================================
CREATE TABLE vehicles (
    vehicle_id VARCHAR(50) PRIMARY KEY,
    station_id VARCHAR(50) REFERENCES stations(station_id) ON DELETE SET NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    battery_level INT NOT NULL DEFAULT 100,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT status_check CHECK (status IN ('AVAILABLE', 'RESERVED', 'UNLOCKED', 'IN_USE', 'BROKEN', 'CHARGING'))
);

COMMENT ON TABLE vehicles IS 'Veicoli elettrici disponibili per noleggio';
COMMENT ON COLUMN vehicles.status IS 'Stato: AVAILABLE, RESERVED, UNLOCKED, IN_USE, BROKEN, CHARGING';
COMMENT ON COLUMN vehicles.battery_level IS 'Livello batteria in percentuale (0-100)';

-- Dati iniziali
INSERT INTO vehicles (vehicle_id, station_id, status, battery_level) VALUES
('car1', 'station1', 'AVAILABLE', 76),
('car2', 'station2', 'AVAILABLE', 80),
('car3', 'station3', 'AVAILABLE', 100);

-- ============================================
-- TABLE: tracking_veichle
-- ============================================
CREATE TABLE tracking_veichle(
    id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(50) REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
    latitude DECIMAL(10, 7),
    longitude DECIMAL(11, 7)
);

-- Dati iniziali tracking
INSERT INTO tracking_veichle (vehicle_id, latitude, longitude) VALUES
('car1', 41.1171, 16.8719),
('car2', 41.1222, 16.8715),
('car3', 41.1200, 16.8700);

-- ============================================
-- TABLE: authorizations (Pre-autorizzazioni bancarie)
-- ============================================
CREATE TABLE authorizations (
    auth_token VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    is_reservation BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

COMMENT ON TABLE authorizations IS 'Token di pre-autorizzazione bancaria';
COMMENT ON COLUMN authorizations.auth_token IS 'Token univoco generato dalla banca';

CREATE INDEX idx_auth_user ON authorizations(user_id);
CREATE INDEX idx_auth_created ON authorizations(created_at);

-- ============================================
-- TABLE: transactions (Storico transazioni)
-- ============================================
CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    auth_token VARCHAR(100) REFERENCES authorizations(auth_token) ON DELETE SET NULL,
    user_id VARCHAR(50) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    transaction_type VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    balance_before DECIMAL(10, 2),
    balance_after DECIMAL(10, 2),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT tx_type_check CHECK (transaction_type IN ('PRE_AUTH', 'CANCEL_AUTH', 'COMMIT_PAYMENT', 'COMMIT_PENALTY'))
);

COMMENT ON TABLE transactions IS 'Storico di tutte le transazioni bancarie';
COMMENT ON COLUMN transactions.transaction_type IS 'Tipo: PRE_AUTH, CANCEL_AUTH, COMMIT_PAYMENT, COMMIT_PENALTY';
COMMENT ON COLUMN transactions.amount IS 'Importo transazione (positivo o negativo)';

CREATE INDEX idx_tx_user ON transactions(user_id);
CREATE INDEX idx_tx_auth ON transactions(auth_token);
CREATE INDEX idx_tx_date ON transactions(created_at);
CREATE INDEX idx_tx_type ON transactions(transaction_type);

-- ============================================
-- TABLE: rentals (Noleggi attivi/storici)
-- ============================================
CREATE TABLE rentals (
    rental_id SERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    vehicle_id VARCHAR(50) NOT NULL REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
    auth_token VARCHAR(100) REFERENCES authorizations(auth_token) ON DELETE SET NULL,
    
    rental_type VARCHAR(20) NOT NULL,
    
    start_station_id VARCHAR(50) REFERENCES stations(station_id) ON DELETE SET NULL,
    end_station_id VARCHAR(50) REFERENCES stations(station_id) ON DELETE SET NULL,
    
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    
    start_battery INT,
    end_battery INT,
    
    start_latitude DECIMAL(10, 7),
    start_longitude DECIMAL(11, 7),
    end_latitude DECIMAL(10, 7),
    end_longitude DECIMAL(11, 7),
    
    total_km DECIMAL(10, 2),
    
    status VARCHAR(20) DEFAULT 'RESERVED',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT rental_type_check CHECK (rental_type IN ('IMMEDIATE', 'RESERVATION')),
    CONSTRAINT rental_status_check CHECK (status IN ('RESERVED', 'ACTIVE', 'COMPLETED', 'CANCELLED'))
);

COMMENT ON TABLE rentals IS 'Noleggi (prenotazioni + noleggi immediati)';
COMMENT ON COLUMN rentals.rental_type IS 'Tipo: IMMEDIATE o RESERVATION';
COMMENT ON COLUMN rentals.status IS 'Stato: RESERVED, ACTIVE, COMPLETED, CANCELLED';

CREATE INDEX idx_rental_user ON rentals(user_id);
CREATE INDEX idx_rental_vehicle ON rentals(vehicle_id);
CREATE INDEX idx_rental_status ON rentals(status);
CREATE INDEX idx_rental_dates ON rentals(start_time, end_time);

-- ============================================
-- TABLE: invoices (Fatture finali)
-- ============================================
CREATE TABLE invoices (
    invoice_id SERIAL PRIMARY KEY,
    rental_id INT NOT NULL REFERENCES rentals(rental_id) ON DELETE CASCADE,
    user_id VARCHAR(50) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    subtotal DECIMAL(10, 2) NOT NULL,
    penalty DECIMAL(10, 2) DEFAULT 0.00,
    payment_status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT payment_status_check CHECK (payment_status IN ('PENDING', 'PAID', 'FAILED'))
);

COMMENT ON TABLE invoices IS 'Fatture generate dal CalculatorService';
COMMENT ON COLUMN invoices.subtotal IS 'Costo base (tempo + distanza)';
COMMENT ON COLUMN invoices.penalty IS 'Penale per batteria < 15%';
COMMENT ON COLUMN invoices.payment_status IS 'Stato pagamento: PENDING, PAID, FAILED';

CREATE INDEX idx_invoice_rental ON invoices(rental_id);
CREATE INDEX idx_invoice_user ON invoices(user_id);
CREATE INDEX idx_invoice_status ON invoices(payment_status);

-- ============================================
-- TRIGGER: Auto-update timestamp
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_bank_updated_at
BEFORE UPDATE ON user_bank
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vehicles_last_updated
BEFORE UPDATE ON vehicles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rentals_updated_at
BEFORE UPDATE ON rentals
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VIEWS: Query comuni
-- ============================================

-- View: Noleggi attivi
CREATE VIEW active_rentals AS
SELECT 
    r.rental_id,
    r.user_id,
    r.vehicle_id,
    r.rental_type,
    v.status AS vehicle_status,
    v.battery_level,
    r.start_latitude,
    r.start_longitude,
    r.start_time,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - r.start_time))/60 AS elapsed_minutes
FROM rentals r
JOIN vehicles v ON r.vehicle_id = v.vehicle_id
WHERE r.status = 'ACTIVE';

-- View: Statistiche utente
CREATE VIEW user_stats AS
SELECT 
    u.user_id,
    ub.balance,
    COUNT(DISTINCT r.rental_id) AS total_rentals,
    SUM(r.total_km) AS total_km_driven,
    SUM(EXTRACT(EPOCH FROM (r.end_time - r.start_time))/60) AS total_minutes_rented,
    COUNT(DISTINCT i.invoice_id) AS total_invoices,
    SUM(i.subtotal + COALESCE(i.penalty, 0)) AS total_spent
FROM users u
JOIN user_bank ub ON u.user_id = ub.user_id
LEFT JOIN rentals r ON u.user_id = r.user_id AND r.status = 'COMPLETED'
LEFT JOIN invoices i ON u.user_id = i.user_id AND i.payment_status = 'PAID'
GROUP BY u.user_id, ub.balance;

-- View: Veicoli disponibili per stazione
CREATE VIEW available_vehicles_by_station AS
SELECT 
    s.station_id,
    s.name AS station_name,
    s.latitude AS station_latitude,
    s.longitude AS station_longitude,
    COUNT(v.vehicle_id) AS available_vehicles,
    AVG(v.battery_level) AS avg_battery_level
FROM stations s
LEFT JOIN vehicles v ON s.station_id = v.station_id AND v.status = 'AVAILABLE'
GROUP BY s.station_id, s.name, s.latitude, s.longitude;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================
-- Per l'utente Camunda
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO camunda;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO camunda;
