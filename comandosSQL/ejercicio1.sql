--EJERCICIO 1: CADENA DE PROPIEDAD
-----------------------------------


USE ESTANCO;  --uso mi BD
GO



-----------------------------------
--SCHEMA
--Un schema (esquema) es como una carpeta lógica dentro de una base de datos que sirve 
--para organizar los objetos (tablas, vistas, procedimientos, etc.).
-----------------------------------


CREATE SCHEMA personal;  --creo mi schema personal para organizar lo relevante a empleados
GO


CREATE TABLE personal.Empleados ( --creo la tabla dentro del schema personal
  ID_empleado      INT PRIMARY KEY,  --número unico para cada trabajador
  Nombre           VARCHAR(50),
  Telefono         VARCHAR(15),   --datos personales básicos
  Mail             VARCHAR(100),
  Salario          DECIMAL(10,2),
  CP_ID_codigopostal INTEGER   --se conecta con la tabla de ubicaciones (CP)
);
GO


DROP TABLE personal.Empleados;
GO

DROP SCHEMA personal;
GO


SELECT * FROM personal.Empleados
GO


-----------------------------------
--VISTA
--es una consulta SQL guardada que se comporta como una tabla virtual.
--No guarda datos (solo SELECT)
-----------------------------------


--si solo quiero saber ID y nombre de empleados

CREATE VIEW personal.VISTA_Empleados  --le pongo nombre a la vista
AS
SELECT
ID_empleado, Nombre  --solo me devuelve estas dos columnas
FROM personal.Empleados; --de mi tabla creada
GO


SELECT * FROM personal.VISTA_Empleados;   --compruebo el resultado
GO



-----------------------------------
--ROL
--es un grupo de permisos que se puede asignar a usuarios.
-----------------------------------

CREATE ROLE ROL_personal;   --creo un rol, solo existe, no tiene aun persmisos
GO

GRANT SELECT ON personal.VISTA_Empleados TO ROL_personal; --los usuarios pueden solo ver los empleados (la VISTA), no modificar nada de la tabla
GO                                                        --doy permiso al rol


DROP USER IF EXISTS Juan;
GO
CREATE USER Juan WITHOUT LOGIN;   --creo un usuario, solo dentro de la base, no puede conectarse (seguridad interna, para pruebas)
GO


ALTER ROLE ROL_personal           --lo asigno al rol  (sirve para consultar empleados pero no modificarlos)
ADD MEMBER Juan;                  --ahora Juan tiene permiso solo sobre la vista, porque el rol lo tiene.
GO




--si quiero que el rol creado tenga acceso (de lectura) a todas las vistas/tablas del schema

GRANT SELECT ON SCHEMA::personal TO rol_personal;
GO



--Crear rol	       CREATE ROLE ROL_personal                 	 Grupo de permisos creado
--Dar permisos	   GRANT SELECT ON personal.VISTA_Empleados	     El rol solo puede leer la vista
--Crear usuario	   CREATE USER Juan WITHOUT LOGIN	             Usuario interno de la base, sin acceso desde fuera
--Asignar al rol   ALTER ROLE ... ADD MEMBER	                 El usuario Juan hereda los permisos del rol




----Juan puede ver la tabla usando la vista

EXECUTE AS USER = 'Juan';  --(poner comillas al nombre)
GO

PRINT USER;   --muestro quien soy
GO

SELECT * FROM personal.VISTA_Empleados;  --selecciono la vista, siendo Juan a ver si veo lo que el rol me permite
GO 


SELECT * FROM personal.Empleados;   --no puede acceder, SOLO mediante la vista
GO





REVERT;
GO
PRINT USER;
GO




-----------------------------------
--mediante PROCEDIMIENTO ALMACENADO

--SP es un conjunto de instrucciones SQL guardadas en la base de datos,
--que se ejecutan cuando lo llamas por su nombre

--En lugar de escribir varias sentencias SQL cada vez
--Se guardan una sola vez dentro del servidor
--Luego solo llamas: EXEC MiProcedimiento
-----------------------------------


CREATE PROCEDURE personal.SP_InsertarEmpleado   --creo un proc de insertar nuevo empleado
    @ID_empleado INT,
    @Nombre VARCHAR(50),
    @Telefono VARCHAR(15),
    @Mail VARCHAR(100),
    @Salario DECIMAL(10,2),
    @CP INT
AS
BEGIN
    INSERT INTO personal.Empleados
        (ID_empleado, Nombre, Telefono, Mail, Salario, CP_ID_codigopostal)
    VALUES
        (@ID_empleado, @Nombre, @Telefono, @Mail, @Salario, @CP);
END;
GO


DROP ROLE IF EXISTS ROL_admin;
GO
CREATE ROLE ROL_admin;
GO


GRANT EXECUTE ON SCHEMA::personal TO ROL_admin;      --concedo el permiso de ejecución sobre el schema personal
GO                                                   --Solo da permisos para ejecutar SP o funciones, no da permisos de SELECT, UPDATE, etc. sobre tablas


DROP USER IF EXISTS Antonia;                   --creo nuevo usuario
GO
CREATE USER Antonia WITHOUT LOGIN;
GO 



ALTER ROLE ROL_admin            --meto a esta nueva usuaria en el ROL de admin
ADD MEMBER Antonia;
GO



EXECUTE AS USER = 'Antonia';
GO 


INSERT INTO personal.Empleados              --esto es una insercción directa, sin SP
   (ID_empleado, Nombre, Telefono, Mail, Salario, CP_ID_codigopostal)
VALUES
    (4, 'Alberto Castro', '600123456', 'alberto.castro@mail.com', 2500.00, 15006);
GO


EXEC personal.SP_InsertarEmpleado            --insertar con el SP
    @ID_empleado = 4,
    @Nombre = 'Alberto Castro',
    @Telefono = '600123456',
    @Mail = 'alberto.castro@mail.com',
    @Salario = 2500.00,
    @CP = 15006;
GO

PRINT USER;
GO




SELECT * FROM EMPLEADOS;              --tabla DBO
GO

SELECT * FROM personal.Empleados;     --tabla schema
GO



REVERT;   --para cambiar de usuario (como si iniciara sesión como otro usuario)
GO


SELECT * FROM personal.Empleados;  --veo toda la tabla
GO



SELECT *                    --Buscar solo el empleado insertado (más preciso)
FROM personal.Empleados
WHERE ID_empleado = 4;
GO



SELECT COUNT(*) AS TotalEmpleados  --Contar registros (útil si la tabla estaba vacía antes)
FROM personal.Empleados;
GO



--ANOTACIONES

--schema	            Carpeta lógica dentro de la BD
--dbo	                Schema por defecto
--personal	            Schema que yo cree
--personal.Empleados	Tabla dentro de mi schema personal



--Permitir ejecutar todos los SP del schema	         GRANT EXECUTE ON SCHEMA::personal TO ROL_X
--Permitir consultar todas las tablas del schema	 GRANT SELECT ON SCHEMA::personal TO ROL_X
--Permitir solo algunas vistas	                     GRANT SELECT ON personal.VistaX TO ROL_X
--Permitir insertar, actualizar, borrar	             GRANT INSERT/UPDATE/DELETE ON SCHEMA::personal TO ROL_X



--EXECUTE AS	Cambia mi usuario temporalmente
--REVERT	    Devuelve mi identidad original
--Sin REVERT	Sigo actuando como el usuario simulado