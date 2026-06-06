-- seed.sql
-- Popolamento dati iniziali database acme_mobility

-- Connessione al database


-- ==================== USERS ====================
INSERT INTO users (user_id, balance) VALUES
('mario', 1000.00),
('luigi', 5.00),
('peach', 100.00),
('wario', 1000.00),
('waluigi', 1000.00),
('toad', 100.00)
ON CONFLICT (user_id) DO NOTHING;

-- ==================== STATIONS ====================
INSERT INTO stations (station_id, name, latitude, longitude, address) VALUES
('station1', 'Bari Centro', 41.1171, 16.8719, 'Piazza Ferrarese, Bari'),
('station2', 'Bari Porto', 41.1222, 16.8715, 'Lungomare Nazario Sauro, Bari'),
('station3', 'Bari Università', 41.1200, 16.8700, 'Campus Universitario, Bari')
ON CONFLICT (station_id) DO NOTHING;

-- ==================== VEHICLES ====================
INSERT INTO vehicles (vehicle_id, station_id, status, battery_level, latitude, longitude, total_km) VALUES
('car1', 'station1', 'AVAILABLE', 76, 41.1171, 16.8719, 0.00),
('car2', 'station2', 'AVAILABLE', 80, 41.1222, 16.8715, 0.00),
('car3', 'station3', 'AVAILABLE', 100, 41.1200, 16.8700, 0.00)
ON CONFLICT (vehicle_id) DO NOTHING;

SELECT 'Seed data loaded successfully' AS status;
