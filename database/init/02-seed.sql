-- Datos de ejemplo para la maqueta funcional (PoC)
-- Contraseñas: admin -> Admin123!  |  operador -> Operador123!
INSERT INTO users (email, password_hash, role) VALUES
    ('admin@cruzazul.cl',    '$2a$10$BCimzg9n/DDxbQsRbdWBVui/acuwmRCcvGdU3QPeGMnHyrjGJ9mdK', 'admin'),
    ('operador@cruzazul.cl', '$2a$10$DZALJBgG4QD77JuFLTT8mu6bwabAlQnyhi7x9ACax963LbY2c/4Ky', 'operador')
ON CONFLICT (email) DO NOTHING;

INSERT INTO products (sku, nombre, laboratorio, precio, stock) VALUES
    ('PARA-500', 'Paracetamol 500mg x16',        'Laboratorio Chile', 1290,  340),
    ('IBUP-400', 'Ibuprofeno 400mg x20',         'Saval',             2190,  210),
    ('AMOX-500', 'Amoxicilina 500mg x21',        'Andrómaco',         4590,   90),
    ('LORA-10',  'Loratadina 10mg x10',          'Mintlab',           1990,  150),
    ('OMEP-20',  'Omeprazol 20mg x14',           'Recalcine',         2790,  120),
    ('VITC-1G',  'Vitamina C 1g efervescente x10','Bayer',            3490,   80),
    ('ASPI-100', 'Aspirina 100mg x30',           'Bayer',             1690,  260),
    ('MELO-15',  'Meloxicam 15mg x10',           'Saval',             3990,   60),
    ('CETI-10',  'Cetirizina 10mg x10',          'Mintlab',           2090,  130),
    ('ALCO-70',  'Alcohol gel 70% 250ml',        'Cruz Azul',          990,  500)
ON CONFLICT (sku) DO NOTHING;
