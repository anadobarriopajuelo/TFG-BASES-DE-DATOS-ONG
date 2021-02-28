use ong;

/* Consulta 1 : 
Numero de solicitudes de cada tipo de ayuda entre 1/7/2020 y 31/12/2020 (segunda mitad del 2020)
*/
SELECT tipo_ayuda, COUNT(*) AS solicitudes 
FROM militar 
WHERE (fecha_solicitud BETWEEN '2020-07-01' AND '2020-12-31')
GROUP BY tipo_ayuda;


/* Consulta 2: 
De los militares actualmente en tratamiento, obtener:
	- Numero de registro
    - DNI
    - Apellidos y nombre
    - Fecha de inicio de tratamiento
*/
SELECT DISTINCT M.num_registro, M.DNI, CONCAT(M.primer_apellido, ' ', M.segundo_apellido,', ', M.nombre) as nombre_completo, R_H.fecha_inicio
FROM militar M, recibe_humanitaria R_H
WHERE M.num_registro = R_H.militar_num_registro AND isnull(R_H.fecha_fin)
ORDER BY 4;


 /*
 Consulta 3: De los militares que no han recibido ayuda, obtener:
	- Numero de registro
    - Sede en la que solicita la ayuda    
    - Fecha de solicitud
    - Disponibilidad
    - Tipo de ayuda
*/
SELECT M.num_registro, M.sede_ciudad, M.fecha_solicitud, M.disponibilidad, M.tipo_ayuda
FROM militar M
WHERE ((M.tipo_ayuda = 'Humanitaria') AND M.num_registro NOT IN (SELECT R_H.militar_num_registro FROM recibe_humanitaria R_H))
OR ((M.tipo_ayuda = 'Material') AND M.num_registro NOT IN (SELECT R_M.militar_num_registro FROM recibe_material R_M))
ORDER BY 1;

									
/* 
 Consulta 4:
 En el año 2021:
	- sede en la que se solicita mas ayuda material
    - sede en la que se solicita mas ayuda humanitaria
	- sede en la que se solicita menos ayuda material
    - sede en la que se solicita menos ayuda humanitaria    
*/
CREATE VIEW AUX1 AS (SELECT M.sede_ciudad, count(*) as solicitud_humanitaria, M.tipo_ayuda
						FROM militar M
						WHERE YEAR(M.fecha_solicitud) = 2021 AND M.tipo_ayuda = 'Humanitaria'
						GROUP BY M.sede_ciudad);

CREATE VIEW AUX2 AS (SELECT M.sede_ciudad, count(*) as solicitud_material, M.tipo_ayuda
						FROM militar M
						WHERE YEAR(M.fecha_solicitud) = 2021 AND M.tipo_ayuda = 'Material'
						GROUP BY M.sede_ciudad);

CREATE VIEW AUX3 AS 										
(SELECT tipo_ayuda, sede_ciudad as sede_ciudad_minimo, solicitud_humanitaria as minimo
FROM AUX1
WHERE solicitud_humanitaria = (SELECT MIN(AUX1.solicitud_humanitaria) FROM AUX1)
UNION
SELECT tipo_ayuda, sede_ciudad as sede_ciudad_minimo, solicitud_material as minimo
FROM AUX2
WHERE solicitud_material = (SELECT MIN(AUX2.solicitud_material) FROM AUX2));

CREATE VIEW AUX4 AS
(SELECT tipo_ayuda, sede_ciudad as sede_ciudad_maximo, solicitud_humanitaria as maximo
FROM AUX1
WHERE solicitud_humanitaria = (SELECT MAX(solicitud_humanitaria) FROM AUX1)
UNION
SELECT tipo_ayuda, sede_ciudad as sede_ciudad_maximo, solicitud_material as maximo
FROM AUX2
WHERE solicitud_material = (SELECT MAX(solicitud_material) FROM AUX2));

SELECT AUX3.tipo_ayuda, sede_ciudad_minimo, minimo as minimo_solicitudes, sede_ciudad_maximo, maximo as maximo_solicitudes
FROM AUX3 
JOIN AUX4 
ON AUX3.tipo_ayuda = AUX4.tipo_ayuda;                                            


/*
Consulta 5:
Obtener la media de las donaciones que ha hecho cada empresa en cada una de las sedes. Mostrar tambien:
	- NIF de la empresa
    - Nombre de la empresa
    - Sector de la empresa
    - Sede en la que realizan la donacion
*/
SELECT E.NIF, D.sede_ciudad, E.nombre, E.sector, ROUND(AVG(D.cantidad_donada),1) AS media_donado
FROM donaciones D, empresa E
WHERE D.empresa_NIF = E.NIF
GROUP BY D.empresa_NIF, D.sede_ciudad
ORDER BY 2, 5 DESC;


/* Consulta 6: 
En el año 2020 obtener el top 5 de empresas que más han donado por sede. Y el top 5 que menos
*/
CREATE VIEW AUX5 AS
(SELECT D.sede_ciudad, E.NIF, E.nombre, ROUND(SUM(cantidad_donada), 1) AS total_donado
	FROM empresa E, donaciones D
	WHERE E.NIF = D.empresa_NIF AND (D.fecha BETWEEN '2020-01-01' AND '2020-12-31')
	GROUP BY D.sede_ciudad, E.NIF
	ORDER BY sede_ciudad, total_donado DESC);

SELECT * 
FROM (SELECT sede_ciudad, ROW_NUMBER() OVER (PARTITION BY sede_ciudad ORDER BY total_donado DESC) AS ranking, nombre, total_donado
		FROM AUX5) TOP_5_por_sede
WHERE ranking <=5;

SELECT * 
FROM (SELECT sede_ciudad, ROW_NUMBER() OVER (PARTITION BY sede_ciudad ORDER BY total_donado ASC) AS ranking, nombre, total_donado
		FROM AUX5) TOP_5_por_sede
WHERE ranking <=5;


/* Consulta 7:
De los socios mas antiguos por sede:
	- Sede en la que se da de alta
	- Numero de alta como socio
	- Nombre completo 
    - Fecha de alta
    - Mail
de los socio mas antiguos cuya cuota es superior a 150
*/
SELECT S.sede_ciudad, S.num_alta, CONCAT(S.nombre,' ', S.primer_apellido,' ',S.segundo_apellido) AS nombre_completo, S.fecha_pago, S.mail
FROM socio S,
	 (SELECT sede_ciudad, min(fecha_pago) as fecha_pago
	  FROM socio
      GROUP BY sede_ciudad) ANT
WHERE S.sede_ciudad = ANT.sede_ciudad AND S.fecha_pago = ANT.fecha_pago
ORDER BY S.fecha_pago;


/* Consulta 8:
Anio en el que se dan de alta mas socios por sede
*/
CREATE VIEW aux6 AS 
(SELECT sede_ciudad, YEAR(fecha_pago) as anio, count(*) as numero_altas
		FROM socio
		GROUP BY sede_ciudad, YEAR(fecha_pago)
        ORDER BY sede_ciudad, YEAR(fecha_pago));

SELECT sede_ciudad, anio, numero_altas AS maximo_altas
FROM aux6 A
WHERE numero_altas = (SELECT MAX(numero_altas) FROM aux6 WHERE aux6.sede_ciudad = A.sede_ciudad);


/* Consulta 9: 
Codigo de ayuda, descripcion y cantidad de articulos disponibles
*/
SELECT AY.codigo_ayuda, AY.descripcion, AP.aportado - EN.entregado AS disponibles
FROM ayuda AY, 
	 (SELECT ayuda_codigo_ayuda AS codigo, SUM(cantidad) AS aportado
	  FROM aportaciones 
	  GROUP BY ayuda_codigo_ayuda) AP,		
	 (SELECT ayuda_codigo_ayuda AS codigo, SUM(cantidad) AS entregado
	  FROM recibe_material
	  GROUP BY ayuda_codigo_ayuda) EN
WHERE AY.codigo_ayuda = AP.codigo AND AY.codigo_ayuda = EN.codigo
ORDER BY disponibles;


/* Consulta 10:
Sexo mayoritario en los socios y en los voluntarios
*/
SELECT AD.sexo, AD.total_sexo_administrativo, SA.total_sexo_sanitario, SO.total_sexo_socio
 FROM (SELECT sexo, count(*) AS total_sexo_administrativo
	   FROM administrativo
	   GROUP BY sexo) AD,
	  (SELECT sexo, count(*) AS total_sexo_sanitario
	   FROM sanitario
	   GROUP BY sexo) SA,
      (SELECT sexo, count(*) AS total_sexo_socio
	   FROM socio
       GROUP BY sexo) SO
WHERE AD.sexo = SA.sexo AND AD.sexo = SO.sexo AND SA.sexo = SO.sexo;


/* Consulta 11:
Tipo de ayuda mas solicitada por cada ejercito
*/
CREATE VIEW aux7 AS
(SELECT cuerpo_ejercito, tipo_ayuda, count(*) AS solicitado
	FROM militar
    GROUP BY cuerpo_ejercito, tipo_ayuda
    ORDER BY cuerpo_ejercito);

SELECT cuerpo_ejercito, tipo_ayuda, solicitado
FROM aux7 A
WHERE solicitado = (SELECT MAX(solicitado) FROM aux7 WHERE aux7.cuerpo_ejercito = A.cuerpo_ejercito);


/* Consulta 12: 
En el 2021, que sector es el que mas ha donado y el que mas ha aportado (numero de aportaciones, no cantidades)
*/
CREATE VIEW aux8 AS
(SELECT E.sector, SUM(D.cantidad_donada) AS donado
FROM empresa E, donaciones D
WHERE E.NIF = D.empresa_NIF AND YEAR(D.fecha)=2021
GROUP BY E.sector);

CREATE VIEW aux9 AS
(SELECT E.sector, COUNT(*) as numero_aportaciones
FROM empresa E, aportaciones A 
WHERE E.NIF = A.empresa_NIF AND YEAR(A.fecha)=2021
GROUP BY E.sector);

SELECT 'Mas dona' AS tipo, sector, donado AS cantidad, 'EUR' AS unidad_medida
FROM aux8 A
WHERE donado = (SELECT MAX(donado) FROM aux8)
UNION
SELECT 'Mas aporta' AS tipo, sector, numero_aportaciones AS cantidad, 'unidad' AS unidad_medida
FROM aux9 B
WHERE numero_aportaciones = (SELECT MAX(numero_aportaciones) FROM aux9);


-/* Consulta 13:
De los militares que reciben tratamiento humanitario en el 2020 obtener:
		- num_registro
        - nombre completo
        - sanitario que le atiende (num_inscripcion y nombre completo)
        - fecha_inicio y fecha_fin
*/
SELECT M.num_registro, CONCAT(M.primer_apellido,' ', M.segundo_apellido, ', ', M.nombre) AS nombre_completo_militar,
	   SA.num_inscripcion, CONCAT(SA.primer_apellido,' ', SA.segundo_apellido, ', ', SA.nombre) AS nombre_completo_sanitario,
       RH.fecha_inicio, RH.fecha_fin
FROM militar M, sanitario SA, recibe_humanitaria RH
WHERE M.num_registro = RH.militar_num_registro AND SA.num_inscripcion = RH.sanitario_num_inscripcion AND YEAR(RH.fecha_inicio) = 2020
ORDER BY RH.fecha_inicio;


/* Consulta 14:
Tiempo medio de espera, medido en meses, en recibir ayuda material
*/
SELECT 'Humanitaria' AS tipo_ayuda, ROUND(AVG(timestampdiff(MONTH, M.fecha_solicitud, RH.fecha_inicio)), 1) as espera_en_meses
FROM militar M, recibe_humanitaria RH
WHERE M.num_registro = RH.militar_num_registro AND M.tipo_ayuda = 'Humanitaria'
UNION 
SELECT 'Material' AS tipo_ayuda, ROUND(AVG(timestampdiff(MONTH, M.fecha_solicitud, RM.fecha)), 1) as espera_en_meses
FROM militar M, recibe_material RM
WHERE M.num_registro = RM.militar_num_registro AND M.tipo_ayuda = 'Material';


/* Consulta 15: 
Sanitarios saturados: obtener num_inscripcion y especialidad sanitarios, num_pacientes y num_registro de militares de los sanitarios que estan atendiendo a la vez a mas de un paciente
*/
SELECT RH.sanitario_num_inscripcion, S.especialidad, COUNT(*) AS atendiendo, GROUP_CONCAT(RH.militar_num_registro) AS pacientes_actuales
FROM recibe_humanitaria RH, sanitario S
WHERE ISNULL(RH.fecha_fin) AND RH.sanitario_num_inscripcion = S.num_inscripcion
GROUP BY RH.sanitario_num_inscripcion
HAVING atendiendo > 1;


/* Consulta 16: 
Edad media de cada tipo de voluntario
*/
SELECT 'Administrativo' AS categoria_voluntario, ROUND(AVG(timestampdiff(YEAR, A.fecha_nacimiento, CURDATE())), 0) as media_edad
FROM administrativo A
UNION
SELECT 'Sanitario' AS categoria_voluntario, ROUND(AVG(timestampdiff(YEAR, SA.fecha_nacimiento, CURDATE())), 0) as media_edad
FROM sanitario SA;

/* Consulta 17: 
Voluntarios sin paciente asignado de cada especialidad sanitaria
*/      
CREATE VIEW aux10 AS
(SELECT *
	FROM sanitario
	WHERE sanitario.num_inscripcion NOT IN (SELECT DISTINCT S.num_inscripcion
											FROM sanitario S, recibe_humanitaria RH
											WHERE ISNULL(RH.fecha_fin) AND RH.sanitario_num_inscripcion = S.num_inscripcion));

SELECT sede_ciudad, especialidad, COUNT(*) AS disponibles, GROUP_CONCAT(num_inscripcion) AS ID_disponibles
FROM aux10
GROUP BY sede_ciudad, especialidad
ORDER BY sede_ciudad, disponibles DESC;


/* Consulta 18: 
Cantidad de mujeres registradas por sede
*/
SELECT A.sede_ciudad, A.total_administrativas AS administrativas, B.total_sanitarias AS sanitarias, A.total_administrativas + B.total_sanitarias AS total_mujeres
FROM
((SELECT sede_ciudad, COUNT(*) AS total_administrativas FROM administrativo WHERE sexo = 'Mujer' GROUP BY sede_ciudad) A
JOIN
(SELECT sede_ciudad, COUNT(*) AS total_sanitarias FROM sanitario WHERE sexo = 'Mujer' GROUP BY sede_ciudad) B
ON A.sede_ciudad = B.sede_ciudad)
ORDER BY total_mujeres DESC;

/* Consulta 19:
Socios cuya cuota supera la cuota media en mas de 50EUR de la sede en la que estan registrados
*/
CREATE VIEW aux11 AS
(SELECT sede_ciudad, ROUND(AVG(cuota),1) as cuota_media
	FROM socio 
	GROUP BY sede_ciudad);

SELECT S.num_alta, S.DNI, S.sede_ciudad, S.cuota, S.cuota - A.cuota_media as diferencia_media
FROM socio S, aux11 A
WHERE S.sede_ciudad = A.sede_ciudad AND S.cuota - A.cuota_media > 50
ORDER BY sede_ciudad, diferencia_media DESC;


