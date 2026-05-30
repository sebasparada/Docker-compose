-- Se agrega el drop para eliminar los documentos basuras de intentos anteriores y evitar que la data_old, se mezcle con la data_new
DROP TABLE IF EXISTS prestamos;
DROP TABLE IF EXISTS libros;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS autores;



--SCRIP CREACION TABLAS

-- creacion de la tabla usuarios cumpliendo con los requerimientos dados, usuarios sirve teniendo la informacion vital de ellos
CREATE TABLE usuarios (
    usuario_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    numero_identificacion VARCHAR(20) UNIQUE NOT NULL,
    direccion VARCHAR(200) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- creacion de la tabla autores cumpliendo con los requisitos dados, autores sirve teniendo la informacion de los autores
CREATE TABLE autores (
    autor_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    nacionalidad VARCHAR(50),
    descripcion TEXT
);


-- creacion de la tabla categorias cumpliendo con los requisitos dados, sirve dando las categorias de los libros
CREATE TABLE categorias (
    categoria_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);


-- creacion de la tabla libros cumpliendo con los requisitos dados, junto a usuarios las mas importantes
CREATE TABLE libros (
    libro_id SERIAL PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    anio_publicacion INTEGER,
    autor_id INTEGER,
    categoria_id INTEGER,
    cantidad_disponible INTEGER DEFAULT 1,
    CONSTRAINT fk_autor FOREIGN KEY (autor_id) REFERENCES autores(autor_id) ON DELETE SET NULL,
    CONSTRAINT fk_categoria FOREIGN KEY (categoria_id) REFERENCES categorias(categoria_id) ON DELETE SET NULL
);


-- creacion de la tabla prestamos cumpliendo con los requisitos dados, esta tabla contierne las limitaciones solicitadas ademas de llamar a los usuarios y libros
CREATE TABLE prestamos (
    prestamo_id SERIAL PRIMARY KEY,
    libro_id INTEGER NOT NULL,
    usuario_id INTEGER NOT NULL,
    fecha_prestamo DATE NOT NULL,
    fecha_devolucion_esperada DATE NOT NULL,
    fecha_devolucion_real DATE,
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    CONSTRAINT fk_libro FOREIGN KEY (libro_id) REFERENCES libros(libro_id) ON DELETE NO ACTION,
    CONSTRAINT fk_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
    CONSTRAINT ck_estado CHECK (estado IN ('ACTIVO', 'DEVUELTO', 'VENCIDO')),
    CONSTRAINT ck_fechas CHECK (fecha_devolucion_esperada >= fecha_prestamo)
);




--SCRIP INSERCION DATOS


-- inserta informacion de autores
INSERT INTO autores (nombre, nacionalidad) VALUES
('Isaac Asimov', 'Ruso-Estadounidense'),
('Gabriel García Márquez', 'Colombiana'),
('J.K. Rowling', 'Británica');

-- inserta informacion de libros relacionando autores y categorias
INSERT INTO libros (titulo, isbn, anio_publicacion, autor_id, categoria_id, cantidad_disponible) VALUES
('Foundation', '978-0553293357', 1951, 1, 1, 5),
('Cien años de soledad', '978-0307474728', 1967, 2, 2, 3),
('Harry Potter', '978-0439064873', 1998, 3, 1, 10);

-- inserta informacion de usuarios registrados en la biblioteca
INSERT INTO usuarios (nombre, email, numero_identificacion, direccion, telefono) VALUES
('Sebastian', 'sebastian@example.com', '12345678', 'Calle 10 #20-30', '3001234567'),
('Maria Lopez', 'maria@example.com', '87654321', 'Carrera 5 #10-10', '3109876543'),
('Carlos Ruiz', 'carlos@example.com', '11223344', 'Calle 50 #10-20', '3201112233');

-- inserta prestamos de ejemplo para probar el funcionamiento del sistema
INSERT INTO prestamos (libro_id, usuario_id, fecha_prestamo, fecha_devolucion_esperada, fecha_devolucion_real, estado)
VALUES (1, 1, CURRENT_DATE, CURRENT_DATE + 7, NULL, 'ACTIVO'),
(2, 2, CURRENT_DATE - 10, CURRENT_DATE - 3, NULL, 'VENCIDO'),
(3, 1, CURRENT_DATE - 5, CURRENT_DATE + 2, CURRENT_DATE - 1, 'DEVUELTO');

-- creacion de indices para mejorar el rendimiento de las consultas mas frecuentes
CREATE INDEX idx_libros_titulo ON libros(titulo);
CREATE INDEX idx_autores_nombre ON autores(nombre);
CREATE INDEX idx_prestamos_estado ON prestamos(estado);
CREATE INDEX idx_libros_autor_id ON libros(autor_id);
CREATE INDEX idx_libros_categoria_id ON libros(categoria_id);
CREATE INDEX idx_prestamos_libro_id ON prestamos(libro_id);
CREATE INDEX idx_prestamos_usuario_id ON prestamos(usuario_id);
CREATE INDEX idx_prestamos_fecha_vencimiento ON prestamos(fecha_devolucion_esperada);



-- SCRIT CONSULTAS

-- 1. lista todos los libros junto con su autor y categoria
SELECT l.titulo, a.nombre AS autor, c.nombre AS categoria
FROM libros l
JOIN autores a ON l.autor_id = a.autor_id
JOIN categorias c ON l.categoria_id = c.categoria_id;

-- 2. muestra todos los prestamos que actualmente estan activos
SELECT * FROM prestamos WHERE estado = 'ACTIVO';

-- 3. consulta todos los prestamos realizados por un usuario especifico
SELECT p.* FROM prestamos p
JOIN usuarios u ON p.usuario_id = u.usuario_id
WHERE u.nombre = 'Sebastian';

-- 4. identifica los libros que no tienen prestamos activos
SELECT titulo FROM libros
WHERE libro_id NOT IN (SELECT libro_id FROM prestamos WHERE estado = 'ACTIVO');

-- 5. cuenta la cantidad de prestamos realizados por cada usuario
SELECT u.nombre, COUNT(p.prestamo_id) AS total_prestamos
FROM usuarios u
LEFT JOIN prestamos p ON u.usuario_id = p.usuario_id
GROUP BY u.usuario_id, u.nombre;

-- 6. muestra los prestamos vencidos tomando como referencia la fecha actual
SELECT * FROM prestamos
WHERE estado = 'VENCIDO'
OR (fecha_devolucion_esperada < CURRENT_DATE AND fecha_devolucion_real IS NULL);

-- 7. muestra los libros prestados junto con la fecha esperada de devolucion
SELECT l.titulo, p.fecha_devolucion_esperada
FROM prestamos p
JOIN libros l ON p.libro_id = l.libro_id;

-- 8. ordena los usuarios segun la cantidad de prestamos realizados
SELECT u.nombre, COUNT(p.prestamo_id) AS total_prestamos
FROM usuarios u
LEFT JOIN prestamos p ON u.usuario_id = p.usuario_id
GROUP BY u.usuario_id, u.nombre
ORDER BY total_prestamos DESC;