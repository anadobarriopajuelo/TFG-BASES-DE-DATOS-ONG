USE ong;

/* Disparador 1: INSERT
Si se inserta una entrada en recibe_humanitaria RH, comprueba:
    - Primero si esta el militar
		- Si esta el sanitario
			- Si atiende a menos de 5 pacientes
				- Si no atiende ya a este militar: inserta registro
				- Si ya lo atiende: excepcion
            - Atiende a mas de 5 pacientes: excepcion: sanitario saturado
		- No atiende el sanitario: excepcion: insertar sanitario
	- No esta el militar: excepcion: insertar militar
*/
DELIMITER $$
CREATE TRIGGER insertarHumanitaria BEFORE INSERT ON recibe_humanitaria FOR EACH ROW
	BEGIN 
        DECLARE contSan INTEGER;
        DECLARE contMil INTEGER;
        DECLARE contAtiende INTEGER;
        DECLARE yaEsta INTEGER;
        SELECT COUNT(num_registro) INTO contMil FROM militar WHERE num_registro = NEW.militar_num_registro;
		IF (contMil>0) THEN
			SELECT COUNT(num_inscripcion) INTO contSan FROM sanitario WHERE num_inscripcion = NEW.sanitario_num_inscripcion;
			IF (contSan>0) THEN
				SELECT COUNT(militar_num_registro) INTO contAtiende FROM recibe_humanitaria WHERE sanitario_num_inscripcion = NEW.sanitario_num_inscripcion AND ISNULL(fecha_fin);
				IF (contAtiende<5) THEN
					SELECT COUNT(militar_num_registro) INTO yaEsta FROM recibe_humanitaria WHERE sanitario_num_inscripcion = NEW.sanitario_num_inscripcion AND ISNULL(fecha_fin) AND militar_num_registro = NEW.militar_num_registro;
                    IF (yaEsta<>0) THEN 
						SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El sanitario ya esta atendiendo a este militar';
					END IF;
				ELSE
					SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El sanitario no puede atender mas de 5 pacientes';
				END IF;
			ELSE
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El sanitario no esta inscrito';
			END IF;
		ELSE
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El militar no esta registrado';
		END IF;
	END
$$


/* Disparador 2: INSERT
Si se inserta una entrada en recibe_material comprueba:
	- Primero si esta el militar
		- Si esta la ayuda
			- Si hay articulos disponibles: inserta entrada
            - No hay suficientes: excepcion
		- No esta la ayuda: excepcion
	- No esta el militar: excepcion
*/
DELIMITER $$
CREATE TRIGGER insertarMaterial BEFORE INSERT ON recibe_material FOR EACH ROW
	BEGIN 
        DECLARE contMil INTEGER;
        DECLARE contAyuda INTEGER;
        DECLARE donado INTEGER;
        DECLARE entregado INTEGER;
        SELECT COUNT(num_registro) INTO contMil FROM militar WHERE num_registro = NEW.militar_num_registro;
		IF (contMil>0) THEN
			SELECT COUNT(codigo_ayuda) INTO contAyuda FROM ayuda WHERE codigo_ayuda = NEW.ayuda_codigo_ayuda;
            IF (contAyuda>0) THEN
				SELECT COUNT(ayuda_codigo_ayuda) INTO donado FROM aportaciones WHERE ayuda_codigo_ayuda = NEW.ayuda_codigo_ayuda;
                SELECT COUNT(ayuda_codigo_ayuda) INTO entregado FROM recibe_material WHERE ayuda_codigo_ayuda = NEW.ayuda_codigo_ayuda; 
				IF (donado - entregado<=0) THEN
					SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay suficientes articulos';
				END IF;
			ELSE
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La ayuda no esta registrada';
			END IF;
		ELSE
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El militar no esta registrado';
		END IF;
	END
$$
    

/* Disparador 3: INSERT
Si se inserta una entrada en donaciones comprueba:
	- Primero si esta la empresa
		- Si esta la sede
		- No esta la sede: excepcion
	- No esta la empresa: excepcion
*/
DELIMITER $$
CREATE TRIGGER insertarDonacion BEFORE INSERT ON donaciones FOR EACH ROW
	BEGIN 
		DECLARE contEmp INTEGER;
        DECLARE contSede INTEGER;
        SELECT COUNT(NIF) INTO contEmp FROM empresa WHERE NIF = NEW.empresa_NIF;
		IF (contEmp>0) THEN
			SELECT COUNT(ciudad) INTO contSede FROM sede WHERE ciudad = NEW.sede_ciudad;
            IF (contSede<=0) THEN
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sede inexistente';
			END IF;
		ELSE
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Empresa no registrada';
		END IF;
	END
$$


/* Disparador 4: INSERT
Si se inserta una entrada en aportaciones comprueba:
	- Primero si esta la empresa
		- Si esta la sede
			- Si esta la ayuda: inserta registro en donaciones
			- No esta la ayuda: excepcion
		- No esta la sede: excepcion
	- No esta la empresa: excepcion
*/
DELIMITER $$    
CREATE TRIGGER insertarAportacion BEFORE INSERT ON aportaciones FOR EACH ROW
	BEGIN 
		DECLARE contEmp INTEGER;
        DECLARE contSede INTEGER;
        DECLARE contAyuda INTEGER;
        SELECT COUNT(NIF) INTO contEmp FROM empresa WHERE NIF = NEW.empresa_NIF;
		IF (contEmp>0) THEN
			SELECT COUNT(ciudad) INTO contSede FROM sede WHERE ciudad = NEW.sede_ciudad;
            IF (contSede>0) THEN
				SELECT COUNT(codigo_ayuda) INTO contAyuda FROM ayuda WHERE codigo_ayuda = NEW.ayuda_codigo_ayuda;
				IF (contAyuda<=0) THEN
					SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ayuda no registrada';
				END IF;
			ELSE
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sede inexistente';
			END IF;
		ELSE
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Empresa no registrada';
		END IF;
	END
$$


/* Disparador 5: UPDATE
Si un socio quiero aumentar o disminuir su cuota, debera seguir en los limites establecidos.
Ademas, no podra variar mas de un 10%
*/
DELIMITER $$
CREATE TRIGGER actualizarCuota BEFORE UPDATE ON socio FOR EACH ROW
 IF UPDATE(cuota) THEN
	BEGIN
		IF NEW.cuota >= 50 THEN
			IF NEW.cuota <=200 THEN
				IF ((ABS(NEW.cuota - OLD.cuota) * 100 / OLD.cuota) < 10) THEN
					SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Diferencia inferior a 10%';
				END IF;
			ELSE
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Excede el maximo';
			END IF;
		ELSE
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No supera el minimo';
		END IF;
	END
 END IF;
$$   
drop trigger actualizarCuota;

/*Disparador 6: UPDATE
Si un militar finaliza el tratamiento, hay que actualizar la fecha_fin de recibe_humanitaria
*/
DELIMITER $$
CREATE TRIGGER actualizarFin BEFORE UPDATE ON recibe_humanitaria FOR EACH ROW
	BEGIN
		IF NOT ISNULL(OLD.fecha_fin) THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fecha de fin ya registrada';
		END IF;
	END
$$


/* Disparador 7: DELETE
	- Si se elimina un militar por la razon que sea, hay que liberar al sanitario que le esta atendiendo actualmente
    - Si ya ha terminado el tratamiento, se deja en la base de datos para estadisticas futuras
*/
DELIMITER $$
CREATE TRIGGER liberarSanitario BEFORE DELETE ON militar FOR EACH ROW
	BEGIN
		DELETE FROM recibe_humanitaria WHERE ISNULL(fecha_fin) AND recibe_humanitaria.militar_num_registro = OLD.num_registro;
    END 
$$


/* Disparador 8: DELETE
Si se elimina un sanitario, hay que dejar al militar solo con la solicitud, para que le atienda otra persona
*/
DELIMITER $$
CREATE TRIGGER atenderMilitar BEFORE DELETE ON sanitario FOR EACH ROW
	BEGIN
		DELETE FROM recibe_humanitaria WHERE ISNULL(fecha_fin) AND recibe_humanitaria.sanitario_num_inscripcion = OLD.num_inscripcion;
	END
$$


/* Disparador 9: DELETE
Si se elimina una sede, hay que eliminar todos los usuarios que estan asociadas a ella
*/
DELIMITER $$
CREATE TRIGGER eliminarSede BEFORE DELETE ON sede FOR EACH ROW
	BEGIN
		DELETE FROM militar WHERE militar.sede_ciudad = OLD.ciudad;
        DELETE FROM administrativo WHERE administrativo.sede_ciudad = OLD.ciudad;
        DELETE FROM sanitario WHERE sanitario.sede_ciudad = OLD.ciudad;
        DELETE FROM socio WHERE socio.sede_ciudad = OLD.ciudad;
	END
$$