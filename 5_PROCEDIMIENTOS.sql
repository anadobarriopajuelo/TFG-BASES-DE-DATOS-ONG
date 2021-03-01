use ong;

/* Procedimiento 1:
Detectar las entradas de recibe_humanitaria incorrectas por no coincidir la disponibilidad del militar y del sanitario
*/

# Tabla para almacenar los resultados del procedimiento
CREATE TABLE error_disponibilidad (id INTEGER primary key AUTO_INCREMENT, err VARCHAR(100), tupla VARCHAR(100));

# Definir el procedimiento almacenado
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE ComprobarCoincideDisponibilidad()	
    BEGIN
		DECLARE milReg CHAR(12);
		DECLARE dispMil VARCHAR(10);
        DECLARE sanIns CHAR(12);
		DECLARE dispSan VARCHAR(10);
		DECLARE done INT DEFAULT FALSE;
  
		DECLARE cur CURSOR FOR 
			SELECT M.num_registro, M.disponibilidad, S.num_inscripcion, S.disponibilidad 
			FROM militar M, sanitario S, recibe_humanitaria RH
			WHERE M.num_registro = RH.militar_num_registro AND S.num_inscripcion = RH.sanitario_num_inscripcion;
   
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
   
		OPEN cur;
  
		read_loop: LOOP
			FETCH cur INTO milReg, dispMil, sanIns, dispSan;
    
			IF done THEN
			LEAVE read_loop;
			END IF;
		
			IF (dispMil='Vespertina' AND dispSan='Diurna') OR (dispMil='Diurna' AND dispSan='Vespertina') THEN
				INSERT INTO error_disponibilidad(err, tupla) VALUES('Disponibilidad diferente', CONCAT_WS(', ', milReg, dispMil, sanIns, dispSan));
			END IF;
		END LOOP;

		CLOSE cur;
	END
$$

# Invocar el procedimiento almacenado
CALL ComprobarCoincideDisponibilidad();


/* Procedimiento 2:
Detectar las entradas de recibe_humanitaria por las que el militar recibe ayuda humanitaria sin habearla solicitado
*/

# Tabla para almacenar los resultados del procedimiento
CREATE TABLE error_no_solicita_humanitaria (id INTEGER primary key AUTO_INCREMENT, err VARCHAR(100), tupla VARCHAR(100));

# Definir el procedimiento almacenado
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE CoincideHumanitaria()	
    BEGIN
		DECLARE milReg CHAR(12);
        DECLARE tipoAy VARCHAR(15);
		DECLARE done INT DEFAULT FALSE;
  
		DECLARE cur CURSOR FOR 
			SELECT DISTINCT M.num_registro, M.tipo_ayuda
            FROM militar M, recibe_humanitaria RH
			WHERE M.num_registro = RH.militar_num_registro;
   
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
   
		OPEN cur;
  
		read_loop: LOOP
			FETCH cur INTO milReg, tipoAy;
    
			IF done THEN
			LEAVE read_loop;
			END IF;
		
			IF tipoAy <> 'Humanitaria' THEN
				INSERT INTO error_no_solicita_humanitaria(err, tupla) VALUES('No solicita ayuda humanitaria', CONCAT_WS(', ', milReg, tipoAy));
			END IF;
		END LOOP;

		CLOSE cur;
	END
$$

# Invocar el procedimiento almacenado
CALL CoincideHumanitaria();


-- Procedimiento 3: analogo a procedimiento 2 pero para recibe_material

CREATE TABLE error_no_solicita_material (id INTEGER primary key AUTO_INCREMENT, err VARCHAR(100), tupla VARCHAR(100));

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE CoincideMaterial()	
    BEGIN
		DECLARE milReg CHAR(12);
        DECLARE tipoAy VARCHAR(15);
		DECLARE done INT DEFAULT FALSE;
  
		DECLARE cur CURSOR FOR 
			SELECT DISTINCT M.num_registro, M.tipo_ayuda
            FROM militar M, recibe_material RM
			WHERE M.num_registro = RM.militar_num_registro;
   
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
   
		OPEN cur;
  
		read_loop: LOOP
			FETCH cur INTO milReg, tipoAy;
    
			IF done THEN
			LEAVE read_loop;
			END IF;
		
			IF tipoAy <> 'Material' THEN
				INSERT INTO error_no_solicita_material(err, tupla) VALUES('No solicita ayuda material', CONCAT_WS(', ', milReg, tipoAy));
			END IF;
		END LOOP;

		CLOSE cur;
	END
$$

CALL CoincideMaterial();


/* Procedimiento 4:
Detectar los militares atendidos a la vez por más de un sanitario dde la misma especialidad
*/

# Tabla para almacenar los resultados
CREATE TABLE MismoTiempoMismaEspec (id INTEGER primary key AUTO_INCREMENT, err VARCHAR(100), tupla VARCHAR(100));

# Definir el procedimiento almacenado
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE atencion_misma_especialidad()	
    BEGIN
		DECLARE milReg CHAR(12);
        DECLARE espec VARCHAR(20);
        DECLARE cont INTEGER;
		DECLARE done INT DEFAULT FALSE;
  
		DECLARE cur CURSOR FOR 
			SELECT RH.militar_num_registro, S.especialidad, COUNT(*) AS num_atenciones
            FROM sanitario S, recibe_humanitaria RH
			WHERE S.num_inscripcion= RH.sanitario_num_inscripcion AND ISNULL(RH.fecha_fin)
            GROUP BY RH.militar_num_registro, S.especialidad;
   
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
   
		OPEN cur;
  
		read_loop: LOOP
			FETCH cur INTO milReg, espec, cont;
    
			IF done THEN
			LEAVE read_loop;
			END IF;
		
			IF cont > 1 THEN
				INSERT INTO MismoTiempoMismaEspec(err, tupla) VALUES('Le atienden a la vez dos sanitarios de la misma especialidad', CONCAT_WS(', ', milReg, espec, cont));
			END IF;
		END LOOP;

		CLOSE cur;
	END
$$

# Invocar el procedimiento almacenado
CALL atencion_misma_especialidad();


