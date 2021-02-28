-- Se crea la base de datos
CREATE DATABASE ong; 

-- Se fija la base de datos que se va a utilizar
USE ong;

-- Creacion de la tabla SEDE
CREATE TABLE sede(
	ciudad VARCHAR(20) PRIMARY KEY,
    direccion VARCHAR(100) NOT NULL,
    director VARCHAR(64) NOT NULL,
    fecha_creacion DATE NOT NULL
);

-- Creacion de la tabla MILITAR
CREATE TABLE militar (
	num_registro CHAR(12) PRIMARY KEY,
    DNI CHAR(9) NOT NULL,
    nombre VARCHAR(16) NOT NULL,
    primer_apellido VARCHAR(30) NOT NULL,
    segundo_apellido VARCHAR(30),
    fecha_nacimiento DATE NOT NULL,
    mail VARCHAR(320),
    telefono CHAR(11) NOT NULL,
    disponibilidad VARCHAR(10) NOT NULL,
    cuerpo_ejercito VARCHAR(10),
    fecha_solicitud DATE NOT NULL, 
    sede_ciudad VARCHAR(20) NOT NULL,
    tipo_ayuda VARCHAR(15) NOT NULL,
    CHECK (num_registro LIKE 'M%'),
    CHECK (telefono LIKE '6%' OR telefono LIKE '7%'),
    CHECK (disponibilidad IN ('Diurna', 'Vespertina', 'Completa')),
    CHECK (cuerpo_ejercito IN ('Tierra', 'Aire', 'Armada')),
    CHECK (tipo_ayuda IN ('Material', 'Humanitaria')),
    FOREIGN KEY (sede_ciudad) REFERENCES sede (ciudad)
);


-- Creacion de la tabla SOCIO
CREATE TABLE socio (
	num_alta CHAR(12) PRIMARY KEY,
    DNI CHAR(9) NOT NULL,
	nombre VARCHAR(16) NOT NULL,
    primer_apellido VARCHAR(30) NOT NULL,
    segundo_apellido VARCHAR(30),
	mail VARCHAR(320),
    telefono CHAR(11) NOT NULL,
    num_cuenta_bancaria CHAR(29) NOT NULL,
    cuota INT NOT NULL,
    fecha_pago DATE NOT NULL,
    sexo VARCHAR(6),
    sede_ciudad VARCHAR(20) NOT NULL,
    CHECK (num_alta LIKE 'SO%'),
    CHECK (telefono LIKE '6%' OR telefono LIKE '7%'),
    CHECK (cuota BETWEEN 50 AND 200),
    CHECK (sexo IN ('Hombre', 'Mujer', NULL)),
    FOREIGN KEY (sede_ciudad) REFERENCES sede (ciudad)
);

-- Creacion de la tabla ADMINISTRATIVO
CREATE TABLE administrativo (
	num_inscripcion CHAR(12) PRIMARY KEY,
    DNI CHAR(9) NOT NULL,
	nombre VARCHAR(16) NOT NULL,
    primer_apellido VARCHAR(30) NOT NULL,
    segundo_apellido VARCHAR(30),
    fecha_nacimiento DATE NOT NULL,
	telefono CHAR(11) NOT NULL,
    sexo VARCHAR(6),
    sede_ciudad VARCHAR(20) NOT NULL,
    CHECK (num_inscripcion LIKE 'A%'),
    CHECK (telefono LIKE '6%' OR telefono LIKE '7%'),
    CHECK (sexo IN ('Hombre', 'Mujer', NULL)),
    FOREIGN KEY (sede_ciudad) REFERENCES sede (ciudad)
);

-- Creacion de la tabla SANITARIO
CREATE TABLE sanitario (
	num_inscripcion CHAR(12) PRIMARY KEY,
    DNI CHAR(9) NOT NULL,
	nombre VARCHAR(16) NOT NULL,
    primer_apellido VARCHAR(30) NOT NULL,
    segundo_apellido VARCHAR(30),
    fecha_nacimiento DATE NOT NULL,
	telefono CHAR(11) NOT NULL,
    sexo VARCHAR(6),
    num_colegiado CHAR(9) NOT NULL,
    especialidad VARCHAR(20) NOT NULL,
    disponibilidad VARCHAR(10) NOT NULL,
    sede_ciudad VARCHAR(20) NOT NULL,
    CHECK (num_inscripcion LIKE 'SA%'),
    CHECK (telefono LIKE '6%' OR telefono LIKE '7%'),
    CHECK (sexo IN ('Hombre', 'Mujer', NULL)),
    CHECK (disponibilidad IN ('Diurna', 'Vespertina', 'Completa')),
    FOREIGN KEY (sede_ciudad) REFERENCES sede (ciudad)
);

-- Creacion de la tabla EMPRESA
CREATE TABLE empresa (
	NIF CHAR(9) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    direccion VARCHAR(100) NOT NULL,
    sector VARCHAR(30) NOT NULL
);

-- Creacion de la tabla AYUDA
CREATE TABLE ayuda ( 
	codigo_ayuda VARCHAR(5) PRIMARY KEY,
    descripcion VARCHAR(50) NOT NULL
);

-- Creacion de la tabla RECIBE_HUMANITARIA
CREATE TABLE recibe_humanitaria (
	militar_num_registro CHAR(12) NOT NULL,
    sanitario_num_inscripcion CHAR(12) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    PRIMARY KEY (militar_num_registro, sanitario_num_inscripcion, fecha_inicio),
    FOREIGN KEY (militar_num_registro) REFERENCES militar (num_registro),
    FOREIGN KEY (sanitario_num_inscripcion) REFERENCES sanitario (num_inscripcion)
);

-- Creacion de la tabla RECIBE_MATERIAL
CREATE TABLE recibe_material (
	militar_num_registro CHAR(12) NOT NULL,
    ayuda_codigo_ayuda VARCHAR(5) NOT NULL,
    fecha DATE NOT NULL,
    cantidad INT NOT NULL,
    PRIMARY KEY (militar_num_registro, ayuda_codigo_ayuda, fecha),
    FOREIGN KEY (militar_num_registro) REFERENCES militar (num_registro),
    FOREIGN KEY (ayuda_codigo_ayuda) REFERENCES ayuda (codigo_ayuda)
);

-- Creacion de la tabla DONACIONES
CREATE TABLE donaciones (
	empresa_NIF CHAR(9) NOT NULL,
    fecha DATE NOT NULL,
    sede_ciudad VARCHAR(20) NOT NULL,
    cantidad_donada INT NOT NULL,
    PRIMARY KEY (empresa_NIF, sede_ciudad, fecha),
    FOREIGN KEY (empresa_NIF) REFERENCES empresa (NIF),
    FOREIGN KEY (sede_ciudad) REFERENCES sede (ciudad)
);

-- Creacion de la tabla APORTACIONES
CREATE TABLE aportaciones (
	fecha DATE NOT NULL,
	sede_ciudad VARCHAR(20) NOT NULL,
    ayuda_codigo_ayuda VARCHAR(5) NOT NULL,
    empresa_NIF CHAR(9) NOT NULL,
    cantidad INT NOT NULL,
    PRIMARY KEY (sede_ciudad, ayuda_codigo_ayuda, empresa_NIF, fecha),
    FOREIGN KEY (sede_ciudad) REFERENCES sede (ciudad),
    FOREIGN KEY (ayuda_codigo_ayuda) REFERENCES ayuda (codigo_ayuda),
    FOREIGN KEY (empresa_NIF) REFERENCES empresa (NIF)
);



