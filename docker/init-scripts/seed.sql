-- seed.sql
-- Aggiunge gli ID corretti usati dal codice (s1/s2/s3, v1/v2/v3/v-test)
-- I dati station1/car1 ecc. sono già inseriti dallo schema.sql

-- ==================== STATIONS ====================
INSERT INTO stations (station_id, name, latitude, longitude) VALUES
('s1', 'Bari Centro',     41.1171, 16.8719),
('s2', 'Bari Porto',      41.1222, 16.8715),
('s3', 'Bari Università', 41.1200, 16.8700)
ON CONFLICT (station_id) DO NOTHING;

-- ==================== VEHICLES ====================
INSERT INTO vehicles (vehicle_id, station_id, status, battery_level) VALUES
('v1',     's1', 'AVAILABLE', 76),
('v2',     's2', 'AVAILABLE', 80),
('v3',     's3', 'AVAILABLE', 100),
('v-test', 's1', 'AVAILABLE', 90)
ON CONFLICT (vehicle_id) DO NOTHING;

-- ==================== TRACKING ====================
INSERT INTO tracking_veichle (vehicle_id, latitude, longitude) VALUES
('v1',     41.1171, 16.8719),
('v2',     41.1222, 16.8715),
('v3',     41.1200, 16.8700),
('v-test', 41.1171, 16.8719)
ON CONFLICT DO NOTHING;

SELECT 'Seed data loaded successfully' AS status;